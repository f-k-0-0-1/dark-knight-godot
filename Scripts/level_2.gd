extends Node

var tutorial_scene := preload("res://Scenes/tutorial_popup_layer.tscn");
var tutorial_instance : CanvasLayer

func _ready() -> void:
	tutorial_instance = tutorial_scene.instantiate()
	add_child(tutorial_instance)
	tutorial_instance.show_tutorial(
		"Welcome To Level 2\n"
	)
	
	tutorial_instance.tutorial_closed.connect(_on_tutorial_closed)

func _on_tutorial_closed():
	print("Tutorial closed!")
