extends Control

@onready var panel: Panel = $Panel
@onready var play_button: Button = $Panel/Play
@onready var credits_button: Button = $Panel/Credits
@onready var quit_button: Button = $Panel/Quit
@onready var play_multi_button: Button = $Panel/Play_Multi
@onready var click_sound: AudioStreamPlayer = $clicksound
@onready var mute_sound_btn : Button = $Panel/Sound

# === NEW: Reference the Name Popup nodes (Based on your Screenshot) ===
@onready var name_popup: Panel = $NamePopup
@onready var name_input: LineEdit = $NamePopup/NameInput
@onready var confirm_name_button: Button = $NamePopup/ConfirmNameButton
@onready var popup_title: Label = $NamePopup/PopupTitle

# Reference to the Multiplayer Lobby scene
const MULTIPLAYER_LOBBY_SCENE = preload("res://Scenes/multiplayer_lobby.tscn")
var lobby_instance: CanvasLayer = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Check for the bg sound flag
	if !MusicManager.isMusicPlaying:
		mute_sound_btn.get_child(0).visible = true
		mute_sound_btn.get_child(1).visible = false
	else:
		mute_sound_btn.get_child(1).visible = true
		mute_sound_btn.get_child(0).visible = false
		
	if not play_button or not quit_button:
		push_error("Play or Quit button not found! Check your node names and paths.")
		return

	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if play_multi_button:
		play_multi_button.pressed.connect(_on_play_multi_pressed)
	else:
		push_error("Play_Multi button not found! Check your node names.")
		
	# === NEW: NAME POPUP LOGIC ===
	# Hide the popup by default
	name_popup.visible = false
	
	# Check if a name is saved
	var saved_name = LIB_C.load_player_name()
	
	if saved_name == "":
		# No name saved -> Show the popup
		name_popup.visible = true
		confirm_name_button.pressed.connect(_on_confirm_name_pressed)
		name_input.grab_focus() # Automatically focus the text box
	else:
		print("Name already saved: ", saved_name)

# === NEW: Confirm Name Button Handler ===
func _on_confirm_name_pressed():
	var new_name = name_input.text.strip_edges()
	if new_name == "":
		# Do NOT assign a random name. Just alert the player and refocus.
		name_input.grab_focus()
		print("Please enter a valid name before confirming.")
		return
	
	# Save the name to disk
	LIB_C.save_player_name(new_name)
	LIB_C.playerName = new_name
	
	# Close the popup
	name_popup.visible = false
	print("Player name saved: ", new_name)

func _on_play_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().paused = false
	
	if SceneManager.scenes.has("level_select"):
		get_tree().change_scene_to_packed(SceneManager.scenes["level_select"])
	else:
		push_error("Scene 'LevelSelect' not found in SceneManager!")
		
func _on_credits_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().change_scene_to_packed(SceneManager.scenes["credits"])

func _on_quit_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().paused = false
	get_tree().quit()

func _on_play_multi_pressed():
	click_sound.play()
	await click_sound.finished
	
	if lobby_instance == null or not is_instance_valid(lobby_instance):
		# Hide the ENTIRE MainMenu control
		visible = false  
		
		# Instantiate the lobby
		lobby_instance = MULTIPLAYER_LOBBY_SCENE.instantiate()
		add_child(lobby_instance)
		
		# Connect the start signal to start the game
		lobby_instance.start_game_pressed.connect(_on_lobby_start_game)

func _on_lobby_start_game(level_name: String):
	print("Starting Multiplayer Game on Level: ", level_name)
	get_tree().paused = false
	
	# Change to the selected level
	if SceneManager.scenes.has(level_name):
		get_tree().change_scene_to_packed(SceneManager.scenes[level_name])
	else:
		push_error("Level scene not found: ", level_name)

func _on_lobby_closed():
	if lobby_instance != null and is_instance_valid(lobby_instance):
		lobby_instance.queue_free()
		lobby_instance = null
	panel.visible = true

func _on_sound_pressed() -> void:
	if MusicManager.isMusicPlaying:
		MusicManager.music.stop()
		mute_sound_btn.get_child(0).visible = true
		mute_sound_btn.get_child(1).visible = false
		MusicManager.isMusicPlaying = false
	else:
		MusicManager.music.play()
		mute_sound_btn.get_child(1).visible = true
		mute_sound_btn.get_child(0).visible = false
		MusicManager.isMusicPlaying = true
