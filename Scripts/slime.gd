extends CharacterBody2D

@export var max_health := 3
@export var move_speed := 130
@export var sprint_multiplier := 3.0
@export var move_distance := 1000
@export var knockback_strength := 200
@export var max_fall_speed := 400
@export var gravity := 900
@export var hit_cooldown := 0.5
@export var aggro_range := 800

var health := max_health
var is_dead := false
var facing_right := true
var starting_position := Vector2.ZERO
var can_hit := true
var knockback_timer := 0.0
var knockback_duration := 0.2
var is_knocked_back := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox

func _ready():
	starting_position = global_position
	add_to_group("enemies")
	update_health_bar()
	sprite.play("default")
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_knocked_back:
		apply_gravity(delta)
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
	else:
		var player = get_closest_player()
		if player and global_position.distance_to(player.global_position) <= aggro_range:
			chase_player(player)
		else:
			patrol()

		apply_gravity(delta)

	move_and_slide()
	sprite.flip_h = not facing_right

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		velocity.y = 0

func patrol() -> void:
	var distance_from_start := global_position.x - starting_position.x

	if facing_right and distance_from_start >= move_distance / 2.0:
		flip_direction()
	elif not facing_right and distance_from_start <= -move_distance / 2.0:
		flip_direction()

	velocity.x = (1 if facing_right else -1) * move_speed

	if not sprite.is_playing() or sprite.animation != "default":
		sprite.play("default")

func chase_player(player: Node2D) -> void:
	var direction = sign(player.global_position.x - global_position.x)
	facing_right = direction > 0
	velocity.x = direction * move_speed * sprint_multiplier

	if not sprite.is_playing() or sprite.animation != "sprint":
		sprite.play("sprint")

func flip_direction() -> void:
	facing_right = not facing_right

func get_closest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null

	var closest = players[0]
	var closest_dist = global_position.distance_to(closest.global_position)
	for p in players:
		var d = global_position.distance_to(p.global_position)
		if d < closest_dist:
			closest = p
			closest_dist = d
	return closest

func _on_hitbox_body_entered(body: Node) -> void:
	if is_dead or not can_hit:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		can_hit = false
		body.take_damage(25, global_position)
		start_hit_cooldown()

func start_hit_cooldown() -> void:
	await get_tree().create_timer(hit_cooldown).timeout
	if is_instance_valid(self):
		can_hit = true

func take_damage(amount: int, knockback_dir := Vector2.ZERO) -> void:
	if is_dead:
		return

	health -= amount
	health = max(health, 0)
	update_health_bar()

	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * knockback_strength
		velocity.y = min(velocity.y, -50)  # Prevent extreme downward spikes
		is_knocked_back = true
		knockback_timer = knockback_duration

	if health <= 0:
		die()

func update_health_bar() -> void:
	health_bar.value = float(health) / float(max_health) * 100.0

@onready var death_sound: AudioStreamPlayer = $DeathSound

func die() -> void:
	is_dead = true
	health_bar.visible = false
	collision_shape.call_deferred("set_disabled", true)
	death_sound.play()
	await death_sound.finished
	queue_free()
