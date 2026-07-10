extends Node2D

# === EXPORT ===
@export var swing_duration: float = 0.18
@export var swing_angle: float = 120.0
@export var base_angle: float = -45.0

# === NODES ===
@onready var pivot: Node2D = $Pivot
@onready var hitbox: Area2D = $Pivot/Hitbox
@onready var swing_sound: AudioStreamPlayer = $SwingSound
@onready var sprite: Sprite2D = $Pivot/Sprite

# === STATE ===
var is_swinging := false
var enemy_hit := false
var facing_right := true
var current_damage := 1
var current_material := "Wood"
var current_category := "Sword"

func _ready():
	pivot.rotation_degrees = base_angle
	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func equip_weapon(item_data: ItemData):
	# 1. Store the data
	current_damage = item_data.damage
	
	# 2. Compute material from the item name and category from the item data.
	var raw_parts = item_data.item_name.split(" ")
	var name_parts: Array = []
	for part in raw_parts:
		if part != "":
			name_parts.append(part)

	if name_parts.size() < 1:
		push_error("Sword: Item name format invalid: " + item_data.item_name)
		return

	current_material = name_parts[0]
	current_category = item_data.category.to_lower().capitalize()

	# 3. Request texture from the WeaponManager
	var weapon_key = current_material + "_" + current_category
	print("Sword: equipping key=", weapon_key)
	var new_texture = WeaponManager.get_weapon_texture(current_material, current_category)
	if new_texture:
		sprite.texture = new_texture
		print("Equipped: ", item_data.item_name, " | Damage: ", current_damage)
	else:
		push_warning("Failed to equip: " + item_data.item_name)

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
	tween.tween_property(pivot, "rotation_degrees", end_angle, swing_duration)

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
		body.take_damage(current_damage, global_position)
