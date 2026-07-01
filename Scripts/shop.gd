extends CanvasLayer

@onready var coin_label: Label = $Panel/CoinDisplayLabel
@onready var sprite: AnimatedSprite2D = $Panel/AnimatedSprite2D

func _ready():
	sprite.play("default")
	update_ui()

func update_ui():
	coin_label.text = str(Globals.player_coins)
# Hide Shop Menu And Free Memory 
func _on_close_button_pressed() -> void:
	self.visible = false;
	queue_free();
