extends Node

# Signals
signal variableSynced(data: String)
signal chat_received(sender: String, msg: String)
signal cloudflare_tunnel_ready(token: String)
signal cloudflare_tunnel_failed(error_msg: String)
signal player_joined(player_name: String)
signal player_left(player_name: String)
signal coin_sync_received(coin_id: String)
signal enemy_sync_received(enemy_id: String)
signal level_sync_received(scene_name: String)
signal pickup_sync_received(item_id: String)

# Configuration Constants
const PORT_PRIMARY: int = 8080
const DEFAULT_IP: String = "127.0.0.1"
const PLAYER_SCENE_PATH: String = "res://Scenes/Player.tscn"

# Network State Variables
var is_host: bool = false
var my_port: int = PORT_PRIMARY
var target_ip: String = DEFAULT_IP
var target_port: int = PORT_PRIMARY
var playerName: String = ""
var cloudflare_checked: bool = false

# Pure GDScript WebSocket Engines
var ws_server: TCPServer = TCPServer.new()
var server_peers: Array[WebSocketPeer] = []
var pending_send_queue: Array[String] = []

# Persistent Bi-directional Client Connection
var client_peer: WebSocketPeer = WebSocketPeer.new()
var client_connected: bool = false

# Cloudflare Tunnel Process Variables
var cloudflare_pid: int = -1
var tunnel_timer: float = 0.0
var tunnel_resolved: bool = false
var is_cloudflare_installed: bool = false
var cloudflare_executable: String = ""

# Connected Players Tracking & Scene Management
var connected_players: Dictionary = {}
var remote_players: Dictionary = {}
var player_scene: PackedScene = null

func _ready() -> void:
	playerName = "Player" + str(randi_range(1000, 9999))
	get_tree().node_added.connect(_on_scene_node_added)
	
	# Load Player Scene for Remote Spawning
	if ResourceLoader.exists(PLAYER_SCENE_PATH):
		player_scene = load(PLAYER_SCENE_PATH)
	else:
		push_error("[Network] Could not find player.tscn. Remote players will not spawn.")
		
	_start_host()

func _check_cloudflare_installed() -> void:
	var output: Array = []
	var exit_code := -1

	var candidates: Array[String] = []

	match OS.get_name():
		"Windows":
			candidates = [
				"cloudflared",
				"cloudflared.exe",
				"C:/Program Files/Cloudflare/cloudflared.exe",
				"C:/Program Files (x86)/Cloudflare/cloudflared.exe",
				OS.get_environment("USERPROFILE") + "/cloudflared.exe",
				OS.get_environment("USERPROFILE") + "/Downloads/cloudflared.exe"
			]

		"Linux":
			candidates = [
				"cloudflared",
				"/usr/bin/cloudflared",
				"/usr/local/bin/cloudflared"
			]

		"macOS":
			candidates = [
				"cloudflared",
				"/opt/homebrew/bin/cloudflared",
				"/usr/local/bin/cloudflared"
			]

		_:
			print("[Network] Unsupported OS: ", OS.get_name())
			is_cloudflare_installed = false
			return

	for exe in candidates:
		output.clear()

		exit_code = OS.execute(exe, ["--version"], output, true)

		if exit_code == 0:
			cloudflare_executable = exe
			is_cloudflare_installed = true

			print("[Network] Cloudflared found:")
			print("    Executable: ", exe)

			if output.size() > 0:
				print(output[0])

			return

	is_cloudflare_installed = false
	print("[Network] Cloudflared not found.")

func _start_host() -> void:
	if ws_server.is_listening():
		is_host = true
		print("[Network] Host already active. Listening on Port: ", my_port)
		return

	# CRITICAL FIX: Clear all old peers, remote players, and sockets before binding a new host
	disconnect_all()

	var err: int = ws_server.listen(PORT_PRIMARY)
	if err == OK:
		is_host = true
		my_port = PORT_PRIMARY
		print("[Network] Initialized as HOST. Identity: ", playerName, " | Listening on Port: ", PORT_PRIMARY)
	else:
		is_host = false
		print("[Network] Port ", PORT_PRIMARY, " in use. Initialized as CLIENT. Identity: ", playerName, " | Ready to connect.")

func disconnect_all() -> void:
	print("[Network] Disconnecting all network connections...")
	stopCloudflareTunnel()
	
	for peer in server_peers:
		if peer != null:
			peer.close()
	server_peers.clear()
	
	if ws_server.is_listening():
		ws_server.stop()
		print("[Network] Server stopped listening.")
		
	if client_peer != null:
		client_peer.close()
		client_connected = false
		print("[Network] Client peer closed.")
		
	pending_send_queue.clear()
	connected_players.clear()
	
	# Cleanup Remote Players
	for p_name in remote_players.keys():
		_despawn_remote_player(p_name)
		
	is_host = false

func reconnect_client() -> void:
	client_peer.close()
	client_connected = false
	
	var clean_ip: String = target_ip.strip_edges()
	if clean_ip.begins_with("https://"):
		clean_ip = clean_ip.substr(8)
	elif clean_ip.begins_with("http://"):
		clean_ip = clean_ip.substr(7)
	elif clean_ip.begins_with("wss://"):
		clean_ip = clean_ip.substr(6)
	elif clean_ip.begins_with("ws://"):
		clean_ip = clean_ip.substr(5)
		
	var protocol: String = "wss://" if "trycloudflare.com" in clean_ip else "ws://"
	var port_str: String = ""
	if "trycloudflare.com" not in clean_ip:
		port_str = ":" + str(target_port)
		
	var url: String = protocol + clean_ip + port_str
	print("[Network] Initiating persistent client connection to: ", url)
	
	var err: int = client_peer.connect_to_url(url)
	if err != OK:
		printerr("[Network] Failed to initiate connection to: ", url)

func send_json_packet(data: Dictionary) -> void:
	var json_str: String = JSON.stringify(data)
	_send_raw_text(json_str)

func _send_raw_text(text: String) -> void:
	if is_host:
		for peer in server_peers:
			if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
				peer.send_text(text)
	else:
		if client_peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			client_peer.send_text(text)
		else:
			pending_send_queue.append(text)

func syncVariableToPeer(myVariable: String) -> void:
	_send_raw_text(myVariable)

func connectToCloudflareServer(token: String) -> void:
	var clean_token: String = token.strip_edges()
	if clean_token.begins_with("https://"):
		clean_token = clean_token.substr(8)
	elif clean_token.begins_with("http://"):
		clean_token = clean_token.substr(7)
		
	if "mock-tunnel-" in clean_token:
		target_ip = "127.0.0.1"
		var parts: PackedStringArray = clean_token.split("-")
		if parts.size() >= 3:
			target_port = parts[2].split(".")[0].to_int()
		else:
			target_port = PORT_PRIMARY
		is_host = false
		reconnect_client()
		return
		
	if ":" in clean_token:
		var parts: PackedStringArray = clean_token.split(":")
		target_ip = parts[0]
		target_port = parts[1].to_int()
	else:
		target_ip = clean_token
		if "trycloudflare.com" in clean_token:
			target_port = 443
		else:
			target_port = PORT_PRIMARY
			
	is_host = false
	reconnect_client()

func startCloudflareTunnel() -> void:
	
	if not cloudflare_checked:
		_check_cloudflare_installed()
		cloudflare_checked = true
		
	if not is_cloudflare_installed:
		cloudflare_tunnel_failed.emit("Cloudflare ('" + cloudflare_executable + "') is not installed. Please install it to use online tunneling. Running localhost only.")
		return

	stopCloudflareTunnel()
	
	if not ws_server.is_listening():
		_start_host()
		
	var log_path: String = "user://cloudflare.log"
	if FileAccess.file_exists(log_path):
		DirAccess.remove_absolute(log_path)
		
	var global_log: String = ProjectSettings.globalize_path(log_path)
	var os_name: String = OS.get_name()
	tunnel_timer = 0.0
	tunnel_resolved = false
	
	# Use the resolved platform-specific executable name
	if os_name == "Windows":
		cloudflare_pid = OS.create_process("cmd.exe", ["/c", cloudflare_executable + " tunnel --url http://localhost:" + str(my_port) + " > \"" + global_log + "\" 2>&1"])
	elif os_name == "Linux" or os_name == "macOS":
		cloudflare_pid = OS.create_process("sh", ["-c", cloudflare_executable + " tunnel --url http://localhost:" + str(my_port) + " > \"" + global_log + "\" 2>&1"])
	else:
		cloudflare_pid = -1
		cloudflare_tunnel_failed.emit("Unsupported OS Platform: " + os_name)
		
	if cloudflare_pid == -1:
		cloudflare_tunnel_failed.emit("Failed to start " + cloudflare_executable + " process.")

func stopCloudflareTunnel() -> void:
	if cloudflare_pid != -1:
		OS.kill(cloudflare_pid)
		cloudflare_pid = -1
	tunnel_resolved = false
	tunnel_timer = 0.0

func _on_packet_received(text: String, from_peer: WebSocketPeer = null) -> void:
	var json: JSON = JSON.new()
	var parse_result: int = json.parse(text)
	
	if parse_result == OK and json.data is Dictionary:
		var data: Dictionary = json.data
		var msg_type: String = data.get("type", "")
		var sender: String = data.get("sender", "Unknown")
		
		# Host Relay Logic: Echo packets from clients to all other clients
		if is_host and sender != playerName and from_peer != null:
			for peer in server_peers:
				if peer != from_peer and peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
					peer.send_text(text)
		
		match msg_type:
			"chat":
				var msg: String = data.get("msg", "")
				chat_received.emit(sender, msg)
			"join":
				print("[Network] Player joined: ", sender)
				connected_players[sender] = {"pos": Vector2.ZERO, "anim": "idle"}
				player_joined.emit(sender)
				_spawn_remote_player(sender)
				
				if is_host and from_peer != null:
					var host_join: Dictionary = {"type": "join", "sender": playerName}
					from_peer.send_text(JSON.stringify(host_join))
					
					 # Sync current level to the new client
					if SceneManager.current_level != "":
						var level_packet: Dictionary = {
							"type": "level_sync",
							"sender": playerName,
							"scene": SceneManager.current_level
						}
						from_peer.send_text(JSON.stringify(level_packet))
					
			"leave":
				print("[Network] Player left: ", sender)
				connected_players.erase(sender)
				player_left.emit(sender)
				_despawn_remote_player(sender)
			"pos":
				if sender != playerName:
					var x: float = float(data.get("x", 0.0))
					var y: float = float(data.get("y", 0.0))
					var anim: String = data.get("anim", "idle")
					var flip: bool = data.get("flip", false)
					if not connected_players.has(sender):
						connected_players[sender] = {}
						_spawn_remote_player(sender)
					connected_players[sender]["pos"] = Vector2(x, y)
					connected_players[sender]["anim"] = anim
					_update_remote_player(sender, Vector2(x, y), anim, flip)
			"coin_sync":
				var coin_id: String = data.get("id", "")
				if coin_id != "":
					coin_sync_received.emit(coin_id)
			"enemy_sync":
				var enemy_id: String = data.get("id", "")
				if enemy_id != "":
					enemy_sync_received.emit(enemy_id)
			"level_sync":
				var scene_name: String = data.get("scene", "")
				if scene_name != "":
					level_sync_received.emit(scene_name)
			"pickup_sync":
				var item_id: String = data.get("id", "")
				if item_id != "":
					pickup_sync_received.emit(item_id)
			_:
				variableSynced.emit(text)
	else:
		variableSynced.emit(text)

func _spawn_remote_player(p_name: String) -> void:
	if remote_players.has(p_name):
		return
	if player_scene == null:
		push_error("[Network] Player scene not found for spawning remote player.")
		return
		
	var remote_instance: CharacterBody2D = player_scene.instantiate()
	remote_instance.is_local = false
	remote_instance.player_name = p_name
	remote_instance.name = "RemotePlayer_" + p_name
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(remote_instance)
	else:
		add_child(remote_instance)
		
	remote_players[p_name] = remote_instance
	print("[Network] Spawned remote player: ", p_name)

func _despawn_remote_player(p_name: String) -> void:
	if remote_players.has(p_name):
		var instance: Node = remote_players[p_name]
		if is_instance_valid(instance):
			instance.queue_free()
		remote_players.erase(p_name)
		print("[Network] Despawned remote player: ", p_name)

func _update_remote_player(p_name: String, pos: Vector2, anim: String, flip: bool) -> void:
	if remote_players.has(p_name):
		if is_instance_valid(remote_players[p_name]):
			var instance: CharacterBody2D = remote_players[p_name]
			instance.network_target_pos = pos
			instance.network_anim = anim
			instance.network_flip_h = flip
		else:
			remote_players.erase(p_name)
			connected_players.erase(p_name)

func _process(delta: float) -> void:
	# 1. Process Server
	if ws_server.is_listening():
		if ws_server.is_connection_available():
			var tcp_conn: StreamPeerTCP = ws_server.take_connection()
			var peer: WebSocketPeer = WebSocketPeer.new()
			var err: int = peer.accept_stream(tcp_conn)
			if err == OK:
				server_peers.append(peer)
				
		var server_idx: int = server_peers.size() - 1
		while server_idx >= 0:
			var peer: WebSocketPeer = server_peers[server_idx]
			peer.poll()
			var state: int = peer.get_ready_state()
			if state == WebSocketPeer.STATE_OPEN:
				while peer.get_available_packet_count() > 0:
					var packet: PackedByteArray = peer.get_packet()
					var text: String = packet.get_string_from_utf8()
					_on_packet_received(text, peer)
			elif state == WebSocketPeer.STATE_CLOSED:
				server_peers.remove_at(server_idx)
			server_idx -= 1
			
	# 2. Process Client
	client_peer.poll()
	var client_state: int = client_peer.get_ready_state()
	if client_state == WebSocketPeer.STATE_OPEN:
		if not client_connected:
			client_connected = true
			print("[Network] Persistent client connection established!")
			send_json_packet({"type": "join", "sender": playerName})
			
		while pending_send_queue.size() > 0:
			var payload: String = pending_send_queue.pop_front()
			client_peer.send_text(payload)
			
		while client_peer.get_available_packet_count() > 0:
			var packet: PackedByteArray = client_peer.get_packet()
			var text: String = packet.get_string_from_utf8()
			_on_packet_received(text, null)
	elif client_state == WebSocketPeer.STATE_CLOSED:
		if client_connected:
			client_connected = false
			print("[Network] Persistent client connection closed.")
			
	# 3. Cloudflare Logs
	if cloudflare_pid != -1 and not tunnel_resolved:
		tunnel_timer += delta
		var log_path: String = "user://cloudflare.log"
		if FileAccess.file_exists(log_path):
			var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
			if file != null:
				var file_text: String = file.get_as_text()
				file.close()
				if "trycloudflare.com" in file_text:
					var marker: int = file_text.find(".trycloudflare.com")
					if marker != -1:
						var start_marker: int = file_text.rfind("https://", marker)
						if start_marker != -1:
							var tunnel_url: String = file_text.substr(start_marker, marker - start_marker + 18)
							tunnel_resolved = true
							DisplayServer.clipboard_set(tunnel_url)
							cloudflare_tunnel_ready.emit(tunnel_url)
							return
		if tunnel_timer >= 15.0:
			tunnel_resolved = true
			cloudflare_tunnel_failed.emit("Timed out waiting for Cloudflare tunnel URL.")

func _on_scene_node_added(node: Node) -> void:
	# When a new scene loads, reparent all active remote players to the new scene root
	if node == get_tree().current_scene:
		for p_name in remote_players.keys():
			if is_instance_valid(remote_players[p_name]):
				var instance: Node = remote_players[p_name]
				if instance.get_parent() != node:
					instance.get_parent().remove_child(instance)
					node.add_child(instance)

func _exit_tree() -> void:
	disconnect_all()
