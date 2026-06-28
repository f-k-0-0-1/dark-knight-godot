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

func finish_level(stars_earned: int):
	camera.trigger_shake(15.0, 0.6)
	level_complete_screen.show_level_complete(stars_earned)

func _on_tutorial_closed():
	print("Tutorial closed!")
