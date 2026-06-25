extends Node

# Dictionary of loaded scenes
var scenes: Dictionary = {}

func _ready():
	# Use load() instead of preload() for safety
	_add_scene("main_menu", "res://Scenes/main_menu.tscn")
	_add_scene("level_select", "res://Scenes/LevelSelect .tscn")
	_add_scene("level_1", "res://Scenes/level_1.tscn")
	_add_scene("level_2", "res://Scenes/level_2.tscn")
	_add_scene("retry_menu", "res://Scenes/retry.tscn")
	_add_scene("fireball_scene", "res://Scenes/fireball.tscn")
	_add_scene("credits", "res://Scenes/credits.tscn")

# Helper to add scenes safely
func _add_scene(name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		scenes[name] = load(path)
	else:
		push_error("Scene not found: %s" % path)

# Accessor
func get_scene(name: String) -> PackedScene:
	if scenes.has(name):
		return scenes[name]
	push_error("Scene '%s' not registered in SceneManager!" % name)
	return null

# Quick scene change
func change_scene(name: String) -> void:
	var scene = get_scene(name)
	if scene:
		get_tree().change_scene_to_packed(scene)
