extends CharacterBody2D

# === CONFIG ===
@export var max_health := 100
@export var move_speed := 200.0
@export var sprint_multiplier := 3.0
@export var knockback_strength := 400.0
@export var detection_range := 800.0
@export var attack_range := 50.0
@export var attack_cooldown := 1.0

@onready var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")

# === STATE ===
var health := max_health
var is_dead := false
var is_aggro := false
var facing_right := true
var is_recoiling := false
var can_attack := true

# === AAA HIT-STUN & INVULNERABILITY ===
var hurt_lock := false
var invulnerable := false

# === NODES ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $HitBox
@onready var timer: Timer = $Timer
@onready var death_sound: AudioStreamPlayer = $DeathSound

func _ready():
	add_to_group("enemies")
	update_health_bar()
	sprite.play("idle")
	hitbox.body_entered.connect(_on_HitBox_body_entered)
	hitbox.body_exited.connect(_on_HitBox_body_exited)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	# 1. Hit-Stun: Stop all movement when hurt
	if hurt_lock:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 2. Recoil: Let the knockback finish
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
	facing_right = direction.x > 0
	sprite.flip_h = not facing_right

	var speed = move_speed
	if global_position.distance_to(player.global_position) < detection_range / 2:
		speed *= sprint_multiplier

	velocity = direction * speed

# === ANIMATION ===
func update_animation():
	if is_dead:
		return
		
	if hurt_lock:
		return
		
	if is_aggro:
		if sprite.animation != "fly" and sprite.animation != "attack":
			sprite.play("fly")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

# === AAA DAMAGE + KNOCKBACK + HIT-STUN ===
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or invulnerable:
		return
	
	# 1. Lock the enemy (Hit Stun)
	hurt_lock = true
	invulnerable = true
	
	# --- CRITICAL FIX: Use call_deferred to disable the Hitbox ---
	hitbox.call_deferred("set_monitoring", false)
	hitbox.call_deferred("set_monitorable", false)
	
	# 2. Play hurt animation
	sprite.play("hurt")
	
	health -= amount
	health = max(health, 0)
	update_health_bar()

	# 3. KNOCKBACK (Push 2x further)
	if source_position != Vector2.ZERO:
		var knockback_dir := (global_position - source_position).normalized()
		velocity = knockback_dir * knockback_strength * 2.0

	if health <= 0:
		die()
		
	# 4. Wait for the hit-stun duration (0.4s)
	await get_tree().create_timer(0.4).timeout
	
	# 5. Unlock the enemy and re-enable the Hitbox
	if not is_dead and is_instance_valid(self):
		hurt_lock = false
		hitbox.call_deferred("set_monitoring", true)
		hitbox.call_deferred("set_monitorable", true)
		
		await get_tree().create_timer(0.2).timeout # Brief invulnerability window
		invulnerable = false

func update_health_bar() -> void:
	health_bar.value = float(health) / float(max_health) * 100.0

# === DEATH ===
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
	if is_dead or is_recoiling or not can_attack or hurt_lock or invulnerable:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		can_attack = false
		sprite.play("attack")
		
		body.take_damage(25, global_position)
		camera.trigger_shake(8.0, 0.2)
		
		var recoil_direction = (global_position - body.global_position).normalized()
		velocity = recoil_direction * knockback_strength
		is_recoiling = true
		
		await get_tree().create_timer(attack_cooldown).timeout
		
		if is_instance_valid(self) and not is_dead:
			can_attack = true
			is_recoiling = false

func _on_HitBox_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		can_attack = true

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
