extends Node2D

# =====================================================
# SETTINGS
# =====================================================

@export var damage: int = 1
@export var swing_duration: float = 0.18
@export var swing_angle: float = 120.0
@export var base_angle: float = -45.0

# =====================================================
# NODES
# =====================================================

@onready var pivot: Node2D = $Pivot
@onready var hitbox: Area2D = $Pivot/Hitbox
@onready var swing_sound: AudioStreamPlayer = $SwingSound

# =====================================================
# STATE
# =====================================================

var is_swinging := false
var enemy_hit := false
var facing_right := true

# =====================================================
# READY
# =====================================================

func _ready():

	pivot.rotation_degrees = base_angle

	hitbox.monitoring = false
	hitbox.monitorable = false

	hitbox.body_entered.connect(_on_hitbox_body_entered)

# =====================================================
# SWING
# =====================================================

func swing(is_facing_right: bool):

	if is_swinging:
		return

	is_swinging = true
	enemy_hit = false
	facing_right = is_facing_right

	hitbox.monitoring = true
	hitbox.monitorable = true

	if swing_sound:
		swing_sound.play()

	var start_angle: float
	var end_angle: float

	if facing_right:
		start_angle = base_angle - swing_angle / 2.0
		end_angle = base_angle + swing_angle / 2.0
	else:
		start_angle = 180.0 - base_angle + swing_angle / 2.0
		end_angle = 180.0 - base_angle - swing_angle / 2.0

	pivot.rotation_degrees = start_angle

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		pivot,
		"rotation_degrees",
		end_angle,
		swing_duration
	)

	await tween.finished

	if facing_right:
		pivot.rotation_degrees = base_angle
	else:
		pivot.rotation_degrees = 180.0 - base_angle

	hitbox.monitoring = false
	hitbox.monitorable = false

	is_swinging = false

# =====================================================
# HITBOX
# =====================================================

func _on_hitbox_body_entered(body: Node2D):

	if enemy_hit:
		return

	if body.is_in_group("enemies") and body.has_method("take_damage"):
		enemy_hit = true
		body.take_damage(damage, global_position)
