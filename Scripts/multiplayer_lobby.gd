extends CanvasLayer

signal start_game_pressed(level_name: String)

@onready var panel: Panel = $Panel
@onready var role_popup: Panel = $RolePopup

# Popup Nodes (Matched to your screenshot)
@onready var host_button: Button = $RolePopup/HostButton
@onready var client_button: Button = $RolePopup/ClientButton

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
#var my_peer_id: int = multiplayer.get_unique_id()
var current_role: String = ""  # "host" or "client"

func _ready():
	# 1. Hide everything initially
	panel.visible = false
	role_popup.visible = true
	
	# === FIX: Hide the Player HUD elements if they exist ===
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		if player_node.has_node("HUD"):
			player_node.get_node("HUD").visible = false
		if player_node.has_node("Camera2D"):
			player_node.get_node("Camera2D").enabled = false
	
	my_peer_id = multiplayer.get_unique_id()
	# 2. Connect Popup Buttons
	host_button.pressed.connect(_on_host_selected)
	client_button.pressed.connect(_on_client_selected)
	
	# 3. Connect Main Lobby Buttons
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	chat_button.pressed.connect(_on_chat_pressed)
	back_button.pressed.connect(_on_back_pressed)
	level_dropdown.item_selected.connect(_on_level_selected)
	
	# 4. Populate level dropdown
	level_dropdown.clear()
	for key in SceneManager.scene_paths:
		if key.begins_with("level_"):
			level_dropdown.add_item(key)
	level_dropdown.select(0)
	
	# 5. Connect Network Signals
	if LIB_C.has_signal("player_joined"):
		LIB_C.player_joined.connect(_on_player_joined)
	if LIB_C.has_signal("player_left"):
		LIB_C.player_left.connect(_on_player_left)
	if LIB_C.has_signal("level_sync_received"):
		LIB_C.level_sync_received.connect(_on_level_sync_received)

# =====================
# ROLE SELECTION POPUP
# =====================
func _on_host_selected():
	current_role = "host"
	role_popup.visible = false
	panel.visible = true
	
	# Initialize network as Host
	LIB_C.set_role(true)
	
	# === FIX: Force a fresh connection ===
	LIB_C.disconnect_all()
	await get_tree().create_timer(0.5).timeout
	LIB_C.set_role(true)
	# ======================================
	
	# Setup Host UI
	join_button.text = "📋 Copy Link"
	link_input.editable = false
	link_input.placeholder_text = "Generating link..."
	level_dropdown.disabled = false
	start_button.disabled = true
	
	player_name_1.text = LIB_C.playerName + " (Host)"
	player_card_2.visible = false
	
	# Generate and display the Cloudflare link (if available)
	await get_tree().create_timer(1.0).timeout
	if LIB_C.has_signal("cloudflare_tunnel_ready"):
		LIB_C.cloudflare_tunnel_ready.connect(_on_tunnel_ready, CONNECT_ONE_SHOT)
		LIB_C.startCloudflareTunnel()
	else:
		# Fallback for local testing
		link_input.text = "ws://localhost:" + str(LIB_C.my_port)
		link_input.placeholder_text = ""

func _on_client_selected():
	current_role = "client"
	role_popup.visible = false
	panel.visible = true
	
	# Initialize network as Client
	LIB_C.set_role(false)
	
	# Setup Client UI
	join_button.text = "Join Game"
	link_input.editable = true
	link_input.placeholder_text = "Paste link here..."
	level_dropdown.disabled = true
	level_dropdown.text = "Waiting for Host..."
	start_button.disabled = true
	
	# === FIX: FORCE YOUR OWN NAME TO SHOW ===
	player_card_2.visible = true
	player_name_2.text = LIB_C.playerName
	# ==========================================

func _on_tunnel_ready(url: String):
	link_input.text = url
	link_input.placeholder_text = ""
	print("Link available at: ", url)
	
	# === FIX: Force the link to be fresh ===
	# We log the time it was generated so the Client knows it's fresh.
	var timestamp = Time.get_time_string_from_system()
	print("Tunnel generated at: ", timestamp)
	join_button.text = "📋 Copy Link (Fresh)"

# =====================
# UI BUTTON LOGIC
# =====================
func _on_join_pressed():
	if current_role == "host":
		# === UPDATED HOST LOGIC: Force a fresh link ===
		print("Host forcing fresh tunnel generation...")
		
		# Kill any existing tunnel and start a fresh one
		LIB_C.stopCloudflareTunnel()
		await get_tree().create_timer(0.5).timeout
		
		# Listen for the fresh link
		if LIB_C.has_signal("cloudflare_tunnel_ready"):
			LIB_C.cloudflare_tunnel_ready.connect(_on_tunnel_ready, CONNECT_ONE_SHOT)
			LIB_C.startCloudflareTunnel()
			
		# Keep the current text (it will update when the new tunnel is ready)
		link_input.text = "Refreshing..."
		link_input.editable = false
		
		return
	
	# === CLIENT JOIN LOGIC ===
	var link = link_input.text.strip_edges()
	if link.is_empty():
		return
	print("Client attempting to join: ", link)
	
	# 1. Update UI to show we are trying to connect
	player_card_2.visible = true
	player_name_2.text = "Connecting..."
	
	# 2. Call the network directly
	LIB_C.connectToCloudflareServer(link)
	
	# 3. Listen for the 'player_joined' signal ONCE (Prevent duplicates)
	if not is_connected("player_joined", _on_player_joined):
		# We connect a local listener for the Client specifically
		LIB_C.player_joined.connect(_on_player_joined, CONNECT_ONE_SHOT)
	
	# 4. Set a 10-second safety timeout (in case of a true network failure)
	var timeout_timer = Timer.new()
	timeout_timer.wait_time = 10.0
	timeout_timer.one_shot = true
	
	# Define what happens when the timeout triggers
	timeout_timer.timeout.connect(func():
		if player_name_2.text == "Connecting...":
			player_name_2.text = "Connection Failed (Timeout)"
			# Clean up the signal listener if the connection failed
			if LIB_C.player_joined.is_connected(_on_player_joined):
				LIB_C.player_joined.disconnect(_on_player_joined)
	)
	
	add_child(timeout_timer)
	timeout_timer.start()
	
	# === THE CLEANUP FIX ===
	# If the connection succeeds early, we need to stop and delete this timer
	# So the timeout doesn't fire after the player has already joined.
	var signal_cleanup = func():
		if timeout_timer and timeout_timer.is_inside_tree():
			timeout_timer.stop()
			timeout_timer.queue_free()
	
	# Connect the cleanup function to run when the connection works
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
	if current_role != "host":
		return
		
	# === 2-PLAYER CHECK ===
	var player_count = 0
	if player_card_1.visible: player_count += 1
	if player_card_2.visible: player_count += 1
	
	if player_count < 2:
		print("Need 2 players to start the game!")
		return
	
	if not is_countdown_running:
		_start_countdown()

# =====================
# NETWORK SIGNAL HANDLERS
# =====================
func _on_player_joined(player_name: String):
	print("Lobby: Player joined: ", player_name)
	
	# === FIX: Remove the "if player_name != LIB_C.playerName" check ===
	
	# 1. Logic for the Host (Sees the Client)
	if current_role == "host":
		player_card_2.visible = true
		player_name_2.text = player_name
		start_button.disabled = false
		
		# Host sends the current level selection to the new client
		var packet: Dictionary = {
			"type": "level_sync",
			"sender": LIB_C.playerName,
			"scene": selected_level
		}
		LIB_C.send_json_packet(packet)
		
	# 2. Logic for the Client (Updates its own card)
	elif current_role == "client":
		# Update the Client's own card from "Connecting..." to their name
		player_name_2.text = player_name

func _on_player_left(player_name: String):
	print("Lobby: Player left: ", player_name)
	if player_name != LIB_C.playerName:
		player_card_2.visible = false
		player_name_2.text = "Disconnected"
		start_button.disabled = true

func _on_level_sync_received(level_name: String):
	if current_role == "client":
		selected_level = level_name
		level_dropdown.text = "Level: " + level_name
		print("Client synced to level: ", selected_level)
		
		# === FIX: Update the UI to show success ===
		player_name_2.text = LIB_C.playerName


func _exit_tree():
	# If the lobby is closed, turn the player HUD back on
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
		
		# === FIX: Tell sync_node to broadcast the start ===
		if LIB_C.has_method("send_game_start"):
			LIB_C.send_game_start(selected_level)
		
		# === FIX: Load the level for the Host ===
		if current_role == "host":
			start_game_pressed.emit(selected_level)
		else:
			# Clients just wait for the sync packet
			pass

# =====================
# BACK BUTTON
# =====================
func _on_back_pressed():
	get_tree().change_scene_to_packed(SceneManager.scenes["main_menu"])
