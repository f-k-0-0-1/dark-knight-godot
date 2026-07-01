extends CanvasLayer

# Hide Shop Menu And Free Memory 
func _on_close_button_pressed() -> void:
	self.visible = false;
	queue_free();
