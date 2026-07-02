extends Node2D

@export var damage: int = 1
@export var swing_duration: float = 0.18
@export var swing_angle: float = 120.0
@export var base_angle: float = -45.0

@onready var pivot: Node2D = $Pivot
@onready var hitbox: Area2D = $Pivot/Hitbox
@onready var swing_sound: AudioStreamPlayer = $SwingSound
@onready var sprite: Sprite2D = $Pivot/Sprite


const WEAPON_TEXTURES := {
	"Wood Sword": preload("res://Assets/Weapons/Wooden sword-1.png.png"),
	"Stone Sword": preload("res://Assets/Weapons/Stone sword-1.png.png"),
	"Iron Sword": preload("res://Assets/Weapons/Iron Sword-1.png.png"),
	"Gold Sword": preload("res://Assets/Weapons/Gold Sword-1.png.png"),
	"Diamond Sword": preload("res://Assets/Weapons/Diamond Sword-1.png (1).png"),
	"Netherite Sword": preload("res://Assets/Weapons/Netherite Sword-1.png.png")
}

var is_swinging := false
var enemy_hit := false
var facing_right := true


func _ready():

	pivot.rotation_degrees = base_angle

	hitbox.monitoring = false
	hitbox.monitorable = false

	hitbox.body_entered.connect(_on_hitbox_body_entered)

func equip_weapon(weapon_name: String):

	if WEAPON_TEXTURES.has(weapon_name):
		sprite.texture = WEAPON_TEXTURES[weapon_name]
		print("Equipped:", weapon_name)
	else:
		push_warning("Weapon not found: " + weapon_name)

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


func _on_hitbox_body_entered(body: Node2D):

	if enemy_hit:
		return

	if body.is_in_group("enemies") and body.has_method("take_damage"):
		enemy_hit = true
		body.take_damage(damage, global_position)
