extends Node

# ALWAYS SET THE LAST LEVEL PLS !!! IMPORTANT
var last_level : int = 3

# Dic of scenes
var scene_paths: Dictionary = {
	"main_menu": "res://Scenes/main_menu.tscn",
	"level_select": "res://Scenes/LevelSelect.tscn",
	"level_1": "res://Scenes/level_1.tscn",
	"level_2": "res://Scenes/level_2.tscn",
	"level_3" : "res://Scenes/level_3.tscn",
	"retry_menu": "res://Scenes/retry.tscn",
	"fireball_scene": "res://Scenes/fireball.tscn",
	"credits": "res://Scenes/credits.tscn",
	"floating_text": "res://Scenes/FloatingText.tscn",
	"cheat_command" : "res://Scenes/cheat_command.tscn"
}
# Loaded Scenes Dic
var scenes: Dictionary = {}
var current_level: String = ""

# Signal to PBar
signal preload_progress_updated(per: float)
signal all_scenes_ready()

func _ready() -> void:
	pass

func start_global_preload() -> void:
	var total_scenes: float = scene_paths.size()
	var current_index: float = 0.0
	
	for scene_key in scene_paths:
		var path = scene_paths[scene_key]
		
		if ResourceLoader.exists(path):
			scenes[scene_key] = load(path)
		else:
			push_error("Scene not found: %s" % path)
			
		current_index += 1.0
		
		# Calculate progress
		var total_per = (current_index / total_scenes) * 100.0
		preload_progress_updated.emit(total_per)
		
		# UPdate frame 
		await get_tree().process_frame

	# Everything is loaded
	all_scenes_ready.emit()

func get_scene(scene_name: String) -> PackedScene:
	if scenes.has(scene_name):
		return scenes[scene_name]
	push_error("Scene '%s' not registered in SceneManager!" % scene_name)
	return null

func change_scene(scene_name: String) -> void:
	var scene = get_scene(scene_name)

	if scene:
		if scene_name.begins_with("level_") and scene_name != "level_select":
			current_level = scene_name

		get_tree().change_scene_to_packed(scene)
