extends Node2D

# Declarations
@onready var axis: Node2D = $Axis;
@onready var hitbox: Area2D = $Axis/Texture/HitBox;
@onready var swing_sound: AudioStreamPlayer = $HammerSound

# Settings exported to the editor
@export var damage: int = 2;
@export var swing_duration: float = 0.20;
@export var swing_angle: float = 120.0;
@export var base_angle: float = -45.0;

# Flags
var is_swinging: bool = false;
var enemy_hit: bool = false;
var facing_right: bool = true;

# Ready Function
func _ready():

	axis.rotation_degrees = base_angle;

	hitbox.monitoring = false;
	hitbox.monitorable = false;

# Handle swing
func swing(is_facing_right: bool):

	if is_swinging:
		return;

	is_swinging = true;
	enemy_hit = false;
	facing_right = is_facing_right;

	hitbox.monitoring = true;
	hitbox.monitorable = true;

	if swing_sound:
		swing_sound.play();

	var start_angle: float;
	var end_angle: float;

	if facing_right:
		start_angle = base_angle - swing_angle / 2.0;
		end_angle = base_angle + swing_angle / 2.0;
	else:
		start_angle = 180.0 - base_angle + swing_angle / 2.0;
		end_angle = 180.0 - base_angle - swing_angle / 2.0;

	axis.rotation_degrees = start_angle;

	var tween := create_tween();
	tween.set_trans(Tween.TRANS_QUAD);
	tween.set_ease(Tween.EASE_OUT);

	tween.tween_property(
		axis,
		"rotation_degrees",
		end_angle,
		swing_duration
	);

	await tween.finished;

	if facing_right:
		axis.rotation_degrees = base_angle;
	else:
		axis.rotation_degrees = 180.0 - base_angle;

	hitbox.monitoring = false;
	hitbox.monitorable = false;

	is_swinging = false;


func _on_hit_box_body_entered(body: Node2D) -> void:
	if enemy_hit:
		return;

	if body.is_in_group("enemies") and body.has_method("take_damage"):
		enemy_hit = true;
		body.take_damage(damage, global_position);
