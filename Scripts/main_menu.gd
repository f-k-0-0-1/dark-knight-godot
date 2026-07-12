extends Control

@onready var play_button: Button = $Panel/Play
@onready var credits_button: Button = $Panel/Credits
@onready var quit_button: Button = $Panel/Quit
@onready var play_multi_button: Button = $Panel/Play_Multi   # <-- NEW BUTTON REFERENCE
@onready var click_sound: AudioStreamPlayer = $clicksound
@onready var mute_sound_btn : Button = $Panel/Sound
@onready var panel: Panel = $Panel

# Reference to the Multiplayer Lobby scene
const MULTIPLAYER_LOBBY_SCENE = preload("res://Scenes/multiplayer_lobby.tscn")
var lobby_instance: CanvasLayer = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Check for the bg sound flag
	if !MusicManager.isMusicPlaying:
		mute_sound_btn.get_child(0).visible = true;
		mute_sound_btn.get_child(1).visible = false;
	else:
		mute_sound_btn.get_child(1).visible = true
		mute_sound_btn.get_child(0).visible = false;
		
	if not play_button or not quit_button:
		push_error("Play or Quit button not found! Check your node names and paths.")
		return

	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# === CONNECT THE MULTIPLAYER BUTTON ===
	if play_multi_button:
		play_multi_button.pressed.connect(_on_play_multi_pressed)
	else:
		push_error("Play_Multi button not found! Check your node names.")

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

# === NEW MULTIPLAYER BUTTON FUNCTION ===
func _on_play_multi_pressed():
	click_sound.play()
	await click_sound.finished
	
	# Check if the lobby is already open. If not, open it.
	if lobby_instance == null or not is_instance_valid(lobby_instance):
		# Hide the main menu buttons
		panel.visible = false
		
		# Instantiate the lobby
		lobby_instance = MULTIPLAYER_LOBBY_SCENE.instantiate()
		add_child(lobby_instance)
		
		# Connect the start signal to start the game
		lobby_instance.start_game_pressed.connect(_on_lobby_start_game)
		
		# Also, allow the lobby to close and return to menu
		# (You would need to add a "Back" button in your lobby to call this)
		# lobby_instance.back_to_menu.connect(_on_lobby_closed)

func _on_lobby_start_game(level_name: String):
	print("Starting Multiplayer Game on Level: ", level_name)
	get_tree().paused = false
	
	# Change to the selected level
	if SceneManager.scenes.has(level_name):
		get_tree().change_scene_to_packed(SceneManager.scenes[level_name])
	else:
		push_error("Level scene not found: ", level_name)

# (Optional) Function to return to main menu from lobby
func _on_lobby_closed():
	if lobby_instance != null and is_instance_valid(lobby_instance):
		lobby_instance.queue_free()
		lobby_instance = null
	panel.visible = true

func _on_sound_pressed() -> void:
	if MusicManager.isMusicPlaying:
		MusicManager.music.stop();
		mute_sound_btn.get_child(0).visible = true;
		mute_sound_btn.get_child(1).visible = false;
		MusicManager.isMusicPlaying = false;
	else:
		MusicManager.music.play();
		mute_sound_btn.get_child(1).visible = true
		mute_sound_btn.get_child(0).visible = false;
		MusicManager.isMusicPlaying = true;
