extends CanvasLayer

@onready var next_button: Button = $MenuPanel/NextLevelButton
@onready var retry_button: Button = $MenuPanel/RetryButton
@onready var main_menu_button: Button = $MenuPanel/MainMenuButton
@onready var quit_button: Button = $MenuPanel/QuitButton

func _ready():
	next_button.pressed.connect(_on_next_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	visible = false

func show_level_complete():	
	visible = true;

func _on_next_pressed():
	get_tree().paused = false
	var next_level: int = SceneManager.current_level.trim_prefix("level_").to_int()
	if (next_level != SceneManager.last_level):
		SceneManager.change_scene("level_" + str(next_level + 1));
	else :
		SceneManager.change_scene("credits") 

func _on_retry_pressed():
	SceneManager.change_scene(SceneManager.current_level)

func _on_main_menu_pressed():
	SceneManager.change_scene("main_menu")

func _on_quit_pressed():
	get_tree().quit()
