extends StaticBody2D

func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(25, global_position);
