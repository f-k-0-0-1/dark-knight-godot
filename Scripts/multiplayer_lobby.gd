extends CanvasLayer

signal start_game_pressed(level_name: String)

@onready var panel: Panel = $Panel

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

# === STATE ===
var players_ready := {}
var countdown_timer: Timer
var countdown_value := 5
var is_countdown_running := false
var selected_level := "level_1"

func _ready():
	# 1. Hide Player 2 immediately until someone joins
	player_card_2.visible = false
	
	# 2. Default text for Player 1
	player_name_1.text = "Host"
	
	# 3. Connect UI buttons
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)
	level_dropdown.item_selected.connect(_on_level_selected)
	
	# 4. Populate level dropdown (Optional: Automatically read from SceneManager)
	level_dropdown.clear()
	for key in SceneManager.scene_paths:
		if key.begins_with("level_"):
			level_dropdown.add_item(key)
	level_dropdown.select(0) # Select the first level by default
	
	# 5. Host setup
	_register_player("Host", multiplayer.get_unique_id())

# === PLAYER MANAGEMENT ===
func _register_player(player_name: String, peer_id: int):
	if peer_id == multiplayer.get_unique_id():
		# Host already has PlayerCard1
		players_ready[peer_id] = false
		return
	
	# New player joined -> Show PlayerCard2
	player_card_2.visible = true
	player_name_2.text = player_name
	players_ready[peer_id] = false

# === UI BUTTONS ===
func _on_join_pressed():
	var link = link_input.text.strip_edges()
	if link.is_empty():
		return
		
	print("Attempting to join: ", link)
	# Your networking join logic goes here...

func _on_level_selected(index: int):
	# ONLY the Host can change the level
	if not multiplayer.is_server():
		return
		
	selected_level = level_dropdown.get_item_text(index)
	print("Host selected level: ", selected_level)

func _on_start_pressed():
	# ONLY the Host can start the game
	if not multiplayer.is_server():
		return
		
	if not _are_all_players_ready():
		print("Not all players are ready!")
		return
	
	if not is_countdown_running:
		_start_countdown()

# === READINESS CHECK ===
func _are_all_players_ready() -> bool:
	if players_ready.is_empty():
		return false
	for peer in players_ready:
		if not players_ready[peer]:
			return false
	return true

# === COUNTDOWN LOGIC ===
func _start_countdown():
	if not multiplayer.is_server():
		return
		
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
	# Update the UI
	# (If you don't have a countdown label, you can temporarily print to the console)
	print("Starting in... ", countdown_value)
	
	countdown_value -= 1
	
	if countdown_value < 0:
		countdown_timer.stop()
		countdown_timer.queue_free()
		start_game_pressed.emit(selected_level)
