extends Node2D

var tutorial_scene := preload("res://Scenes/tutorial_popup_layer.tscn")
var tutorial_instance: CanvasLayer
@onready var camera: Camera2D = get_tree().get_first_node_in_group("player").get_node("Camera2D")
@onready var level_complete_screen: CanvasLayer = $LevelCompleteScreen

func _ready():
	tutorial_instance = tutorial_scene.instantiate()
	add_child(tutorial_instance)
	tutorial_instance.show_tutorial(
		"Press A/D to move\nPress W or Space to jump\nPress F or Enter to shoot\nPress G to toggle God Mode"
	)
	tutorial_instance.tutorial_closed.connect(_on_tutorial_closed)

func finish_level(stars_earned: int, current_time: float):
	var is_new_record = _save_best_time(current_time)
	$LevelCompleteScreen.show_level_complete(stars_earned, current_time, is_new_record)

func _save_best_time(current_time: float) -> bool:
	var config = ConfigFile.new()
	var file_path = "user://level_times.ini"
	
	config.load(file_path)
	
	var level_name = SceneManager.current_level
	var saved_best = config.get_value(level_name, "best_time", 9999.0)
	
	if saved_best == 0.0:
		saved_best = 9999.0
	
	var is_new_record = false
	
	if current_time < saved_best:
		config.set_value(level_name, "best_time", current_time)
		config.save(file_path)
		is_new_record = true
	
	return is_new_record

func _on_tutorial_closed():
	pass
