extends CanvasLayer

signal start_game_pressed(level_name: String)

@onready var panel: Panel = $Panel
@onready var role_popup: Panel = $RolePopup

# Popup Nodes (Matched to your layout)
@onready var host_button: Button = $RolePopup/HostButton
@onready var client_button: Button = $RolePopup/ClientButton
@onready var popup_back_button: Button = $RolePopup/BackButton

# Player Cards
@onready var player_card_1: Control = $Panel/PlayerCard1
@onready var player_card_2: Control = $Panel/PlayerCard2
@onready var player_name_1: Label = $Panel/PlayerCard1/PlayerName
@onready var player_name_2: Label = $Panel/PlayerCard2/PlayerName

# Inputs & Buttons
@onready var link_input: LineEdit = $Panel/LinkInput
@onready var join_button: Button = $Panel/JoinButton
@onready var start_button: Button = $Panel/StartButton
@onready var chat_button: Button = $Panel/ChatButton
@onready var level_dropdown: OptionButton = $Panel/LevelSelectDropdown
@onready var back_button: Button = $Panel/BackButton

# === STATE ===
var players_ready := {}
var countdown_timer: Timer
var countdown_value := 5
var is_countdown_running := false
var selected_level := "level_1"
var my_peer_id: int = 0
var current_role: String = ""  # "host" or "client"
var is_client_ready: bool = false # === ADDED: Client ready tracker state ===
var client_name_cached: String = "Player 2" # === ADDED: Cache to remember client name labels ===

func _ready():
# 1. Hide everything initially
	panel.visible = false
	role_popup.visible = true
	
	var black_style = StyleBoxFlat.new()
	black_style.bg_color = Color.BLACK
	
	# === UPDATED: Set the corner radius to 30 pixels ===
	black_style.set_corner_radius_all(30) 
	black_style.set_content_margin_all(6)
	
	# Apply the flat black style box override across ALL interaction states
	start_button.add_theme_stylebox_override("normal", black_style)
	start_button.add_theme_stylebox_override("hover", black_style)
	start_button.add_theme_stylebox_override("pressed", black_style)
	start_button.add_theme_stylebox_override("focus", black_style)
	start_button.add_theme_stylebox_override("disabled", black_style)
	
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		if player_node.has_node("HUD"):
			player_node.get_node("HUD").visible = false
		if player_node.has_node("Camera2D"):
			player_node.get_node("Camera2D").enabled = false
	
	my_peer_id = multiplayer.get_unique_id()
	
	host_button.pressed.connect(_on_host_selected)
	client_button.pressed.connect(_on_client_selected)
	if popup_back_button:
		popup_back_button.pressed.connect(_on_back_pressed)
	
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	chat_button.pressed.connect(_on_chat_pressed)
	back_button.pressed.connect(_on_back_pressed)
	level_dropdown.item_selected.connect(_on_level_selected)
	
	level_dropdown.clear()
	for key in SceneManager.scene_paths:
		if key.begins_with("level_"):
			level_dropdown.add_item(key)
	level_dropdown.select(0)
	
	if LIB_C.has_signal("player_joined"):
		LIB_C.player_joined.connect(_on_player_joined)
	if LIB_C.has_signal("player_left"):
		LIB_C.player_left.connect(_on_player_left)
	if LIB_C.has_signal("level_sync_received"):
		LIB_C.level_sync_received.connect(_on_level_sync_received)
	if LIB_C.has_signal("game_start_received"):
		LIB_C.game_start_received.connect(_on_game_start_received)
	# === ADDED: Connect network ready status handler ===
	if LIB_C.has_signal("player_ready_changed"):
		LIB_C.player_ready_changed.connect(_on_player_ready_changed)

# =====================
# ROLE SELECTION POPUP
# =====================
func _on_host_selected():
	current_role = "host"
	role_popup.visible = false
	panel.visible = true
	
	LIB_C.set_role(true)
	LIB_C.disconnect_all()
	await get_tree().create_timer(0.5).timeout
	LIB_C.set_role(true)
	
	join_button.text = "📋 Copy Link"
	link_input.editable = false
	link_input.placeholder_text = "Generating link..."
	level_dropdown.disabled = false
	
	# Host button is always "Start Game" but begins disabled until client joins and reads up
	start_button.text = "Start Game"
	start_button.disabled = true
	
	player_card_1.visible = true
	player_name_1.text = LIB_C.playerName + " (Host)"
	player_card_2.visible = false
	
	await get_tree().create_timer(1.0).timeout
	if LIB_C.has_signal("cloudflare_tunnel_ready"):
		LIB_C.cloudflare_tunnel_ready.connect(_on_tunnel_ready, CONNECT_ONE_SHOT)
		LIB_C.startCloudflareTunnel()
	else:
		link_input.text = "ws://localhost:" + str(LIB_C.my_port)
		link_input.placeholder_text = ""

func _on_client_selected():
	current_role = "client"
	role_popup.visible = false
	panel.visible = true
	
	LIB_C.set_role(false)
	
	join_button.text = "Join Game"
	link_input.editable = true
	link_input.placeholder_text = "Paste link here..."
	level_dropdown.disabled = true
	
	# === FIX: Client's button now behaves as a Ready button ===
	start_button.text = "Ready"
	start_button.disabled = true # Enabled only after a successful connection setup
	
	selected_level = "level_1"
	level_dropdown.text = "level_1"
	
	player_card_1.visible = true
	player_name_1.text = "Waiting for Host..."
	
	player_card_2.visible = true
	player_name_2.text = LIB_C.playerName + " (Not Ready)"
	client_name_cached = LIB_C.playerName

func _on_tunnel_ready(url: String):
	link_input.text = url
	link_input.placeholder_text = ""
	join_button.text = "📋 Copy Link"

# =====================
# UI BUTTON LOGIC
# =====================
func _on_join_pressed():
	if current_role == "host":
		print("Host forcing fresh tunnel generation...")
		LIB_C.stopCloudflareTunnel()
		await get_tree().create_timer(0.5).timeout
		
		if LIB_C.has_signal("cloudflare_tunnel_ready"):
			LIB_C.cloudflare_tunnel_ready.connect(_on_tunnel_ready, CONNECT_ONE_SHOT)
			LIB_C.startCloudflareTunnel()
			
		link_input.text = "Refreshing..."
		link_input.editable = false
		return
	
	var link = link_input.text.strip_edges()
	if link.is_empty():
		return
	print("Client attempting to join: ", link)
	
	player_card_2.visible = true
	player_name_2.text = "Connecting..."
	
	LIB_C.connectToCloudflareServer(link)
	
	if not is_connected("player_joined", _on_player_joined):
		LIB_C.player_joined.connect(_on_player_joined, CONNECT_ONE_SHOT)
	
	var timeout_timer = Timer.new()
	timeout_timer.wait_time = 10.0
	timeout_timer.one_shot = true
	timeout_timer.timeout.connect(func():
		if player_name_2.text == "Connecting...":
			player_name_2.text = "Connection Failed"
			if LIB_C.player_joined.is_connected(_on_player_joined):
				LIB_C.player_joined.disconnect(_on_player_joined)
	)
	add_child(timeout_timer)
	timeout_timer.start()
	
	var signal_cleanup = func():
		if timeout_timer and timeout_timer.is_inside_tree():
			timeout_timer.stop()
			timeout_timer.queue_free()
	LIB_C.player_joined.connect(signal_cleanup, CONNECT_ONE_SHOT)

func _on_chat_pressed():
	const CHAT_SCENE = preload("res://Scenes/multiplayer_chat_ui.tscn")
	if $Panel.get_node_or_null("ChatUI") != null:
		return
	var chat_instance = CHAT_SCENE.instantiate()
	chat_instance.name = "ChatUI"
	$Panel.add_child(chat_instance)

func _on_level_selected(index: int):
	if current_role != "host":
		return
	selected_level = level_dropdown.get_item_text(index)
	print("Host selected level: ", selected_level)
	
	if LIB_C.has_method("send_json_packet"):
		var packet: Dictionary = {
			"type": "level_sync",
			"sender": LIB_C.playerName,
			"scene": selected_level
		}
		LIB_C.send_json_packet(packet)

func _on_start_pressed():
	# === 1. HOST LOGIC: Starts the match if verified ===
	if current_role == "host":
		var player_count = 0
		if player_card_1.visible: player_count += 1
		if player_card_2.visible: player_count += 1
		
		if player_count < 2:
			print("Need 2 players to start the game!")
			return
			
		if not is_client_ready:
			print("Cannot start! Client is not ready yet.")
			return
		
		if not is_countdown_running:
			_start_countdown()
			
	# === 2. CLIENT LOGIC: Toggles the ready state ===
	elif current_role == "client":
		is_client_ready = !is_client_ready
		
		if is_client_ready:
			start_button.text = "Not Ready"
			player_name_2.text = client_name_cached + " (I am ready)"
		else:
			start_button.text = "Ready"
			player_name_2.text = client_name_cached + " (Not Ready)"
			
		# Send our choice up the connection pipe to update the Host panel
		if LIB_C.has_method("send_json_packet"):
			var packet: Dictionary = {
				"type": "ready_status",
				"sender": LIB_C.playerName,
				"is_ready": is_client_ready
			}
			LIB_C.send_json_packet(packet)

# =====================
# NETWORK SIGNAL HANDLERS
# =====================
func _on_player_joined(player_name: String):
	print("Lobby: Player joined: ", player_name)
	
	if player_name == LIB_C.playerName:
		return

	if current_role == "host":
		player_card_2.visible = true
		player_name_2.text = player_name + " (Not Ready)"
		client_name_cached = player_name
		is_client_ready = false
		start_button.disabled = true # Remains locked until they click ready
		
		var packet: Dictionary = {
			"type": "level_sync",
			"sender": LIB_C.playerName,
			"scene": selected_level
		}
		LIB_C.send_json_packet(packet)
		
	elif current_role == "client":
		player_card_1.visible = true
		player_name_1.text = player_name + " (Host)"
		player_name_2.text = LIB_C.playerName + " (Not Ready)"
		start_button.disabled = false # Unlock the ready button now that connection is established

func _on_player_left(player_name: String):
	print("Lobby: Player left: ", player_name)
	if player_name != LIB_C.playerName:
		if current_role == "host":
			player_card_2.visible = false
			start_button.disabled = true
			is_client_ready = false
		else:
			player_card_1.visible = true
			player_name_1.text = "Host Disconnected"
			start_button.disabled = true

func _on_level_sync_received(level_name: String):
	if current_role == "client":
		selected_level = level_name
		level_dropdown.text = level_name
		print("Client synced to level: ", selected_level)

func _on_game_start_received(level_name: String):
	if current_role == "client":
		print("Client shifting to gameplay level: ", level_name)
		start_game_pressed.emit(level_name)

# === ADDED: Updates UI when the client status packet is intercepted ===
func _on_player_ready_changed(sender_name: String, ready_state: bool):
	if current_role == "host":
		is_client_ready = ready_state
		if ready_state:
			player_name_2.text = client_name_cached + " (I am ready)"
			start_button.disabled = false # Host can now click Start Game!
		else:
			player_name_2.text = client_name_cached + " (Not Ready)"
			start_button.disabled = true

func _exit_tree():
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		if player_node.has_node("HUD"):
			player_node.get_node("HUD").visible = true
		if player_node.has_node("Camera2D"):
			player_node.get_node("Camera2D").enabled = true

# =====================
# COUNTDOWN LOGIC
# =====================
func _start_countdown():
	is_countdown_running = true
	countdown_value = 5
	start_button.disabled = true
	
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.one_shot = false
	countdown_timer.timeout.connect(_update_countdown)
	add_child(countdown_timer)
	countdown_timer.start()
	
	_update_countdown()

func _update_countdown():
	print("Starting in... ", countdown_value)
	countdown_value -= 1
	
	if countdown_value < 0:
		countdown_timer.stop()
		countdown_timer.queue_free()
		
		if LIB_C.has_method("send_game_start"):
			LIB_C.send_game_start(selected_level)
		
		if current_role == "host":
			start_game_pressed.emit(selected_level)

# =====================
# BACK BUTTON
# =====================
func _on_back_pressed():
	LIB_C.disconnect_all()
	if current_role == "host":
		LIB_C.stopCloudflareTunnel()
		
	get_tree().change_scene_to_packed(SceneManager.scenes["main_menu"])
