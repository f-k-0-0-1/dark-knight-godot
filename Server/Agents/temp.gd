
func _update_remote_player(p_name: String, pos: Vector2, anim: String, flip: bool) -> void:
	if remote_players.has(p_name):
		# CRITICAL FIX: Check validity on the raw dictionary value before typed assignment 
		# to prevent Godot 4 engine crashes when the local player dies and frees the scene.
		if is_instance_valid(remote_players[p_name]):
			var instance: CharacterBody2D = remote_players[p_name]
			instance.network_target_pos = pos
			instance.network_anim = anim
			instance.network_flip_h = flip
		else:
			remote_players.erase(p_name)
			connected_players.erase(p_name)

func _exit_tree() -> void:
	# CRITICAL FIX: Forcefully tear down all sockets and remote players on game exit
	disconnect_all()

# Add this new function and connect it in _ready() via: get_tree().node_added.connect(_on_scene_node_added)
func _on_scene_node_added(node: Node) -> void:
	# When a new scene loads, reparent all active remote players to the new scene root
	if node == get_tree().current_scene:
		for p_name in remote_players.keys():
			if is_instance_valid(remote_players[p_name]):
				var instance: Node = remote_players[p_name]
				if instance.get_parent() != node:
					instance.get_parent().remove_child(instance)
					node.add_child(instance)
