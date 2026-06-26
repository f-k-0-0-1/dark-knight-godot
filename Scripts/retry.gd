extends Control

@onready var retry_button: Button = $Panel/Retry
@onready var main_menu_button: Button = $"Panel/Main Menu"

func _ready():
	retry_button.pressed.connect(retry_level)
	main_menu_button.pressed.connect(go_to_main_menu)

func retry_level():
	MusicManager.play_button_click()
	SceneManager.change_scene(SceneManager.current_level)

func go_to_main_menu():
	MusicManager.play_button_click()
	get_tree().change_scene_to_packed(SceneManager.scenes["main_menu"])
	
