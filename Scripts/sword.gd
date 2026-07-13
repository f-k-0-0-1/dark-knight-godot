extends Node2D

# === EXPORT ===
@export var swing_duration: float = 0.18
@export var swing_angle: float = 120.0
@export var base_angle: float = -45.0

# Signal to lock/unlock player movement during swing
signal swing_started
signal swing_finished

# === CONSTANTS ===
# FIX FOR ERROR 1: This must be declared at the top!
const SLASH_SCENE = preload("res://Scenes/Slash.tscn");

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

# === COMBO SYSTEM ===
# FIX FOR ERROR 2 & 3: Add these variables!
var combo_count := 0
var combo_reset_timer: Timer

func _ready():
	pivot.rotation_degrees = base_angle
	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Setup combo reset timer
	combo_reset_timer = Timer.new()
	combo_reset_timer.wait_time = 0.8 # Reset combo if you don't swing again in 0.8s
	combo_reset_timer.one_shot = true
	combo_reset_timer.timeout.connect(_reset_combo)
	add_child(combo_reset_timer)
	
	# Connect to swing sync signal
	if LIB_C != null and not LIB_C.swing_sync_received.is_connected(_on_swing_sync_received):
		LIB_C.swing_sync_received.connect(_on_swing_sync_received)

func _reset_combo():
	combo_count = 0

func equip_weapon(item_data: ItemData):
	current_damage = item_data.damage
	var clean_name = item_data.item_name.strip_edges()
	var name_parts = clean_name.split(" ")
	if name_parts.size() >= 2:
		current_material = name_parts[0].strip_edges()
		current_category = name_parts[-1].strip_edges()
	else:
		push_error("Sword: Item name format invalid: " + item_data.item_name)
		return
		
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
	
	# Identify owner by traversing scene tree: Sword -> SwordHolder -> Player
	var player = get_parent().get_parent()
	if player != null and player is CharacterBody2D and player.is_local and Globals.is_online_mode and LIB_C != null:
		var packet: Dictionary = Dictionary()
		packet["type"] = "swing_sync"
		packet["sender"] = LIB_C.playerName
		packet["facing_right"] = is_facing_right
		packet["combo"] = combo_count
		LIB_C.send_json_packet(packet)
		
	hitbox.monitoring = true
	hitbox.monitorable = true
	
	if swing_sound:
		swing_sound.play()
		
	# Lock player movement during swing
	swing_started.emit()
	
	# === SPAWN SLASH EFFECT ===
	var slash_instance = SLASH_SCENE.instantiate()
	# Position it slightly in front of the player
	var slash_offset = Vector2(40, 0) if facing_right else Vector2(-40, 0)
	slash_instance.global_position = global_position + slash_offset
	
	# ROTATE THE SLASH BASED ON FACING DIRECTION
	if not facing_right:
		slash_instance.scale.x = -1.0 # Flip the slash if facing left
		
	# Add it to the world FIRST so @onready variables initialize
	get_tree().current_scene.add_child(slash_instance)
	# Pass the current combo count to decide which slash to play
	slash_instance.init(combo_count)
	
	# === DETERMINE SWING DURATION BASED ON COMBO (before incrementing) ===
	var swing_duration_actual: float
	if combo_count == 2:  # Multi slash
		swing_duration_actual = 0.30
	else:  # Single slash (combo 0 or 1)
		swing_duration_actual = 0.12
		
	# === INCREMENT COMBO ===
	combo_count += 1
	if combo_count > 2:
		combo_count = 0 # Loop back to Slash 1 after Spin/Multi Slash
	combo_reset_timer.start() # Reset the timer
	
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
	tween.tween_property(pivot, "rotation_degrees", end_angle, swing_duration_actual)
	await tween.finished
	
	if facing_right:
		pivot.rotation_degrees = base_angle
	else:
		pivot.rotation_degrees = 180.0 - base_angle
		
	hitbox.monitoring = false
	hitbox.monitorable = false
	is_swinging = false
	
	# Unlock player movement after swing
	swing_finished.emit()

func _on_hitbox_body_entered(body: Node2D):
	if enemy_hit:
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		enemy_hit = true
		body.take_damage(current_damage, global_position)

func _on_swing_sync_received(sender: String, f_right: bool, combo: int) -> void:
	# Identify owner by traversing scene tree: Sword -> SwordHolder -> Player
	var player = get_parent().get_parent()
	if player == null or not player is CharacterBody2D:
		return
	if player.is_local:
		return  # ignore local player's own swings
	if sender != player.player_name:
		return  # ignore swings from other remote players
		
	# Call swing_remote
	swing_remote(f_right, combo)

func swing_remote(is_facing_right: bool, combo: int) -> void:
	# Similar to swing but without hitbox/damage and without sending packet again
	if is_swinging:
		return
	is_swinging = true
	facing_right = is_facing_right
	
	# Spawn slash effect (visual)
	var slash_instance = SLASH_SCENE.instantiate()
	var slash_offset = Vector2(40, 0) if facing_right else Vector2(-40, 0)
	slash_instance.global_position = global_position + slash_offset
	if not facing_right:
		slash_instance.scale.x = -1.0
	get_tree().current_scene.add_child(slash_instance)
	slash_instance.init(combo)  # pass combo for correct slash animation
	
	# Determine swing duration based on combo
	var swing_duration_actual = 0.30 if combo == 2 else 0.12
	
	# Animate pivot
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
	tween.tween_property(pivot, "rotation_degrees", end_angle, swing_duration_actual)
	await tween.finished
	
	if facing_right:
		pivot.rotation_degrees = base_angle
	else:
		pivot.rotation_degrees = 180.0 - base_angle
		
	is_swinging = false
