extends CharacterBody2D

@export var speed: float = 80.0
@export var max_health: int = 25
@export var detection_range: float = 500.0

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
		if not LIB_C.enemy_sync_received.is_connected(_on_enemy_sync_received):
			LIB_C.enemy_sync_received.connect(_on_enemy_sync_received)

func _physics_process(delta: float) -> void:
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
