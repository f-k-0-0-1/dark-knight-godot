extends CharacterBody2D

@export var speed: float = 80.0
@export var max_health: int = 25
@export var detection_range: float = 500.0

var current_health: int
var player: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready():
	current_health = max_health
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if not player or not is_instance_valid(player):
		velocity = Vector2.ZERO
		sprite.play("idle")
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > detection_range:
		velocity = Vector2.ZERO
		sprite.play("idle")
		return

	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	# Flip sprite
	sprite.flip_h = velocity.x < 0

	# Animate
	if not is_on_floor():
		sprite.play("jump")
	elif velocity.length() > 10:
		sprite.play("walk")
	else:
		sprite.play("idle")

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	# Optional: add particles, sound, etc.
	queue_free()

func _on_hitbox_area_exited(area: Area2D) -> void:
	pass # Replace with function body.
