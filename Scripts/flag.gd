extends Node

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Get the level 
		var next_level: int = SceneManager.current_level.trim_prefix("level_").to_int()
		
		# Chanage scene if not on last level
		if (next_level != SceneManager.last_level):
			SceneManager.change_scene("level_" + str(next_level + 1));
		else :
			SceneManager.change_scene("credits")
