extends Area2D

@export var damage: int = 1
@export var grow_duration: float = 0.3
@export var full_scale: Vector2 = Vector2(1, 1)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D

@onready var shoot_sound: AudioStreamPlayer = $ShootSound

func _ready():
	# Play the animation once
	sprite.play("charge")
	shoot_sound.play()
	# Start with scale 0 and tween to full scale
	shape.scale = Vector2.ZERO
	var tween := get_tree().create_tween()
	tween.tween_property(shape, "scale", full_scale, grow_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Destroy this node after the animation is done
	sprite.animation_finished.connect(queue_free)

	# Enable damage
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
