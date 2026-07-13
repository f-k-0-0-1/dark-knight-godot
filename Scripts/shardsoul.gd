extends CharacterBody2D

# === CONFIG ===
@export var max_health := 400
@export var move_speed := 150.0
@export var sprint_multiplier := 3.0
@export var knockback_strength := 400.0
@export var detection_range := 1000.0
@export var attack_range := 400.0
@export var attack_cooldown := 1.0

# Online
var state_broadcast_timer: float = 0.0
const STATE_BROADCAST_INTERVAL: float = 0.1
var last_state: Dictionary = {}
var is_remote_damage: bool = false

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
var can_attack := true
var sync_id: String = ""
var is_syncing_death: bool = false

# Patrol state
var moving_right := true

# === NODES ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $HitBox
@onready var timer: Timer = $AttackCooldown
@onready var death_sound: AudioStreamPlayer = $DeathSound

func _ready() -> void:
	add_to_group("enemies")
	update_health_bar()
	sprite.play("walk")
	sync_id = str(get_path())
	
	hitbox.body_entered.connect(_on_HitBox_body_entered)
	hitbox.body_exited.connect(_on_HitBox_body_exited)
	sprite.animation_finished.connect(_on_animation_finished)
	
	if LIB_C != null:
		if not LIB_C.enemy_state_received.is_connected(_on_enemy_state_received):
			LIB_C.enemy_state_received.connect(_on_enemy_state_received)
		if not LIB_C.enemy_damage_received.is_connected(_on_enemy_damage_received):
			LIB_C.enemy_damage_received.connect(_on_enemy_damage_received)
	
	if LIB_C != null:
		if not LIB_C.enemy_sync_received.is_connected(_on_enemy_sync_received):
			LIB_C.enemy_sync_received.connect(_on_enemy_sync_received)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Online Sync Logic
	if Globals.is_online_mode and LIB_C != null and LIB_C.is_host and not is_dead:
		state_broadcast_timer += delta
		if state_broadcast_timer >= STATE_BROADCAST_INTERVAL:
			state_broadcast_timer = 0.0
			var current_state = {
				"x": global_position.x,
				"y": global_position.y,
				"anim": sprite.animation,
				"flip_h": sprite.flip_h,
				"health": health
			}
			if current_state != last_state:
				var packet: Dictionary = {
					"type": "enemy_state",
					"sender": LIB_C.playerName,
					"id": sync_id,
					"x": global_position.x,
					"y": global_position.y,
					"anim": sprite.animation,
					"flip_h": sprite.flip_h,
					"health": health
				}
				LIB_C.send_json_packet(packet)
				last_state = current_state

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
	if source_position != Vector2.ZERO:
		var knockback_dir := (global_position - source_position).normalized()
		velocity = knockback_dir * knockback_strength
	if is_attacking:
		is_attacking = false
		sprite.stop()
	if health <= 0:
		die()
		
	if Globals.is_online_mode and LIB_C != null and not is_remote_damage:
		var packet: Dictionary = {
			"type": "enemy_damage",
			"sender": LIB_C.playerName,
			"id": sync_id,
			"damage": amount,
			"source_x": source_position.x,
			"source_y": source_position.y
		}
		LIB_C.send_json_packet(packet)

func _on_enemy_damage_received(sender: String, enemy_id: String, damage: int, source_x: float, source_y: float) -> void:
	if sender == LIB_C.playerName:
		return
	if enemy_id != sync_id or is_dead:
		return
	is_remote_damage = true
	take_damage(damage, Vector2(source_x, source_y))
	is_remote_damage = false

func update_health_bar() -> void:
	health_bar.value = float(health) / float(max_health) * 100.0

# === DEATH (Fixed for crash) ===
func die() -> void:
	if is_dead:
		return
	is_dead = true

	if LIB_C != null:
		var packet: Dictionary = Dictionary()
		packet["type"] = "enemy_sync"
		packet["sender"] = LIB_C.playerName
		packet["id"] = sync_id
		LIB_C.send_json_packet(packet)
		
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
	if is_dead or is_recoiling or not can_attack:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		can_attack = false
		sprite.play("attack")
		body.take_damage(50, global_position) # Note: Reference uses 25 damage

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

func get_closest_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
		
	var closest: Node2D = null
	var closest_dist: float = INF
	
	for p in players:
		if p is CharacterBody2D and p.is_local:
			var dist: float = global_position.distance_to(p.global_position)
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

func _on_enemy_sync_received(enemy_id: String) -> void:
	if enemy_id == sync_id and health > 0 and not is_syncing_death:
		is_syncing_death = true
		take_damage(max_health, Vector2.ZERO)

func _on_enemy_state_received(sender: String, enemy_id: String, x: float, y: float, anim: String, flip_h: bool, new_health: int) -> void:
	if sender == LIB_C.playerName:
		return  # ignore own broadcasts (host)
	if LIB_C.is_host:
		return  # host does not apply others' states
	if enemy_id != sync_id or is_dead:
		return

	# Update position with interpolation or direct
	global_position = Vector2(x, y)  # or lerp
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = flip_h
	if new_health != self.health:
		self.health = new_health
		update_health_bar()
