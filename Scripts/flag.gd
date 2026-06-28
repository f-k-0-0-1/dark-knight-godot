extends Node

@onready var level_complete_ui = get_tree().current_scene.find_child("LevelCompleteScreen", true, false)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 1. Tell the player to stop its timer
		if body.has_method("stop_level_timer"):
			body.stop_level_timer()
		
		# 2. Freeze the game
		get_tree().paused = true
		
		# 3. Open the Level Complete Screen
		var level_root = get_parent()
		if level_root.has_method("finish_level"):
			level_root.finish_level()
