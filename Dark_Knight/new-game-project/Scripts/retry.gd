extends Control

@onready var retry_button: Button = $Panel/Retry
@onready var main_menu_button: Button = $"Panel/Main Menu"

func _ready():
	retry_button.pressed.connect(retry_level)
	main_menu_button.pressed.connect(go_to_main_menu)

func retry_level():
	get_tree().change_scene_to_packed(SceneManager.scenes["level_1"])

func go_to_main_menu():
	get_tree().change_scene_to_packed(SceneManager.scenes["main_menu"])
	
