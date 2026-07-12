extends Area2D

# === CONFIG ===
@export var damage_per_tick: int = 150
@export var tick_rate: float = 0.5
@export var max_lifetime: float = 5.0
@export var follow_distance: float = 80.0
@export var full_scale: Vector2 = Vector2(1, 1)
@export var grow_duration: float = 0.3

# === NODES ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var shoot_sound: AudioStreamPlayer = $ShootSound

# === INTERNAL STATE ===
var player_ref: Node2D = null
var total_damage_dealt: float = 0.0
var is_attacking_this_tick := false
var lifetime_timer: Timer
var attack_timer: Timer

func _ready():
	# Find the player immediately
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref:
		queue_free()
		return
	
	# 1. Play the initial charge effect
	sprite.play("charge_2")
	shoot_sound.play()
	
	# 2. Grow from 0 to full scale
	shape.scale = Vector2.ZERO
	var tween := get_tree().create_tween()
	tween.tween_property(shape, "scale", full_scale, grow_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. Connect damage signal
	body_entered.connect(_on_body_entered)
	
	# === THE FIX: Remove the animation auto-death ===
	# We remove this line so the animation doesn't kill the ball early:
	# sprite.animation_finished.connect(queue_free)
	
	# 4. Set up the Lifetime Timer (5 seconds)
	lifetime_timer = Timer.new()
	lifetime_timer.wait_time = max_lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	lifetime_timer.start()
	
	# 5. Set up the Attack Tick Timer (0.5 seconds)
	attack_timer = Timer.new()
	attack_timer.wait_time = tick_rate
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_on_attack_tick)
	add_child(attack_timer)
	attack_timer.start()

func _process(_delta: float) -> void:
	if not is_instance_valid(player_ref):
		queue_free()
		return
	
	# Stay BEHIND the player (Opposite of the player's facing direction)
	var offset = Vector2(-follow_distance, -20) if player_ref.facing_right else Vector2(follow_distance, -20)
	global_position = player_ref.global_position + offset

# === ON ATTACK TICK ===
func _on_attack_tick():
	is_attacking_this_tick = false

# === ON LIFETIME END ===
func _on_lifetime_timeout():
	queue_free()

# === DAMAGE LOGIC ===
func _on_body_entered(body: Node):
	if is_attacking_this_tick:
		return
		
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		if total_damage_dealt >= 500.0:
			return
			
		var damage_to_deal = min(damage_per_tick, 500.0 - total_damage_dealt)
		body.take_damage(damage_to_deal, global_position)
		total_damage_dealt += damage_to_deal
		is_attacking_this_tick = true
		
		var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
		if camera and camera.has_method("trigger_shake"):
			camera.trigger_shake(5.0, 0.15)
