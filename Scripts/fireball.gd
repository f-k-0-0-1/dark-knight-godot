extends Area2D

@export var speed: float = 1500.0
@export var lifetime: float = 1.0  # seconds before disappearing
var direction: Vector2 = Vector2.RIGHT
var _destroy_sent: bool = false
var is_remote: bool = false

@onready var camera: Camera2D = get_tree().get_first_node_in_group("player").get_node("Camera2D")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer  # Make sure the Timer node exists and is named "Timer"
@onready var shoot_sound: AudioStreamPlayer = $ShootSound

func _ready():
	sprite.flip_h = direction.x < 0
	sprite.play("fly")
	shoot_sound.play()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.start()
	
	# Send Packet
	var player = get_tree().get_first_node_in_group("player")
	if not is_remote and player != null and player.is_local and Globals.is_online_mode and LIB_C != null:
		var packet: Dictionary = {
			"type": "fireball_spawn",
			"sender": LIB_C.playerName,
			"x": global_position.x,
			"y": global_position.y,
			"dir_x": direction.x,
			"dir_y": direction.y,
			"speed": speed,
			"lifetime": lifetime,
			"id": str(get_instance_id())  # unique ID for this fireball
		}
		LIB_C.send_json_packet(packet)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(35, global_position)
			camera.trigger_shake(10.0, 0.3)
		_send_destroy_sync()
		queue_free()

func _on_timer_timeout() -> void:
	_send_destroy_sync()
	queue_free()

func _send_destroy_sync() -> void:
	if _destroy_sent:
		return
	_destroy_sent = true
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.is_local and Globals.is_online_mode and LIB_C != null:
		var packet: Dictionary = {
			"type": "fireball_destroy",
			"sender": LIB_C.playerName,
			"id": str(get_instance_id())
		}
		LIB_C.send_json_packet(packet)
