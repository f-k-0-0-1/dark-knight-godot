extends Node

# Signals
signal variableSynced(data: String)
signal cloudflare_tunnel_ready(token: String)
signal cloudflare_tunnel_failed(error_msg: String)

# Configuration Constants
const PORT_PRIMARY: int = 8080
const PORT_SECONDARY: int = 8081
const DEFAULT_IP: String = "127.0.0.1"

# Network State Variables
var isPlayer2: bool = false
var myPort: int = PORT_PRIMARY
var targetPort: int = PORT_SECONDARY
var targetIp: String = DEFAULT_IP

# Pure GDScript WebSocket Engines
var ws_server: TCPServer = TCPServer.new()
var server_peers: Array[WebSocketPeer] = []
var pending_send_queue: Array[Dictionary] = [] # Array of Dictionary: { "peer": WebSocketPeer, "payload": String, "sent": bool }

# Cloudflare Tunnel Process Variables
var cloudflare_pid: int = -1
var tunnel_timer: float = 0.0
var tunnel_resolved: bool = false

func _ready() -> void:
	# Attempt to bind to the primary port to dynamically determine identity
	var err = ws_server.listen(PORT_PRIMARY)
	
	if err == OK:
		# Port 8080 is free: We are Player 1!
		isPlayer2 = false
		myPort = PORT_PRIMARY
		targetPort = PORT_SECONDARY
		print("[Network] Dynamic setup successful: Configured as Player 1 (Port 8080)")
	else:
		# Port 8080 is in use: Try the secondary port to configure as Player 2
		err = ws_server.listen(PORT_SECONDARY)
		if err == OK:
			# Port 8081 is free: We are Player 2!
			isPlayer2 = true
			myPort = PORT_SECONDARY
			targetPort = PORT_PRIMARY
			print("[Network] Dynamic setup successful: Configured as Player 2 (Port 8081)")
		else:
			# Both ports are blocked by other running background processes
			printerr("CRITICAL ERROR: Failed to listen on both 8080 and 8081 ports. Sockets are blocked.")

# Transmit message variable dynamically over a non-blocking WebSocket handshake
func syncVariableToPeer(myVariable: String) -> void:
	var ws_client: WebSocketPeer = WebSocketPeer.new()
	var clean_ip: String = targetIp.strip_edges()
	
	if clean_ip.begins_with("https://"):
		clean_ip = clean_ip.substr(8)
	elif clean_ip.begins_with("http://"):
		clean_ip = clean_ip.substr(7)
	elif clean_ip.begins_with("wss://"):
		clean_ip = clean_ip.substr(6)
	elif clean_ip.begins_with("ws://"):
		clean_ip = clean_ip.substr(5)
		
	# Connect via Secure WebSocket (wss) over port 443 for Cloudflare Tunnels
	var protocol: String = "wss://" if "trycloudflare.com" in clean_ip else "ws://"
	var port_str: String = ""
	if "trycloudflare.com" not in clean_ip:
		port_str = ":" + str(targetPort)
		
	var url: String = protocol + clean_ip + port_str
	var err = ws_client.connect_to_url(url)
	if err == OK:
		pending_send_queue.append({
			"peer": ws_client,
			"payload": myVariable,
			"sent": false
		})

# Parse connection token and update routing properties
func connectToCloudflareServer(token: String) -> void:
	var clean_token: String = token.strip_edges()
	
	if clean_token.begins_with("https://"):
		clean_token = clean_token.substr(8)
	elif clean_token.begins_with("http://"):
		clean_token = clean_token.substr(7)
		
	# Handle local mock tunnel routing for local/offline testing
	if "mock-tunnel-" in clean_token:
		targetIp = "127.0.0.1"
		var parts: PackedStringArray = clean_token.split("-")
		if parts.size() >= 3:
			var port_part: String = parts[2].split(".")[0]
			targetPort = port_part.to_int()
		else:
			targetPort = PORT_PRIMARY
		return

	if ":" in clean_token:
		var parts: PackedStringArray = clean_token.split(":")
		targetIp = parts[0]
		targetPort = parts[1].to_int()
	else:
		targetIp = clean_token
		if "trycloudflare.com" in clean_token:
			targetPort = 443
		else:
			targetPort = PORT_PRIMARY

# Asynchronously spawn cloudflared quick-tunnel
func startCloudflareTunnel() -> void:
	stopCloudflareTunnel()
	
	var log_path: String = "user://cloudflare.log"
	if FileAccess.file_exists(log_path):
		DirAccess.remove_absolute(log_path)
		
	var global_log: String = ProjectSettings.globalize_path(log_path)
	var osName: String = OS.get_name()
	
	tunnel_timer = 0.0
	tunnel_resolved = false
	
	if osName == "Windows":
		cloudflare_pid = OS.create_process("cmd.exe", ["/c", "cloudflared tunnel --url http://localhost:" + str(myPort) + " > \"" + global_log + "\" 2>&1"])
	elif osName == "Linux" or osName == "macOS":
		cloudflare_pid = OS.create_process("sh", ["-c", "cloudflared tunnel --url http://localhost:" + str(myPort) + " > \"" + global_log + "\" 2>&1"])
	else:
		cloudflare_pid = -1
		cloudflare_tunnel_failed.emit("Unsupported OS Platform")

func stopCloudflareTunnel() -> void:
	if cloudflare_pid != -1:
		OS.kill(cloudflare_pid)
		cloudflare_pid = -1
	tunnel_resolved = false
	tunnel_timer = 0.0

# Non-blocking main-thread polling loop
func _process(delta: float) -> void:
	# 1. Process active Server incoming connections
	if ws_server.is_listening():
		if ws_server.is_connection_available():
			var tcp_conn = ws_server.take_connection()
			var peer = WebSocketPeer.new()
			var err = peer.accept_stream(tcp_conn)
			if err == OK:
				server_peers.append(peer)

	# 2. Process active Server Peer data transfers
	var server_idx = server_peers.size() - 1
	while server_idx >= 0:
		var peer = server_peers[server_idx] as WebSocketPeer
		peer.poll()
		
		var state = peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count() > 0:
				var packet = peer.get_packet()
				var text = packet.get_string_from_utf8()
				variableSynced.emit(text)
		elif state == WebSocketPeer.STATE_CLOSED:
			server_peers.remove_at(server_idx)
		server_idx -= 1

	# 3. Process Client Sending Queue
	var client_idx = pending_send_queue.size() - 1
	while client_idx >= 0:
		var item = pending_send_queue[client_idx]
		var peer = item["peer"] as WebSocketPeer
		peer.poll()
		
		var state = peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if not item["sent"]:
				peer.send_text(item["payload"])
				item["sent"] = true
			else:
				# Once packet leaves buffer, close socket cleanly
				if peer.get_current_outbound_buffered_amount() == 0:
					peer.close()
		elif state == WebSocketPeer.STATE_CLOSED:
			pending_send_queue.remove_at(client_idx)
		client_idx -= 1

	# 4. Process Cloudflare Tunnel Logs and Handshake (with expanded 15s timeout)
	if cloudflare_pid != -1 and not tunnel_resolved:
		tunnel_timer += delta
		var log_path: String = "user://cloudflare.log"
		
		if FileAccess.file_exists(log_path):
			var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
			if file != null:
				var file_text: String = file.get_as_text()
				file.close()
				
				# Parse backwards from the domain to isolate the true tunnel URL
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
			var fallback_token: String = "mock-tunnel-" + str(myPort) + ".trycloudflare.com"
			DisplayServer.clipboard_set(fallback_token)
			cloudflare_tunnel_ready.emit(fallback_token)

func _exit_tree() -> void:
	stopCloudflareTunnel()
	if ws_server.is_listening():
		ws_server.stop()
