extends Control

@onready var retry_button: Button = $Panel/Retry
@onready var main_menu_button: Button = $"Panel/Main Menu"

var target_player: Node = null

func _ready():
	retry_button.pressed.connect(retry_level)
	main_menu_button.pressed.connect(go_to_main_menu)
	
	if has_meta("target_player"):
		target_player = get_meta("target_player")

func retry_level():
	MusicManager.play_button_click()
	if target_player and is_instance_valid(target_player) and target_player.has_method("respawn"):
		target_player.respawn()
		if get_parent() is CanvasLayer:
			get_parent().queue_free()
		else:
			queue_free()
	else:
		var target_level: String = SceneManager.current_level
		if target_level == "" or not SceneManager.scenes.has(target_level):
			target_level = "level_1"
		SceneManager.change_scene(target_level)

func go_to_main_menu():
	MusicManager.play_button_click()
	if get_parent() is CanvasLayer:
		get_parent().queue_free()
	SceneManager.change_scene("main_menu")
