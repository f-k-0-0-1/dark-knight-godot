extends Node

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 1. Tell the player to stop its internal timer
		if body.has_method("stop_level_timer"):
			body.stop_level_timer()
		
		# 2. Ask the player how many stars they earned
		var stars_earned = 0
		if body.has_method("get_stars_earned"):
			stars_earned = body.get_stars_earned()
		
		# 3. Freeze the game
		get_tree().paused = true
		
		# 4. Pass the stars to the Level Root
		var level_root = get_parent()
		if level_root.has_method("finish_level"):
			level_root.finish_level(stars_earned)
