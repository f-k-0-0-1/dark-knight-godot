extends Node2D

var tutorial_scene := preload("res://Scenes/tutorial_popup_layer.tscn")
var tutorial_instance: CanvasLayer

func _ready():
	tutorial_instance = tutorial_scene.instantiate()
	add_child(tutorial_instance)
	tutorial_instance.show_tutorial(
		"Welcome To Level 1\nTUTORIAL:\nPress A/D to move\nPress W or Space to jump\nPress F or Enter to shoot\nPress G to toggle God Mode"
	)
	tutorial_instance.tutorial_closed.connect(_on_tutorial_closed)

func _on_tutorial_closed():
	print("Tutorial closed!")
