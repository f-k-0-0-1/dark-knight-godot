extends Area2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coin_sound: AudioStreamPlayer = $CoinSound

signal coin_collected

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		anim_sprite.visible = false
		$CollisionShape2D.call_deferred("set_disabled", true)
		
		if coin_sound:
			coin_sound.play()
		
		# === CHANGED: Use the Level Coin function ===
		Globals.add_level_coin()
		coin_collected.emit()
		
		await get_tree().create_timer(0.5).timeout
		queue_free()
