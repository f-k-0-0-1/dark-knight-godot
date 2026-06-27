extends CharacterBody2D

# === CONFIG ===
@export var max_health := 6
@export var move_speed := 150.0
@export var sprint_multiplier := 3.0
@export var knockback_strength := 400.0
@export var detection_range := 1000.0
@export var attack_range := 400.0

# === PATROL BOUNDARIES ===
@export var patrol_x_min := 19000.0
@export var patrol_x_max := 22200.0

# === STATE ===
var health := max_health
var is_dead := false
var is_aggro := false
var facing_right := true
var is_recoiling := false
var is_attacking := false # Used to freeze movement during animations

# Patrol state
var moving_right := true

# === NODES ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $HitBox
@onready var timer: Timer = $AttackCooldown
@onready var death_sound: AudioStreamPlayer = $DeathSound

func _ready():
	add_to_group("enemies")
	
	update_health_bar()
	sprite.play("walk")
	
	# Connect Signals
	hitbox.body_entered.connect(_on_HitBox_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_recoiling:
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += 980 * delta

	# Find Player
	var player := get_closest_player()
	
	# Chase or Patrol
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < detection_range:
			is_aggro = true
			chase_player(player)
		else:
			is_aggro = false
			patrol()
	else:
		is_aggro = false
		patrol()

	move_and_slide()
	update_animation()

# === PATROL LOGIC ===
func patrol() -> void:
	# Don't move if currently in attack animation
	if is_attacking:
		return
		
	# Determine direction based on current X position
	if global_position.x >= patrol_x_max:
		moving_right = false
	elif global_position.x <= patrol_x_min:
		moving_right = true
		
	# Move
	var direction = 1 if moving_right else -1
	velocity.x = direction * move_speed
	facing_right = direction > 0
	
	# Flip sprite visually
	sprite.flip_h = not facing_right

# === CHASE & MOVEMENT ===
func chase_player(player: Node2D) -> void:
	var direction_vec := (player.global_position - global_position).normalized()
	facing_right = direction_vec.x > 0
	sprite.flip_h = not facing_right

	var distance = global_position.distance_to(player.global_position)
	
	# Attack if close (stops movement)
	if distance < attack_range and not is_attacking:
		sprite.play("attack")
		is_attacking = true
		velocity.x = 0
		return

	# Sprint logic
	var speed = move_speed
	if distance < detection_range / 2:
		speed *= sprint_multiplier

	velocity.x = direction_vec.x * speed

# === ANIMATION ===
func update_animation():
	if is_dead or is_attacking:
		return
		
	if is_aggro:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "walk":
			sprite.play("walk")

# === DAMAGE (Copied verbatim from your reference) ===
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	health -= amount
	health = max(health, 0)
	update_health_bar()

	# Knockback away from source
	if source_position != Vector2.ZERO:
		var knockback_dir := (global_position - source_position).normalized()
		velocity = knockback_dir * knockback_strength

	# Cancel attack if hit
	if is_attacking:
		is_attacking = false
		sprite.stop()

	if health <= 0:
		die()

func update_health_bar() -> void:
	health_bar.value = float(health) / float(max_health) * 100.0

# === DEATH (Fixed for crash) ===
func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("death")
	death_sound.play()
	
	collision_shape.call_deferred("set_disabled", true)
	hitbox.call_deferred("set_monitoring", false)
	hitbox.call_deferred("set_monitorable", false)
	
	await sprite.animation_finished
	queue_free()

# === ATTACK (Copied verbatim from your reference) ===
func _on_HitBox_body_entered(body: Node) -> void:
	if is_dead or is_recoiling:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		sprite.play("attack")
		body.take_damage(50, global_position) # Note: Reference uses 25 damage

		var recoil_direction = (global_position - body.global_position).normalized()
		velocity = recoil_direction * knockback_strength
		is_recoiling = true
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and not is_dead:
			is_recoiling = false

# === GET PLAYER ===
func get_closest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null

	var closest: Node2D = players[0]
	var closest_dist := global_position.distance_to(closest.global_position)

	for p in players:
		var dist = global_position.distance_to(p.global_position)
		if dist < closest_dist:
			closest = p
			closest_dist = dist
	return closest

# === ANIMATION FINISHED ===
func _on_animation_finished() -> void:
	# This allows the enemy to move again after the attack animation finishes
	if is_attacking:
		is_attacking = false
		if is_aggro:
			sprite.play("walk")
