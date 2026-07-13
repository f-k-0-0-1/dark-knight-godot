extends CharacterBody2D

# === CONFIG ===
@export var max_health := 100
@export var move_speed := 200.0
@export var sprint_multiplier := 3.0
@export var knockback_strength := 400.0
@export var detection_range := 800.0
@export var attack_range := 50.0
@export var attack_cooldown := 1.0

var camera: Camera2D = null
var sync_id: String = ""
var is_syncing_death: bool = false;
var state_broadcast_timer: float = 0.0
const STATE_BROADCAST_INTERVAL: float = 0.1
var last_state: Dictionary = {}
var is_remote_damage: bool = false

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
	
	sync_id = str(get_path())

	# Safely resolve local player camera
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is CharacterBody2D and p.is_local:
			camera = p.get_node_or_null("Camera2D")
			break
	
	if LIB_C != null:
		if not LIB_C.enemy_state_received.is_connected(_on_enemy_state_received):
			LIB_C.enemy_state_received.connect(_on_enemy_state_received)
		if not LIB_C.enemy_damage_received.is_connected(_on_enemy_damage_received):
			LIB_C.enemy_damage_received.connect(_on_enemy_damage_received)
	
	if LIB_C != null:
		if not LIB_C.enemy_sync_received.is_connected(_on_enemy_sync_received):
			LIB_C.enemy_sync_received.connect(_on_enemy_sync_received)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
			
	# Online Sync Logic
	if Globals.is_online_mode and LIB_C != null and LIB_C.is_host and not is_dead:
		state_broadcast_timer += _delta
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
	hurt_lock = true
	invulnerable = true
	hitbox.call_deferred("set_monitoring", false)
	hitbox.call_deferred("set_monitorable", false)
	sprite.play("hurt")
	health -= amount
	health = max(health, 0)
	update_health_bar()
	if source_position != Vector2.ZERO:
		var knockback_dir := (global_position - source_position).normalized()
		velocity = knockback_dir * knockback_strength * 2.0
	if health <= 0:
		die()
	await get_tree().create_timer(0.4).timeout
	if not is_dead and is_instance_valid(self):
		hurt_lock = false
		hitbox.call_deferred("set_monitoring", true)
		hitbox.call_deferred("set_monitorable", true)
		await get_tree().create_timer(0.2).timeout
		invulnerable = false
	
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

# === DEATH ===
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
	if camera:
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
	
func _on_enemy_sync_received(enemy_id: String) -> void:
	if enemy_id == sync_id and not is_dead and not is_syncing_death:
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
