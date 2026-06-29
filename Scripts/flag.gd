extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("stop_level_timer"):
			body.stop_level_timer()
		
		var stars_earned = 0
		if body.has_method("get_stars_earned"):
			stars_earned = body.get_stars_earned()
		
		var current_time = 0.0
		if body.has_method("get_current_time"):
			current_time = body.get_current_time()
			print("FLAG READ: ", current_time) # <-- LOOK HERE
		
		get_tree().paused = true
		
		var level_root = get_parent()
		if level_root.has_method("finish_level"):
			level_root.finish_level(stars_earned, current_time)
