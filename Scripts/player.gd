extends CharacterBody2D

# Signals
@warning_ignore("unused_signal")
signal health_changed(new_health: int, max_health: int)

# Lazy Load Variables
@onready var heart_ui = self;
@onready var sword: Node2D = $SwordHolder/Sword;
@onready var camera: Camera2D = $Camera2D;
@onready var timer_label: Label = $HUD/TimerLabel;
@onready var level_timer: Timer = $HUD/LevelTimer;
@onready var zoom_button: Button = $HUD/ZoomButton;
@onready var fire_point: Marker2D = $FirePoint;
@onready var sword_holder: Marker2D = $SwordHolder;
@onready var coin_counter_label: Label = $HUD/CoinCounter;
@onready var ability_cooldown_bar: ProgressBar = $HUD/AbilityCooldownBar;
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D;
@onready var name_label: Label = $name;

# Audio Players Lazy Load
@onready var jump_sound: AudioStreamPlayer = $JumpSound;
@onready var player_hurt: AudioStreamPlayer = $PlayerHurt;
@onready var double_jump_sound: AudioStreamPlayer = $DoubleJumpSound;

# Variables Exported to the Inspector
@export var speed: float = 650.0;
@export var gravity: float = 1500.0;
@export var max_health: int = 100;
@export var jump_velocity: float = -1150.0;
@export var sprint_speed: float = speed * 2.4;
@export var fireball_cooldown: float = 0.5;
@export var shoot_anim_duration: float = 0.2;
@export var lightning_ball_scene: PackedScene;
@export var lightning_ability_duration: float = 3.0;
@export var lightning_ability_cooldown: float = 10.0;

# Constants
const MAX_JUMPS: int = 2;
const NET_TICK_RATE: float = 0.05; # 20Hz network sync rate

# Network & State Variables
var is_local: bool = true;
var player_name: String = "";
var network_target_pos: Vector2 = Vector2.ZERO;
var network_anim: String = "idle";
var network_flip_h: bool = false;
var net_tick_timer: float = 0.0;
var remote_fireballs: Dictionary = {}
var _weapon_synced_for_remote: bool = false

# Variables when Node init
var fireball_scene: PackedScene;
var lightning_ball_instance: Area2D;
var cheat_command_scene: Node = null;

# Booleans
var lobby: bool = false;
var god_mode: bool = false;
var is_dead: bool = false;
var can_shoot: bool = true;
var dash_locked: bool = false;
var is_shooting: bool = false;
var is_sprinting: bool = false;
var facing_right: bool = true;
var is_sword_swinging: bool = false;
var was_on_floor: bool = false;
var cheat_command: bool = false;
var jump_anim_played: bool = false;
var can_use_lightning: bool = true;
var is_lightning_active: bool = false;
var bonus_heart_unlocked: bool = false;

# Decimals
var jump_count: int = 0;
var move_speed: float = speed;
var time_elapsed: float = 0.0;
var cooldown_remaining: float = 0.0;
var cooldown_active_phase: bool = false;
var cooldown_phase_timer: Timer;
var current_health: int = max_health;
var old_health: int = current_health;

# Scope Variables
var ball: Area2D;
var fireball: Node;
var offset: Vector2;
var zoom_label: String;
var knockback: Vector2;
var start_timer_: Timer;
var cleanup_timer: Timer;
var saved_item: ItemData;
var input_direction: float;
var input_direction_A: float;
var time_for_3_stars: float;
var time_for_2_stars: float;
var time_for_1_star: float;

# Engine Callbacks
func _ready() -> void:
	# Remote Player Initialization
	if not is_local:
		if name_label:
			name_label.text = player_name
			name_label.visible = true

		var collision_shapes: Array[Node] = find_children("*", "CollisionShape2D")
		for shape in collision_shapes:
			shape.set_deferred("disabled", true)
			
		network_target_pos = global_position
		
		if camera:
			camera.enabled = false
			camera = null
		if timer_label: timer_label.visible = false
		if zoom_button: zoom_button.visible = false
		if coin_counter_label: coin_counter_label.visible = false
		if ability_cooldown_bar: ability_cooldown_bar.visible = false
		if jump_sound: jump_sound.volume_db = -80
		if player_hurt: player_hurt.volume_db = -80
		if double_jump_sound: double_jump_sound.volume_db = -80
		
		# === SYSTEM FIX: Force remote player's sword hierarchy and sprites to be visible ===
		if is_instance_valid(sword_holder):
			sword_holder.visible = true
		if is_instance_valid(sword):
			sword.visible = true
			var pivot = sword.get_node_or_null("Pivot")
			if pivot:
				pivot.visible = true
				var sprite_node = pivot.get_node_or_null("Sprite")
				if sprite_node:
					sprite_node.visible = true
					sprite_node.modulate = Color.WHITE
					sprite_node.scale = Vector2.ONE
		
		# === FIX: Equip their designated weapon immediately on initialization ===
		if Globals.equipped_item_name != "":
			_on_weapon_equipped(Globals.equipped_item_name)

		# === FIX: Remote players subscribe to weapon_sync_received immediately on join ===
		if LIB_C != null:
			LIB_C.player_joined.connect(_on_remote_initialized, CONNECT_ONE_SHOT)
		return
		
	# Local Player Initialization
	if is_local:
		if name_label:
			name_label.visible = false;
			
		fireball_scene = SceneManager.scenes.get("fireball_scene");
		Globals.level_coins_updated.connect(_update_coin_ui);
		Globals.weapon_equipped.connect(_on_weapon_equipped);
		_update_coin_ui(Globals.level_coins);
		Globals.reset_level_coins();
		health_changed.emit(current_health, max_health);
		
		if zoom_button:
			zoom_button.pressed.connect(_on_zoom_button_pressed);
			zoom_button.text = "2.0x";
			
		# === SYSTEM FIX: Dynamic, Type-Safe Initialization (Resolves String assignment to ItemData error) ===
		if not Globals.equipped_item_name.is_empty():
			if Globals.has_method("get_item_data_by_name"):
				var found_item = Globals.get_item_data_by_name(Globals.equipped_item_name)
				if found_item is ItemData:
					saved_item = found_item
					_on_weapon_equipped(saved_item)
				elif found_item is String or found_item == null:
					# Pass the raw string directly to our dynamic untyped method
					_on_weapon_equipped(Globals.equipped_item_name)
			else:
				# Pass the fallback string directly to our dynamic untyped method
				_on_weapon_equipped(Globals.equipped_item_name)
				
		if LIB_C != null:
			if not LIB_C.fireball_spawn_received.is_connected(_on_fireball_spawn_received):
				LIB_C.fireball_spawn_received.connect(_on_fireball_spawn_received)
			if not LIB_C.fireball_destroy_received.is_connected(_on_fireball_destroy_received):
				LIB_C.fireball_destroy_received.connect(_on_fireball_destroy_received)
			if not LIB_C.player_died_received.is_connected(_on_player_died_received):
				LIB_C.player_died_received.connect(_on_player_died_received)
			if not LIB_C.player_respawned_received.is_connected(_on_player_respawned_received):
				LIB_C.player_respawned_received.connect(_on_player_respawned_received)
				
		if LIB_C != null and not LIB_C.weapon_sync_received.is_connected(_on_weapon_sync_received):
			LIB_C.weapon_sync_received.connect(_on_weapon_sync_received)
			
		# Remove hard-coded 1.5s timer. Replace with event-driven broadcast.
		if is_local and Globals.is_online_mode and LIB_C != null:
			if not LIB_C.player_joined.is_connected(_broadcast_initial_weapon_to_peer):
				LIB_C.player_joined.connect(_broadcast_initial_weapon_to_peer)
				
				

# === NEW: Event-driven remote initialization ===
func _on_remote_initialized(player_name: String) -> void:
	if is_local:
		return
	if LIB_C != null and not LIB_C.weapon_sync_received.is_connected(_on_weapon_sync_received):
		LIB_C.weapon_sync_received.connect(_on_weapon_sync_received)

# === NEW: Event-driven broadcast for initial weapon state ===
func _broadcast_initial_weapon_to_peer(player_name: String) -> void:
	# Only the local host should broadcast. Ignore own joins.
	if not is_local or not Globals.is_online_mode or LIB_C == null:
		return
	if player_name == LIB_C.playerName:
		return
	if Globals.equipped_item_name.is_empty():
		return
		
	# Prevent duplicate broadcasts
	if _weapon_synced_for_remote:
		return
		
	_weapon_synced_for_remote = true
	
	var packet: Dictionary = Dictionary()
	packet["type"] = "weapon_sync"
	packet["sender"] = LIB_C.playerName
	packet["weapon_name"] = Globals.equipped_item_name.strip_edges()
	LIB_C.send_json_packet(packet)

func is_typing_in_input() -> bool:
	var focus_owner = get_viewport().gui_get_focus_owner();
	if focus_owner != null:
		if focus_owner is LineEdit or focus_owner is TextEdit:
			return true;
	return false;

func _input(event) -> void:
	if not is_local:
		return;
	if is_dead:
		return;
		
	if event.is_action_pressed("cheat_command") or (event is InputEventKey and event.pressed and (event.keycode == KEY_QUOTELEFT or event.keycode == KEY_ASCIITILDE)):
		cheat_command = !cheat_command;
		get_viewport().set_input_as_handled();
		return;
		
	if is_typing_in_input() and !event.is_action_pressed("Enter"):
		return;
		
	if !cheat_command and event.is_action_pressed("fireball"):
		shoot_fireball();
	if !cheat_command and event.is_action_pressed("lightning_ability"):
		activate_lightning_ball();
	if !cheat_command and !lobby and event.is_action_pressed("sword_attack"):
		if sword and sword.has_method("swing"):
			sword.swing(facing_right);
	if !cheat_command and event.is_action_pressed("god_mode_toggle"):
		god_mode = !god_mode;
		velocity = Vector2.ZERO;
		
	if cheat_command and cheat_command_scene != null and event.is_action_pressed("Enter"):
		cheat_command_scene.run_command();
		
	if !cheat_command and Input.is_action_pressed("ui_shift"):
		is_sprinting = true;
		move_speed = sprint_speed;
	if !cheat_command and Input.is_action_just_released("ui_shift"):
		is_sprinting = false;
		move_speed = speed;

func _physics_process(delta) -> void:
	# Remote Player Interpolation
	if not is_local:
		global_position = global_position.lerp(network_target_pos, 10.0 * delta);
		if sprite and sprite.animation != network_anim:
			sprite.play(network_anim);
		if sprite:
			sprite.flip_h = network_flip_h;
		return;

	# Local Player Physics
	if god_mode:
		handle_movement_input();
		move_and_slide();
		if sprite:
			if velocity.length() > 0:
				sprite.play("walk");
			else:
				sprite.play("idle");
	else:
		apply_gravity(delta);
		handle_movement_input();
		move_and_slide();
		handle_landing_reset();
		handle_animation();
		update_lightning_ball_position();
		
		if cooldown_remaining > 0:
			cooldown_remaining -= delta;
			if cooldown_active_phase:
				ability_cooldown_bar.value = lightning_ability_duration - cooldown_remaining;
			else:
				ability_cooldown_bar.value = cooldown_remaining;
				
		if cooldown_remaining <= 0 and cooldown_active_phase:
			cooldown_active_phase = false;
			cooldown_remaining = lightning_ability_cooldown;
			ability_cooldown_bar.max_value = lightning_ability_cooldown;
			
		if cooldown_remaining <= 0 and not cooldown_active_phase:
			cooldown_remaining = 0;
			ability_cooldown_bar.value = cooldown_remaining;
			
	# Network Sync Tick (Runs for local player regardless of god_mode)
	net_tick_timer += delta;
	if net_tick_timer >= NET_TICK_RATE:
		net_tick_timer = 0.0;
		_send_network_state();

func _process(_delta: float) -> void:
	if not is_local:
		return;
		
	if current_health != old_health:
		health_changed.emit(current_health, max_health);
		
	if not level_timer.is_stopped():
		time_elapsed += _delta;
		timer_label.text = str(snapped(time_elapsed, 0.1)) + "s";
		
	if cheat_command and cheat_command_scene == null:
		cheat_command_scene = SceneManager.get_scene("cheat_command").instantiate();
		add_child(cheat_command_scene);
		cheat_command_scene.name = "cheat_command"
		var command_line = cheat_command_scene.get_node_or_null("VBox/command_Box/command");
		if command_line and command_line is LineEdit:
			command_line.grab_focus();
	elif cheat_command and cheat_command_scene != null:
		cheat_command_scene.visible = true;
		var command_line = cheat_command_scene.get_node_or_null("VBox/command_Box/command");
		if command_line and command_line is LineEdit and get_viewport().gui_get_focus_owner() != command_line:
			command_line.grab_focus();
	else:
		if !cheat_command and cheat_command_scene != null:
			cheat_command_scene.visible = false;
			var command_line = cheat_command_scene.get_node_or_null("VBox/command_Box/command");
			if command_line and command_line is LineEdit and get_viewport().gui_get_focus_owner() == command_line:
				command_line.release_focus();

# Movement & Physics Helpers
func handle_movement_input() -> void:
	if is_typing_in_input():
		input_direction_A = 0.0;
		input_direction = 0.0;
		velocity.x = 0.0;
		is_sprinting = false;
		move_speed = speed;
		return;
		
	input_direction_A = Input.get_axis("move_left", "move_right");
	if input_direction_A != 0:
		facing_right = input_direction_A > 0;
		sprite.flip_h = !facing_right;
		if facing_right:
			sword_holder.position = Vector2(20, -5);
		else:
			sword_holder.position = Vector2(-20, -5);
			
	if is_sword_swinging and not god_mode:
		velocity.x = 0;
		return;
		
	if !cheat_command and god_mode:
		velocity = Vector2.ZERO;
		if Input.is_action_pressed("move_right"): velocity.x += move_speed;
		if Input.is_action_pressed("move_left"): velocity.x -= move_speed;
		if Input.is_action_pressed("move_up"): velocity.y -= move_speed;
		if Input.is_action_pressed("move_down"): velocity.y += move_speed;
	else:
		input_direction = 0.0;
		if !cheat_command and Input.is_action_pressed("move_left"): input_direction -= 1;
		if !cheat_command and Input.is_action_pressed("move_right"): input_direction += 1;
		velocity.x = input_direction * move_speed;
		
		if !cheat_command and Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
			velocity.y = jump_velocity;
			jump_count += 1;
			jump_anim_played = false;
			if jump_count == 1:
				jump_sound.play();
			else:
				double_jump_sound.play();

func apply_gravity(delta) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta;

func handle_landing_reset() -> void:
	if is_on_floor() and not was_on_floor:
		jump_count = 0;
		jump_anim_played = false;
	was_on_floor = is_on_floor();

# Combat & Abilities
func shoot_fireball() -> void:
	if not can_shoot or fireball_scene == null or is_shooting:
		return;
		
	fireball = fireball_scene.instantiate();
	fireball.direction = Vector2.RIGHT if facing_right else Vector2.LEFT;
	fireball.global_position = fire_point.global_position;
	get_tree().current_scene.add_child(fireball);
	
	dash_locked = true;
	sprite.play("dash");
	sprite.frame = 0;
	
	if sprite.animation_finished.is_connected(_on_dash_anim_finished):
		sprite.animation_finished.disconnect(_on_dash_anim_finished);
	sprite.animation_finished.connect(_on_dash_anim_finished, CONNECT_ONE_SHOT);
	
	is_shooting = true;
	can_shoot = false;
	
	if camera:
		camera.trigger_shake(5.0, 0.15);
		
	start_timer(shoot_anim_duration, _on_shoot_anim_end);
	start_timer(fireball_cooldown, _on_fireball_cooldown_timeout);

func activate_lightning_ball() -> void:
	if not can_use_lightning or lightning_ball_scene == null:
		return;
		
	can_use_lightning = false;
	is_lightning_active = true;
	cooldown_active_phase = true;
	cooldown_remaining = lightning_ability_duration;
	ability_cooldown_bar.max_value = lightning_ability_duration;
	ability_cooldown_bar.value = 0;
	
	ball = lightning_ball_scene.instantiate() as Area2D;
	ball.scale = Vector2(1.5, 1.5);
	ball.global_position = global_position + Vector2(50 if facing_right else -50, 0);
	
	if ball.has_method("set_direction"):
		ball.set_direction(Vector2(1, 0) if facing_right else Vector2(-1, 0));
	if ball.has_method("activate"):
		ball.activate();
		
	get_tree().current_scene.add_child(ball);
	
	cleanup_timer = Timer.new();
	cleanup_timer.wait_time = lightning_ability_duration;
	cleanup_timer.one_shot = true;
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(ball):
			if ball.has_method("deactivate"):
				ball.deactivate();
			ball.queue_free();
		is_lightning_active = false;
	);
	add_child(cleanup_timer);
	cleanup_timer.start();
	
	start_timer(lightning_ability_cooldown, _on_lightning_cooldown_timeout);
	start_timer(lightning_ability_duration, _on_lightning_ability_end);

func update_lightning_ball_position() -> void:
	if is_instance_valid(lightning_ball_instance) and lightning_ball_instance.visible:
		offset = Vector2(50, 0) if facing_right else Vector2(-50, 0);
		lightning_ball_instance.global_position = global_position + offset;
		lightning_ball_instance.scale.x = abs(lightning_ball_instance.scale.x) if facing_right else -abs(lightning_ball_instance.scale.x);
		if lightning_ball_instance.has_method("set_direction"):
			lightning_ball_instance.set_direction(Vector2(1, 0) if facing_right else Vector2(-1, 0));

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if god_mode: return;
	if camera: camera.trigger_shake(12.0, 0.3);
	player_hurt.play();
	current_health -= amount;
	knockback = (global_position - source_position).normalized() * 500.0;
	velocity = knockback;
	if current_health <= 0:
		die();

func heal(amount: int) -> void:
	current_health += amount;
	current_health = clamp(current_health, 0, max_health);
	health_changed.emit(current_health, max_health);

func add_bonus_heart() -> bool:
	if bonus_heart_unlocked: return false;
	bonus_heart_unlocked = true;
	max_health += 25;
	current_health += 25;
	health_changed.emit(current_health, max_health);
	return true;

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	if LIB_C != null:
		var packet: Dictionary = Dictionary()
		packet["type"] = "player_died"
		packet["sender"] = LIB_C.playerName
		LIB_C.send_json_packet(packet)
		
	if not is_local:
		if sprite:
			sprite.visible = false
		if sword_holder:
			sword_holder.visible = false
		return
		
	if camera: 
		camera.trigger_shake(20.0, 0.8)
	MusicManager.play_game_over()
	set_process(false)
	set_process_input(false)
	set_physics_process(false)
	
	if sprite:
		sprite.visible = false
	if sword_holder:
		sword_holder.visible = false
		
	await get_tree().create_timer(0.5).timeout
	show_retry_overlay()

func show_retry_overlay() -> void:
	var retry_scene: PackedScene = SceneManager.get_scene("retry_menu")
	if retry_scene:
		var canvas_layer: CanvasLayer = CanvasLayer.new()
		canvas_layer.layer = 100
		var overlay: Control = retry_scene.instantiate()
		overlay.set_meta("target_player", self)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		canvas_layer.add_child(overlay)
		get_tree().root.add_child(canvas_layer)

func respawn() -> void:
	is_dead = false
	current_health = max_health
	old_health = current_health
	health_changed.emit(current_health, max_health)
	
	global_position = Vector2(100, 100) 
	velocity = Vector2.ZERO
	
	if sprite:
		sprite.visible = true
	if sword_holder:
		sword_holder.visible = true
		
	set_process(true)
	set_process_input(true)
	set_physics_process(true)
	
	if LIB_C != null:
		var packet: Dictionary = Dictionary()
		packet["type"] = "player_respawned"
		packet["sender"] = LIB_C.playerName
		LIB_C.send_json_packet(packet)

func _on_player_died_received(sender: String) -> void:
	if not is_local and sender == player_name:
		if sprite: sprite.visible = false
		set_process(false)

func _on_player_respawned_received(sender: String) -> void:
	if not is_local and sender == player_name:
		if sprite: sprite.visible = true
		set_process(true)

# Utilities and Helpers
func handle_animation() -> void:
	if is_shooting: return;
	if god_mode and velocity.length() > 0:
		sprite.play("idle");
	elif not is_on_floor():
		if not jump_anim_played:
			sprite.play("jump", false);
			jump_anim_played = true;
	elif abs(velocity.x) > 0:
		sprite.play("run" if is_sprinting else "walk");
	else:
		sprite.play("idle");

func start_timer(duration: float, callback: Callable):
	start_timer_ = Timer.new();
	start_timer_.wait_time = duration;
	start_timer_.one_shot = true;
	start_timer_.timeout.connect(callback);
	add_child(start_timer_);
	start_timer_.start();

func stop_level_timer() -> void:
	level_timer.stop();

func get_current_time() -> float:
	return time_elapsed;

func get_stars_earned() -> int:
	time_for_3_stars = 90.0;
	time_for_2_stars = 105.0;
	time_for_1_star  = 120.0;
	if time_elapsed <= time_for_3_stars: return 3;
	elif time_elapsed <= time_for_2_stars: return 2;
	elif time_elapsed <= time_for_1_star: return 1;
	else: return 0;

func reset_level_timer() -> void:
	time_elapsed = 0.0;
	timer_label.text = "0.0s";
	level_timer.start();

func _send_network_state() -> void:
	if LIB_C == null: return
	if not LIB_C.is_host and not LIB_C.client_connected: return
	
	var anim_name: String = "idle"
	if sprite: 
		anim_name = sprite.animation
		
	var packet: Dictionary = Dictionary()
	packet["type"] = "pos"
	packet["sender"] = LIB_C.playerName
	packet["x"] = global_position.x
	packet["y"] = global_position.y
	packet["anim"] = anim_name
	packet["flip"] = sprite.flip_h if sprite else false
	LIB_C.send_json_packet(packet)

func _on_weapon_equipped(item_data) -> void:
	sword.equip_weapon(item_data)
	if not sword.swing_started.is_connected(_on_sword_swing_started):
		sword.swing_started.connect(_on_sword_swing_started)
	if not sword.swing_finished.is_connected(_on_sword_swing_finished):
		sword.swing_finished.connect(_on_sword_swing_finished)
		
	if is_local and Globals.is_online_mode and LIB_C != null:
		# Prevent duplicate broadcasts when a remote player joins
		if not _weapon_synced_for_remote:
			var packet: Dictionary = Dictionary()
			packet["type"] = "weapon_sync"
			packet["sender"] = LIB_C.playerName
			packet["weapon_name"] = item_data.item_name.strip_edges()
			LIB_C.send_json_packet(packet)

# Signal Handlers
func _update_coin_ui(new_total: int) -> void:
	if coin_counter_label: coin_counter_label.text = str(new_total);

func _on_zoom_button_pressed() -> void:
	if camera:
		zoom_label = camera.toggle_zoom();
		zoom_button.text = zoom_label;

func _on_dash_anim_finished() -> void:
	dash_locked = false;
	if abs(velocity.x) > 10.0: sprite.play("walk");
	else: sprite.play("idle");

func _on_lightning_ability_end() -> void:
	is_lightning_active = false
	
	# Single safety check for everything
	if is_instance_valid(lightning_ball_instance):
		lightning_ball_instance.visible = false
		
		if lightning_ball_instance.has_method("deactivate"):
			lightning_ball_instance.deactivate()

func _on_weapon_sync_received(sender: String, weapon_name: String) -> void:
	if sender == LIB_C.playerName:
		return  # Ignore weapon sync packets sent by ourselves

	print("[Network] Synced weapon '", weapon_name, "' received from peer: ", sender)
	
	if is_instance_valid(sword):
		# Pass the weapon name directly. sword.equip_weapon handles strings and normalized spacing!
		sword.equip_weapon(weapon_name)
	else:
		push_warning("[Player Network] Cannot sync weapon; sword instance is invalid.")

func _on_fireball_spawn_received(sender: String, x: float, y: float, dir_x: float, dir_y: float, fb_speed: float, lifetime: float, fireball_id: String) -> void:
	if sender == LIB_C.playerName:
		return  # ignore our own spawns
	var fb_instance = fireball_scene.instantiate()
	fb_instance.global_position = Vector2(x, y)
	fb_instance.direction = Vector2(dir_x, dir_y)
	fb_instance.speed = fb_speed
	fb_instance.lifetime = lifetime
	fb_instance.is_remote = true
	get_tree().current_scene.add_child(fb_instance)
	remote_fireballs[fireball_id] = fb_instance

func _on_fireball_destroy_received(sender: String, fireball_id: String) -> void:
	if sender == LIB_C.playerName:
		return
	if remote_fireballs.has(fireball_id):
		var fb_fireball = remote_fireballs[fireball_id]
		if is_instance_valid(fb_fireball):
			fb_fireball.queue_free()
		remote_fireballs.erase(fireball_id)

func _on_lightning_cooldown_timeout() -> void:
	can_use_lightning = true;

func _on_shoot_anim_end() -> void:
	is_shooting = false;
	if abs(velocity.x) > 10.0: sprite.play("walk");
	else: sprite.play("idle");

func _on_fireball_cooldown_timeout() -> void:
	can_shoot = true;

func _on_sword_swing_started() -> void:
	is_sword_swinging = true;

func _on_sword_swing_finished() -> void:
	is_sword_swinging = false;
