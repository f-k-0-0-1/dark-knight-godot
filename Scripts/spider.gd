extends CharacterBody2D

@export var speed: float = 80.0
@export var max_health: int = 25
@export var detection_range: float = 500.0

var state_broadcast_timer: float = 0.0
const STATE_BROADCAST_INTERVAL: float = 0.1
var last_state: Dictionary = {}
var is_remote_damage: bool = false

var current_health: int
var player: Node2D
var sync_id: String = ""
var is_syncing_death: bool = false
var is_dead: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	sync_id = str(get_path())
	
	if LIB_C != null:
		if not LIB_C.enemy_state_received.is_connected(_on_enemy_state_received):
			LIB_C.enemy_state_received.connect(_on_enemy_state_received)
		if not LIB_C.enemy_damage_received.is_connected(_on_enemy_damage_received):
			LIB_C.enemy_damage_received.connect(_on_enemy_damage_received)
	
	if LIB_C != null:
		if not LIB_C.enemy_sync_received.is_connected(_on_enemy_sync_received):
			LIB_C.enemy_sync_received.connect(_on_enemy_sync_received)

func _physics_process(delta: float) -> void:
	
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
				}
				LIB_C.send_json_packet(packet)
				last_state = current_state
	
	if not is_instance_valid(player) or not player.is_local:
		player = get_closest_player()	
	
	if not player:
		velocity = Vector2.ZERO
		sprite.play("idle")
		return
		
	var distance_to_player: float = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_range:
		velocity = Vector2.ZERO
		sprite.play("idle")
		return
		
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	sprite.flip_h = velocity.x < 0
	
	if not is_on_floor():
		sprite.play("jump")
	elif velocity.length() > 10:
		sprite.play("walk")
	else:
		sprite.play("idle")

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_health -= amount
	if current_health <= 0:
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
	
func get_closest_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
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
	if enemy_id == sync_id and current_health > 0 and not is_dead:
		take_damage(max_health, Vector2.ZERO)
		
func _on_enemy_state_received(sender: String, enemy_id: String, x: float, y: float, anim: String, flip_h: bool, _new_health: int) -> void:
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

func _on_enemy_damage_received(sender: String, enemy_id: String, damage: int, source_x: float, source_y: float) -> void:
	if sender == LIB_C.playerName:
		return
	if enemy_id != sync_id or is_dead:
		return
	is_remote_damage = true
	take_damage(damage, Vector2(source_x, source_y))
	is_remote_damage = false

func _on_hitbox_area_exited(area: Area2D) -> void:
	pass # Replace with function body.

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
		
	queue_free()
