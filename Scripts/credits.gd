extends Control

@onready var back_button: Button = $Panel/back

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	get_tree().change_scene_to_packed(SceneManager.scenes["main_menu"])
