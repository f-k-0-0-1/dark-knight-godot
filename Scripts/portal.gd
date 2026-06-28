extends Area2D

@export var target_portal: NodePath
@export var portal_effect: CanvasLayer # DRAG PortalEffect here in the Inspector

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var can_teleport := true
var destination: Area2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _on_body_entered(body):
	if !body.is_in_group("player"):
		return
	if !can_teleport:
		return

	var dest = get_node_or_null(target_portal)
	if dest == null:
		push_error("Target Portal not assigned!")
		return

	# Store destination and disable teleports
	destination = dest
	can_teleport = false
	destination.can_teleport = false
	
	# Freeze the player
	body.set_process(false)
	body.set_physics_process(false)
	
	# Play source portal animation
	sprite.play("teleport")
	
	# === TRIGGER THE EFFECT ===
	if portal_effect:
		print("Portal: Triggering effect...")
		portal_effect.portal_warp_complete.connect(_on_warp_finished, CONNECT_ONE_SHOT)
		portal_effect.trigger_portal() # Start the shader animation
	else:
		print("ERROR: portal_effect is null! Did you drag it into the Inspector?")
		await get_tree().create_timer(1.0).timeout
		_finish_teleport(body)

func _on_warp_finished():
	print("Portal: Received finish signal!")
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_finish_teleport(player)

func _finish_teleport(body):
	# 1. Teleport the player
	body.global_position = destination.global_position + Vector2(0, -32)
	if "velocity" in body:
		body.velocity = Vector2.ZERO

	# 2. Unfreeze player
	body.set_process(true)
	body.set_physics_process(true)

	# 3. Play destination portal animation
	if destination:
		destination.sprite.play("teleport")

	# 4. Return both portals to idle
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(self) and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	if is_instance_valid(destination) and destination.sprite.sprite_frames.has_animation("idle"):
		destination.sprite.play("idle")

	# 5. Cooldown Reset
	await get_tree().create_timer(0.5).timeout
	can_teleport = true
	if destination and is_instance_valid(destination):
		destination.can_teleport = true
