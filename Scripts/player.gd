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

# Variables when Node init
var fireball_scene: PackedScene;
var lightning_ball_instance: Area2D;
var cheat_command_scene: Node = null;

# Booleans
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

# Init Stuff Here
func _ready() -> void:
	# Init FireBall Scene
	fireball_scene = SceneManager.scenes.get("fireball_scene");
	
	# Init Signals connection
	Globals.level_coins_updated.connect(_update_coin_ui);
	Globals.weapon_equipped.connect(_on_weapon_equipped);
	
	# Init Coins
	_update_coin_ui(Globals.level_coins);
	Globals.reset_level_coins();
	
	# Set Default Health via Signal
	health_changed.emit(current_health, max_health);
	
	# Init Zoom Button
	if (zoom_button):
		zoom_button.pressed.connect(_on_zoom_button_pressed);
		zoom_button.text = "2.0x";
	
	# Init Equipped Item
	if (!Globals.equipped_item_name.is_empty()):
		saved_item = Globals.get_item_data_by_name(Globals.equipped_item_name);
		
		# Send Signal if weapon equipped
		if (saved_item != null):
			_on_weapon_equipped(saved_item);
		else:
			print("Player: saved equipped item not found: ", Globals.equipped_item_name);

# Handle Input Events Here
func _input(event) -> void:
	if (is_dead):
		return;
		
	if (event.is_action_pressed("cheat_command") or (event is InputEventKey and event.pressed and (event.keycode == KEY_QUOTELEFT or event.keycode == KEY_ASCIITILDE))):
		cheat_command = !cheat_command;
		get_viewport().set_input_as_handled();
		
	if (!cheat_command and event.is_action_pressed("fireball")):
		shoot_fireball();

	if (!cheat_command and event.is_action_pressed("lightning_ability")):
		activate_lightning_ball();
	
	if (!cheat_command and event.is_action_pressed("sword_attack")):
		if (sword and sword.has_method("swing")):
			sword.swing(facing_right);
			
	if (!cheat_command and event.is_action_pressed("god_mode_toggle")):
		god_mode = !god_mode;
		velocity = Vector2.ZERO;

	if (!cheat_command and event.is_action_pressed("fireball")):
		shoot_fireball();

	if (!cheat_command and event.is_action_pressed("lightning_ability")):
		activate_lightning_ball();

	if (cheat_command and cheat_command_scene != null and event.is_action_pressed("Enter")):
		cheat_command_scene.run_command();
		
	if (!cheat_command and Input.is_action_pressed("ui_shift")):
		is_sprinting = true;
		move_speed = sprint_speed;
		
	if (!cheat_command and Input.is_action_just_released("ui_shift")):
		is_sprinting = false;
		move_speed = speed;

# Handle Physics Here
func _physics_process(delta) -> void:
	if (not god_mode): 
		apply_gravity(delta);
		
	handle_movement_input();
	move_and_slide();
	handle_landing_reset();
	handle_animation();
	update_lightning_ball_position();
	
	if (cooldown_remaining > 0):
		cooldown_remaining -= delta;
		ability_cooldown_bar.value = lightning_ability_cooldown - cooldown_remaining;

	if (cooldown_remaining <= 0):
		cooldown_remaining = 0;
		ability_cooldown_bar.value = lightning_ability_cooldown;

# Every Frame Logic Here
func _process(_delta: float) -> void:
	# Keep Track of the Player Health
	if (current_health != old_health):
		health_changed.emit(current_health, max_health);
	
	# Update the level timer text
	if (not level_timer.is_stopped()):
		time_elapsed += _delta;
		timer_label.text = str(snapped(time_elapsed, 0.1)) + "s";
	
	# Logic for cheat command 
	if (cheat_command and cheat_command_scene == null):
		cheat_command_scene = SceneManager.get_scene("cheat_command").instantiate();
		add_child(cheat_command_scene);
	
	elif (cheat_command and cheat_command_scene != null):
		cheat_command_scene.visible = true;
	
	else:
		if (!cheat_command and cheat_command_scene != null):
			cheat_command_scene.visible = false;

# Movement and Physics Logic

# Function Handles Player Movement
func handle_movement_input() -> void:
	input_direction_A = Input.get_axis("move_left", "move_right");

	if (input_direction_A != 0):
		facing_right = input_direction_A > 0;

	sprite.flip_h = !facing_right;

	if (facing_right):
		sword_holder.position = Vector2(20, -5);
	
	# Lock horizontal movement during sword swing
	if (is_sword_swinging):
		velocity.x = 0;
		return;

	if (!cheat_command and god_mode):
		velocity = Vector2.ZERO;
		if (Input.is_action_pressed("move_right")):
			velocity.x += move_speed;
		if (Input.is_action_pressed("move_left")):
			velocity.x -= move_speed;
		if (Input.is_action_pressed("move_up")):
			velocity.y -= move_speed;
		if (Input.is_action_pressed("move_down")):
			velocity.y += move_speed;
	else:
		sword_holder.position = Vector2(-20, -5);

	if (!cheat_command and god_mode):
		velocity = Vector2.ZERO;
		if (Input.is_action_pressed("move_right")):
			velocity.x += move_speed;
		if (Input.is_action_pressed("move_left")):
			velocity.x -= move_speed;
		if (Input.is_action_pressed("move_up")):
			velocity.y -= move_speed;
		if (Input.is_action_pressed("move_down")):
			velocity.y += move_speed;
	else:
		input_direction = 0.0;
		if (!cheat_command and Input.is_action_pressed("move_left")):
			input_direction -= 1;
		if (!cheat_command and Input.is_action_pressed("move_right")):
			input_direction += 1;

		velocity.x = input_direction * move_speed;

		# Jump and Jump Sound Logic
		if (!cheat_command and Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS):
			velocity.y = jump_velocity;
			jump_count += 1;
			jump_anim_played = false;
			if (jump_count == 1):
				jump_sound.play();
			else:
				double_jump_sound.play();

# Function to Apply Gravity to Player
func apply_gravity(delta) -> void:
	if (not is_on_floor()):
		velocity.y += gravity * delta;

# Function to Handle Player Landing from Jump
func handle_landing_reset() -> void:
	if (is_on_floor() and not was_on_floor):
		jump_count = 0;
		jump_anim_played = false;
	was_on_floor = is_on_floor();

# Ability Actions and Combat

# Function Handles Player Fireball Shooting
func shoot_fireball() -> void:
	if (not can_shoot or fireball_scene == null or is_shooting):
		return;
		
	fireball = fireball_scene.instantiate();
	fireball.direction = Vector2.RIGHT if facing_right else Vector2.LEFT;
	fireball.global_position = fire_point.global_position;
	get_tree().current_scene.add_child(fireball);

	dash_locked = true;
	sprite.play("dash");
	sprite.frame = 0;
	
	# Safely disconnect before connecting again 
	if (sprite.animation_finished.is_connected(_on_dash_anim_finished)):
		sprite.animation_finished.disconnect(_on_dash_anim_finished);
	sprite.animation_finished.connect(_on_dash_anim_finished, CONNECT_ONE_SHOT);
	
	is_shooting = true;
	can_shoot = false;
	
	@warning_ignore("shadowed_variable")
	if (camera):
		camera.trigger_shake(5.0, 0.15);

	start_timer(shoot_anim_duration, _on_shoot_anim_end);
	start_timer(fireball_cooldown, _on_fireball_cooldown_timeout);

# Function Handle Player Lightning Ball
func activate_lightning_ball() -> void:
	if (not can_use_lightning or lightning_ball_scene == null):
		return;

	can_use_lightning = false;
	is_lightning_active = true;
	
	cooldown_remaining = lightning_ability_cooldown;
	ability_cooldown_bar.max_value = lightning_ability_cooldown;
	ability_cooldown_bar.value = 0;
	
	ball = lightning_ball_scene.instantiate() as Area2D;
	ball.scale = Vector2(1.5, 1.5);
	ball.global_position = global_position + Vector2(50 if facing_right else -50, 0);
	
	if (ball.has_method("set_direction")):
		ball.set_direction(Vector2(1, 0) if facing_right else Vector2(-1, 0));

	if (ball.has_method("activate")):
		ball.activate();

	get_tree().current_scene.add_child(ball);

	# Start cleanup timer
	cleanup_timer = Timer.new();
	cleanup_timer.wait_time = lightning_ability_duration;
	cleanup_timer.one_shot = true;
	cleanup_timer.timeout.connect(func():
		if (is_instance_valid(ball)):
			if (ball.has_method("deactivate")):
				ball.deactivate();
			ball.queue_free();
		is_lightning_active = false;
	);
	add_child(cleanup_timer);
	cleanup_timer.start();

	start_timer(lightning_ability_cooldown, _on_lightning_cooldown_timeout);
	start_timer(lightning_ability_duration, _on_lightning_ability_end);

# Function to Update Lightning Ball Position
func update_lightning_ball_position() -> void:
	if (is_instance_valid(lightning_ball_instance) and lightning_ball_instance.visible):
		offset = Vector2(50, 0) if facing_right else Vector2(-50, 0);
		lightning_ball_instance.global_position = global_position + offset;
		lightning_ball_instance.scale.x = abs(lightning_ball_instance.scale.x) if facing_right else -abs(lightning_ball_instance.scale.x);
		
		# Typo fixed from original 'pvar.ightning_ball_instance' to avoid potential crashes
		if (lightning_ball_instance.has_method("set_direction")):
			lightning_ball_instance.set_direction(Vector2(1, 0) if facing_right else Vector2(-1, 0));

# Function Handle Player Damage
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if (god_mode):
		return;
	camera.trigger_shake(12.0, 0.3);
	player_hurt.play();
	current_health -= amount;
	knockback = (global_position - source_position).normalized() * 500.0;
	velocity = knockback;

	if (current_health <= 0):
		die();

# Function Handle Player Heal
func heal(amount: int) -> void:
	current_health += amount;
	current_health = clamp(current_health, 0, max_health);
	health_changed.emit(current_health, max_health);

# Function Handle Bonus Heart
func add_bonus_heart() -> bool:
	if (bonus_heart_unlocked):
		return false;

	bonus_heart_unlocked = true;

	max_health += 25;
	current_health += 25;

	health_changed.emit(current_health, max_health);

	return true;

# Function Handle Player Die
func die() -> void:
	if (is_dead):
		return;
	is_dead = true;
	camera.trigger_shake(20.0, 0.8);
	MusicManager.play_game_over();

	set_process(false);
	set_process_input(false);

	await get_tree().create_timer(0.5).timeout;
	SceneManager.change_scene("retry_menu");

# Utilities and Helpers

# Function to Handle Player Animation
func handle_animation() -> void:
	if (is_shooting):
		return;

	if (god_mode and velocity.length() > 0):
		sprite.play("idle");
	
	elif (not is_on_floor()):
		if (not jump_anim_played):
			sprite.play("jump", false);
			jump_anim_played = true;
	
	elif (abs(velocity.x) > 0):
		sprite.play("run" if is_sprinting else "walk");
	
	else:
		sprite.play("idle");

# Function of a Timer
func start_timer(duration: float, callback: Callable):
	start_timer_ = Timer.new();
	start_timer_.wait_time = duration;
	start_timer_.one_shot = true;
	start_timer_.timeout.connect(callback);
	add_child(start_timer_);
	start_timer_.start();

# Function to be Called When Level Completed
func stop_level_timer() -> void:
	level_timer.stop();

# Function to get Current Time
func get_current_time() -> float:
	return time_elapsed;

# Function Handle Start Earn Time
func get_stars_earned() -> int:
	time_for_3_stars = 90.0;
	time_for_2_stars = 105.0;
	time_for_1_star  = 120.0;
	
	if (time_elapsed <= time_for_3_stars):
		return 3;
	elif (time_elapsed <= time_for_2_stars):
		return 2;
	elif (time_elapsed <= time_for_1_star):
		return 1;
	else:
		return 0;

# Function Handle Timer Reset
func reset_level_timer() -> void:
	time_elapsed = 0.0;
	timer_label.text = "0.0s";
	level_timer.start();

# Signal Connection Handlers

# Signal Function For Coin
func _update_coin_ui(new_total: int) -> void:
	if (coin_counter_label):
		coin_counter_label.text = str(new_total);

# Signal Function For Zoom
func _on_zoom_button_pressed() -> void:
	if (camera):
		zoom_label = camera.toggle_zoom();
		zoom_button.text = zoom_label;

# Signal Function for Dash Animation Finished
func _on_dash_anim_finished() -> void:
	dash_locked = false;
	
	# Immediately switch back to a valid animation state based on movement
	if (abs(velocity.x) > 10.0):
		sprite.play("walk");
	else:
		sprite.play("idle");

# Signal Function For Weapon Equipped		
func _on_weapon_equipped(item_data: ItemData) -> void:
	sword.equip_weapon(item_data);
	
	# Connect sword swing signals to lock/unlock player movement
	if (not sword.swing_started.is_connected(_on_sword_swing_started)):
		sword.swing_started.connect(_on_sword_swing_started);
	if (not sword.swing_finished.is_connected(_on_sword_swing_finished)):
		sword.swing_finished.connect(_on_sword_swing_finished);

# Signal Function for Lightning Timer End
func _on_lightning_ability_end() -> void:
	is_lightning_active = false;
	
	if (is_instance_valid(lightning_ball_instance)):
		lightning_ball_instance.visible = false;
		if (lightning_ball_instance.has_method("deactivate")):
			lightning_ball_instance.deactivate();

# Signal Function for Lightning CoolDown Timer
func _on_lightning_cooldown_timeout() -> void:
	can_use_lightning = true;

# Signal Function for Shoot Animation End	
func _on_shoot_anim_end() -> void:
	is_shooting = false;
	if (abs(velocity.x) > 10.0):
		sprite.play("walk");
	else:
		sprite.play("idle");

# Signal Function for FireBall Cooldown
func _on_fireball_cooldown_timeout() -> void:
	can_shoot = true;

# Signal Function for Sword Swing
func _on_sword_swing_started() -> void:
	is_sword_swinging = true;

# Signal Function for Sword Swing Finished
func _on_sword_swing_finished() -> void:
	is_sword_swinging = false;
