extends CharacterBody2D

# === CONFIG ===
@export var max_health := 1
@export var move_speed := 200.0
@export var sprint_multiplier := 3.0
@export var knockback_strength := 400.0
@export var detection_range := 800.0
@export var attack_range := 50.0

@onready var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")

# === STATE ===
var health := max_health
var is_dead := false
var is_aggro := false
var facing_right := true
var is_recoiling := false

# === NODES ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $HitBox
@onready var timer: Timer = $Timer

func _ready():
	add_to_group("enemies")
	update_health_bar()
	sprite.play("idle")
	hitbox.body_entered.connect(_on_HitBox_body_entered)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if is_recoiling:
		move_and_slide()
		return

	var player := get_closest_player()
	if player:
		var distance = global_position.distance_to(player.global_position)

		if distance < detection_range:
			is_aggro = true
			chase_player(player)
		else:
			is_aggro = false
			velocity = Vector2.ZERO
	else:
		is_aggro = false
		velocity = Vector2.ZERO

	move_and_slide()
	update_animation()

# === CHASE & MOVEMENT ===
func chase_player(player: Node2D) -> void:
	var direction := (player.global_position - global_position).normalized()

	# Flip sprite based on direction
	facing_right = direction.x > 0
	sprite.flip_h = not facing_right

	# Sprint if close
	var speed = move_speed
	if global_position.distance_to(player.global_position) < detection_range / 2:
		speed *= sprint_multiplier

	velocity = direction * speed

# === ANIMATION ===
func update_animation():
	if is_dead:
		return
	if is_aggro:
		if sprite.animation != "fly":
			sprite.play("fly")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

# === DAMAGE ===
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

	sprite.play("hurt")

	if health <= 0:
		die()

func update_health_bar() -> void:
	health_bar.value = float(health) / float(max_health) * 100.0

# === DEATH ===
@onready var death_sound: AudioStreamPlayer = $DeathSound

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("death")
	camera.trigger_shake(8.0, 0.2)
	death_sound.play()
	collision_shape.call_deferred("set_disabled", true)
	await sprite.animation_finished
	queue_free()

# === ATTACK ===
func _on_HitBox_body_entered(body: Node) -> void:
	if is_dead or is_recoiling:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		sprite.play("attack")
		body.take_damage(25, global_position)
		camera.trigger_shake(8.0, 0.2)
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
