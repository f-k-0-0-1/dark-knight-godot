extends Area2D

@export var target_portal: NodePath

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var can_teleport := true

func _ready():
	body_entered.connect(_on_body_entered)

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _on_body_entered(body):

	if !body.is_in_group("player"):
		return

	if !can_teleport:
		return

	var destination: Area2D = get_node_or_null(target_portal)

	if destination == null:
		push_error("Target Portal not assigned!")
		return

	can_teleport = false
	destination.can_teleport = false

	# Play source portal animation
	sprite.play("teleport")

	# Wait 2 seconds
	await get_tree().create_timer(1.0).timeout

	# Teleport player
	body.global_position = destination.global_position + Vector2(0, -32)

	# Stop player movement (if Player.gd has velocity)
	if "velocity" in body:
		body.velocity = Vector2.ZERO

	# Play destination portal animation
	destination.sprite.play("teleport")

	# Wait 2 seconds
	await get_tree().create_timer(1.0).timeout

	# Return both portals to idle
	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	if destination.sprite.sprite_frames.has_animation("idle"):
		destination.sprite.play("idle")

	# Prevent instant re-teleport
	await get_tree().create_timer(0.5).timeout

	can_teleport = true
	destination.can_teleport = true
