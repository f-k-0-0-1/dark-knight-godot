extends Area2D

var has_triggered: bool = false

func _ready() -> void:
	if LIB_C != null:
		if not LIB_C.level_sync_received.is_connected(_on_level_sync_received):
			LIB_C.level_sync_received.connect(_on_level_sync_received)

func _on_body_entered(body: Node2D) -> void:
	if has_triggered:
		return
		
	if body.is_in_group("player") and body.is_local:
		has_triggered = true
		
		if body.has_method("stop_level_timer"):
			body.stop_level_timer()
			
		var stars_earned: int = 0
		if body.has_method("get_stars_earned"):
			stars_earned = body.get_stars_earned()
			
		var current_time: float = 0.0
		if body.has_method("get_current_time"):
			current_time = body.get_current_time()
			
		get_tree().paused = true
		
		var level_root: Node = get_parent()
		if level_root.has_method("finish_level"):
			level_root.finish_level(stars_earned, current_time)
			
		# Broadcast level completion to advance clients
		if LIB_C != null:
			var current_level: String = SceneManager.current_level
			var next_level: String = ""
			var level_num: int = current_level.trim_prefix("level_").to_int()
			
			if level_num != SceneManager.last_level:
				next_level = "level_" + str(level_num + 1)
			else:
				next_level = "credits"
				
			var packet: Dictionary = {
				"type": "level_sync",
				"sender": LIB_C.playerName,
				"scene": next_level
			}
			LIB_C.send_json_packet(packet)

func _on_level_sync_received(scene_name: String) -> void:
	if not has_triggered:
		has_triggered = true
		get_tree().paused = false 
		SceneManager.change_scene(scene_name)
