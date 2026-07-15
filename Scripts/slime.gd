extends CharacterBody2D

@export var max_health := 100
@export var move_speed := 130
@export var sprint_multiplier := 3.0
@export var move_distance := 1000
@export var knockback_strength := 200
@export var max_fall_speed := 400
@export var gravity := 900
@export var hit_cooldown := 0.75
@export var aggro_range := 800

const STATE_BROADCAST_INTERVAL: float = 0.1

var camera: Camera2D = null
var sync_id: String = ""
var is_syncing_death: bool = false
var health := max_health
var is_dead := false
var facing_right := true
var starting_position := Vector2.ZERO
var can_hit := true
var knockback_timer := 0.0
var knockback_duration := 0.2
var is_knocked_back := false
var is_recoiling := false
var recoil_timer := 0.0
var recoil_duration := 0.5
var state_broadcast_timer: float = 0.0
var last_state: Dictionary = {}
var is_remote_damage: bool = false
var network_target_pos: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	starting_position = global_position
	add_to_group("enemies")
	update_health_bar()
	sprite.play("default")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.body_exited.connect(_on_hitbox_body_exited)
	sync_id = str(get_path())
	network_target_pos = global_position
	
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node != null:
		camera = player_node.get_node_or_null("Camera2D")
		
	if LIB_C != null:
		if not LIB_C.enemy_state_received.is_connected(_on_enemy_state_received):
			LIB_C.enemy_state_received.connect(_on_enemy_state_received)
		if not LIB_C.enemy_damage_received.is_connected(_on_enemy_damage_received):
			LIB_C.enemy_damage_received.connect(_on_enemy_damage_received)
		if not LIB_C.enemy_sync_received.is_connected(_on_enemy_sync_received):
			LIB_C.enemy_sync_received.connect(_on_enemy_sync_received)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Online Client Logic: Interpolate to host position and bypass local AI
	if Globals.is_online_mode and LIB_C != null and not LIB_C.is_host:
		global_position = global_position.lerp(network_target_pos, 10.0 * delta)
		apply_gravity(delta)
		move_and_slide()
		sprite.flip_h = not facing_right
		return

	# Online Host Logic: Broadcast state
	if Globals.is_online_mode and LIB_C != null and LIB_C.is_host and not is_dead:
		state_broadcast_timer += delta
		if state_broadcast_timer >= STATE_BROADCAST_INTERVAL:
			state_broadcast_timer = 0.0
			var current_state: Dictionary = Dictionary()
			current_state["x"] = global_position.x
			current_state["y"] = global_position.y
			current_state["anim"] = sprite.animation
			current_state["flip_h"] = sprite.flip_h
			current_state["health"] = health
		
			if current_state != last_state:
				var packet: Dictionary = Dictionary()
				packet["type"] = "enemy_state"
				packet["sender"] = LIB_C.playerName
				packet["id"] = sync_id
				packet["x"] = global_position.x
				packet["y"] = global_position.y
				packet["anim"] = sprite.animation
				packet["flip_h"] = sprite.flip_h
				packet["health"] = health
				LIB_C.send_json_packet(packet)
				last_state = current_state

	if is_knocked_back:
		apply_gravity(delta)
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
	elif is_recoiling:
		apply_gravity(delta)
		recoil_timer -= delta
		if recoil_timer <= 0:
			is_recoiling = false
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

func flash_on_hit():
	var flash_tween = create_tween()
	# Flash Red instead of White
	flash_tween.tween_property(sprite, "modulate", Color.RED, 0.05)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

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
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	var closest: Node2D = null
	var closest_dist: float = INF
	for p in players:
		# Target any alive player (host or client)
		if p is CharacterBody2D and not p.is_dead:
			var dist: float = global_position.distance_to(p.global_position)
			if dist < closest_dist:
				closest = p
				closest_dist = dist
	return closest

func _on_hitbox_body_entered(body: Node) -> void:
	if is_dead or not can_hit:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		can_hit = false
		var recoil_direction: Vector2 = (global_position - body.global_position).normalized()
		velocity = recoil_direction * knockback_strength
		is_recoiling = true
		recoil_timer = recoil_duration
		body.take_damage(35, global_position)
		var target_camera: Node = camera
		if target_camera == null:
			target_camera = body.get_node_or_null("Camera2D")
		if target_camera != null and target_camera.has_method("trigger_shake"):
			target_camera.trigger_shake(8.0, 0.2)
		start_hit_cooldown()

func _on_hitbox_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		can_hit = true

func start_hit_cooldown() -> void:
	await get_tree().create_timer(hit_cooldown).timeout
	if is_instance_valid(self):
		can_hit = true

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	flash_on_hit()
	health -= amount
	health = max(health, 0)
	update_health_bar()
	
	if source_position != Vector2.ZERO:
		var knockback_dir := (global_position - source_position).normalized()
		velocity = knockback_dir * knockback_strength
		velocity.y = min(velocity.y, -50)
		is_knocked_back = true
		knockback_timer = knockback_duration
		
	if health <= 0:
		die()
		
	if Globals.is_online_mode and LIB_C != null and not is_remote_damage:
		var packet: Dictionary = Dictionary()
		packet["type"] = "enemy_damage"
		packet["sender"] = LIB_C.playerName
		packet["id"] = sync_id
		packet["damage"] = amount
		packet["source_x"] = source_position.x
		packet["source_y"] = source_position.y
		LIB_C.send_json_packet(packet)

func update_health_bar() -> void:
	health_bar.value = float(health) / float(max_health) * 100.0

@onready var death_sound: AudioStreamPlayer = $DeathSound

func _on_enemy_sync_received(enemy_id: String) -> void:
	if enemy_id == sync_id and health > 0 and not is_dead:
		take_damage(max_health, Vector2.ZERO)

func _on_enemy_state_received(sender: String, enemy_id: String, x: float, y: float, anim: String, flip_h: bool, new_health: int) -> void:
	if sender == LIB_C.playerName:
		return  # ignore own broadcasts (host)
	if LIB_C.is_host:
		return  # host does not apply others' states
	if enemy_id != sync_id or is_dead:
		return
		
	# Update target position for smooth interpolation in _physics_process
	network_target_pos = Vector2(x, y)
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = flip_h
	facing_right = not flip_h
	
	if new_health != self.health:
		self.health = new_health
		update_health_bar()

func _on_enemy_damage_received(sender: String, enemy_id: String, damage: int, source_x: float, source_y: float) -> void:
	if sender == LIB_C.playerName:
		return
	if enemy_id != sync_id or is_dead:
		return
	is_remote_damage = true
	take_damage(damage, Vector2(source_x, source_y))
	is_remote_damage = false

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
		
	health_bar.visible = false
	collision_shape.call_deferred("set_disabled", true)
	if camera != null:
		camera.trigger_shake(6.0, 0.2)
	death_sound.play()
	await death_sound.finished
	queue_free()
