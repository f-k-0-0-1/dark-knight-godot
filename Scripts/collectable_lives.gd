extends Area2D

@export var heal_amount := 25
@export var float_height := 4.0
@export var float_speed := 2.0
@export var pulse_amount := 0.04
@export var pulse_speed := 2.0

@onready var pickup_sound: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite: Sprite2D = $Sprite2D

var start_position: Vector2
var time := 0.0
var sync_id: String = ""
var is_syncing: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	start_position = position
	sync_id = str(get_path())
	
	if LIB_C != null:
		if not LIB_C.pickup_sync_received.is_connected(_on_pickup_sync_received):
			LIB_C.pickup_sync_received.connect(_on_pickup_sync_received)

func _process(delta: float) -> void:
	time += delta
	position.y = start_position.y + sin(time * float_speed) * float_height
	var scale_factor: float = 1.0 + sin(time * pulse_speed) * pulse_amount
	sprite.scale = Vector2.ONE * scale_factor

func _on_body_entered(body: Node2D) -> void:
	if is_syncing:
		return
		
	if not body.is_in_group("player") or not body.is_local:
		return
		
	is_syncing = true
	
	if body.current_health < body.max_health:
		body.heal(heal_amount)
	elif body.add_bonus_heart():
		var floating_text = SceneManager.scenes["floating_text"].instantiate()
		floating_text.text = "Bonus Life"
		floating_text.global_position = global_position
		get_tree().current_scene.add_child(floating_text)
		
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	if pickup_sound:
		pickup_sound.play()
		
	sprite.hide()
	
	if LIB_C != null:
		var packet: Dictionary = Dictionary()
		packet["type"] = "pickup_sync"
		packet["sender"] = LIB_C.playerName
		packet["id"] = sync_id
		LIB_C.send_json_packet(packet)
		
	if pickup_sound:
		await pickup_sound.finished
	else:
		await get_tree().create_timer(0.5).timeout
		
	queue_free()

func _on_pickup_sync_received(item_id: String) -> void:
	if item_id == sync_id and not is_syncing:
		is_syncing = true
		set_deferred("monitoring", false)
		$CollisionShape2D.set_deferred("disabled", true)
		sprite.hide()
		await get_tree().create_timer(0.1).timeout
		queue_free()
