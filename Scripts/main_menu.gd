extends Control

@onready var play_button: Button = $Panel/Play
@onready var credits_button: Button = $Panel/Credits
@onready var quit_button: Button = $Panel/Quit

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not play_button or not quit_button:
		push_error("Play or Quit button not found! Check your node names and paths.")
		return

	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	get_tree().paused = false
	
	if SceneManager.scenes.has("level_1"):
		get_tree().change_scene_to_packed(SceneManager.scenes["level_1"])
	else:
		push_error("Scene 'level_1' not found in SceneManager!")
		
func _on_credits_pressed():
	get_tree().change_scene_to_packed(SceneManager.scenes["credits"])

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().quit()
