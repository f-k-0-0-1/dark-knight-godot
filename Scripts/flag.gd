extends Node

@onready var level_complete_ui = get_tree().current_scene.find_child("LevelCompleteScreen", true, false)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		
		if level_complete_ui:
			level_complete_ui.show_level_complete()
