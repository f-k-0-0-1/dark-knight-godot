extends Area2D

@export var speed: float = 1500.0
@export var lifetime: float = 1.0  # seconds before disappearing
var direction: Vector2 = Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer  # Make sure the Timer node exists and is named "Timer"
@onready var shoot_sound: AudioStreamPlayer = $ShootSound

func _ready():
	sprite.flip_h = direction.x < 0
	sprite.play("fly")
	shoot_sound.play()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.start()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
