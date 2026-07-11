extends CharacterBody2D

# Scrpits
@onready var psig = $Signals;
@onready var pvar = $Variables;

# Signals
@warning_ignore("unused_signal")
signal health_changed(new_health: int, max_health: int)

# Init Stuff Here
func _ready() -> void:
	# Init FireBall Scene
	pvar.fireball_scene = SceneManager.scenes.get("fireball_scene");
	
	# Init Signals connection
	Globals.level_coins_updated.connect(psig._update_coin_ui);
	Globals.weapon_equipped.connect(psig._on_weapon_equipped)
	
	# Init Conis
	psig._update_coin_ui(Globals.level_coins);
	Globals.reset_level_coins();
	
	# Set Default Health via Signal
	health_changed.emit(pvar.current_health, pvar.max_health);
	
	# Init Zoom Button
	if (pvar.zoom_button):
		pvar.zoom_button.pressed.connect(psig._on_zoom_button_pressed);
		pvar.zoom_button.text = "2.0x";
	
	# Init Equipped Item
	if (!Globals.equipped_item_name.is_empty()):
		pvar.saved_item = Globals.get_item_data_by_name(Globals.equipped_item_name);
		
		# Send Signal if weapon equipped
		if (pvar.saved_item != null):
			pvar.psig._on_weapon_equipped(pvar.saved_item);
		else:
			print("Player: saved equipped item not found: ", Globals.equipped_item_name);

# Handle Input Events Here
func _input(event) -> void:
	if (pvar.is_dead):
		return;
		
	if (!pvar.cheat_command and event.is_action_pressed("fireball")):
		shoot_fireball();

	if (!pvar.cheat_command and event.is_action_pressed("lightning_ability")):
		activate_lightning_ball();
	
	if (!pvar.cheat_command and event.is_action_pressed("sword_attack")):
		if (pvar.sword and pvar.sword.has_method("swing")):
			pvar.sword.swing(pvar.facing_right);
			
	if (event.is_action_pressed("cheat_command")):
		pvar.cheat_command = !pvar.cheat_command;
		
	if (!pvar.cheat_command and event.is_action_pressed("god_mode_toggle")):
		pvar.god_mode = !pvar.god_mode;
		velocity = Vector2.ZERO;

	if !pvar.cheat_command and event.is_action_pressed("fireball"):
		shoot_fireball();

	if (!pvar.cheat_command and event.is_action_pressed("lightning_ability")):
		activate_lightning_ball();

	if (pvar.cheat_command and pvar.cheat_command_scene != null and  event.is_action_pressed("Enter")):
		pvar.cheat_command_scene.run_command();
		
	if (!pvar.cheat_command and Input.is_action_pressed("ui_shift")):
		pvar.is_sprinting = true;
		pvar.move_speed = pvar.sprint_speed;
		
	if (!pvar.cheat_command and Input.is_action_just_released("ui_shift")):
		pvar.is_sprinting = false;
		pvar.move_speed = pvar.speed

# Handle Physics Here
func _physics_process(delta) -> void:
	if (not pvar.god_mode): apply_gravity(delta);
		
	handle_movement_input();
	move_and_slide();
	handle_landing_reset();
	handle_animation();
	update_lightning_ball_position();
	
	if (pvar.cooldown_remaining > 0):
		pvar.cooldown_remaining -= delta;
		pvar.ability_cooldown_bar.value = pvar.lightning_ability_cooldown - pvar.cooldown_remaining;

	if (pvar.cooldown_remaining <= 0):
		pvar.cooldown_remaining = 0;
		pvar.ability_cooldown_bar.value = pvar.lightning_ability_cooldown;

# Every Frame Logic Here
func _process(_delta: float) -> void:
	# Keep Track of the Player Health
	if (pvar.current_health != pvar.old_health):
		health_changed.emit(pvar.current_health, pvar.max_health);
	
	# Update the level timer text
	if (not pvar.level_timer.is_stopped()):
		pvar.time_elapsed += _delta;
		pvar.timer_label.text = str(snapped(pvar.time_elapsed, 0.1)) + "s";
	
	# Logic for cheat command 
	if (pvar.cheat_command and pvar.cheat_command_scene == null):
		pvar.cheat_command_scene = SceneManager.get_scene("cheat_command").instantiate();
		add_child(pvar.cheat_command_scene);
	
	elif (pvar.cheat_command and pvar.cheat_command_scene != null):
		pvar.cheat_command_scene.visible = true;
	
	else: if (!pvar.cheat_command and pvar.cheat_command_scene != null):
			pvar.cheat_command_scene.visible = false;

# Function Handles PLayer Movement
func handle_movement_input() -> void:

	pvar.input_direction_A = Input.get_axis("move_left", "move_right");

	if (pvar.input_direction_A != 0):
		pvar.facing_right = pvar.input_direction_A > 0;

	pvar.sprite.flip_h = !pvar.facing_right;

	if (pvar.facing_right):
		pvar.sword_holder.position = Vector2(20, -5);
	
	# Lock horizontal movement during sword swing
	if (pvar.is_sword_swinging):
		velocity.x = 0;
		return;

	if (!pvar.cheat_command and pvar.god_mode):
		velocity = Vector2.ZERO;
		if Input.is_action_pressed("move_right"):
			velocity.x += pvar.move_speed;
		if Input.is_action_pressed("move_left"):
			velocity.x -= pvar.move_speed;
		if Input.is_action_pressed("move_up"):
			velocity.y -= pvar.move_speed;
		if Input.is_action_pressed("move_down"):
			velocity.y += pvar.move_speed;
	else:
		pvar.sword_holder.position = Vector2(-20, -5);

	if (!pvar.cheat_command and pvar.god_mode):
		velocity = Vector2.ZERO;
		if (Input.is_action_pressed("move_right")):
			velocity.x += pvar.move_speed;
		if (Input.is_action_pressed("move_left")):
			velocity.x -= pvar.move_speed;
		if (Input.is_action_pressed("move_up")):
			velocity.y -= pvar.move_speed;
		if (Input.is_action_pressed("move_down")):
			velocity.y += pvar.move_speed;
	else:
		pvar.input_direction = 0.0;
		if (!pvar.cheat_command and Input.is_action_pressed("move_left")):
			pvar.input_direction -= 1;
		if (!pvar.cheat_command and Input.is_action_pressed("move_right")):
			pvar.input_direction += 1;

		velocity.x = pvar.input_direction * pvar.move_speed;

		# Jump and Jump Sound Logic
		if (!pvar.cheat_command and Input.is_action_just_pressed("jump") and pvar.jump_count < pvar.MAX_JUMPS):
			velocity.y = pvar.jump_velocity;
			pvar.jump_count += 1;
			pvar.jump_anim_played = false;
			if (pvar.jump_count == 1):
				pvar.jump_sound.play();
			else:
				pvar.double_jump_sound.play();

# Function to Apply Gravity to PLayer
func apply_gravity(delta) -> void:
	if (not is_on_floor()):
		velocity.y += pvar.gravity * delta;

# Function to Handle Player Landing from Jump
func handle_landing_reset() -> void:
	if (is_on_floor() and not pvar.was_on_floor):
		pvar.jump_count = 0;
		pvar.jump_anim_played = false;
	pvar.was_on_floor = is_on_floor();

# Function Handel Player Fireball Shooting
func shoot_fireball() -> void:
	if (not pvar.can_shoot or pvar.fireball_scene == null or pvar.is_shooting):
		return;
		
	pvar.fireball = pvar.fireball_scene.instantiate();
	pvar.fireball.direction = Vector2.RIGHT if pvar.facing_right else Vector2.LEFT;
	pvar.fireball.global_position = pvar.fire_point.global_position;
	get_tree().current_scene.add_child(pvar.fireball);

	pvar.dash_locked = true;
	pvar.sprite.play("dash");
	pvar.sprite.frame = 0;
	
	# Safely disconnect before connecting again 
	if (pvar.sprite.animation_finished.is_connected(psig._on_dash_anim_finished)):
		pvar.sprite.animation_finished.disconnect(psig._on_dash_anim_finished);
	pvar.sprite.animation_finished.connect(psig._on_dash_anim_finished, CONNECT_ONE_SHOT);
	
	pvar.is_shooting = true;
	pvar.can_shoot = false;
	
	@warning_ignore("shadowed_variable")
	if pvar.camera:
		pvar.camera.trigger_shake(5.0, 0.15);

	start_timer(pvar.shoot_anim_duration, psig._on_shoot_anim_end);
	start_timer(pvar.fireball_cooldown, psig._on_fireball_cooldown_timeout);

# Function Handle Player Lightning Ball
func activate_lightning_ball() -> void:
	if (not pvar.can_use_lightning or pvar.lightning_ball_scene == null):
		return;

	pvar.can_use_lightning = false;
	pvar.is_lightning_active = true;
	
	pvar.cooldown_remaining = pvar.lightning_ability_cooldown;
	pvar.ability_cooldown_bar.max_value = pvar.lightning_ability_cooldown;
	pvar.ability_cooldown_bar.value = 0;
	
	pvar.ball = pvar.lightning_ball_scene.instantiate() as Area2D;
	pvar.ball.scale = Vector2(1.5, 1.5);
	pvar.ball.global_position = pvar.global_position + Vector2(50 if pvar.facing_right else -50, 0);
	
	if (pvar.ball.has_method("set_direction")):
		pvar.ball.set_direction(Vector2(1, 0) if pvar.facing_right else Vector2(-1, 0));

	if (pvar.ball.has_method("activate")):
		pvar.ball.activate();

	get_tree().current_scene.add_child(pvar.ball);

	# Start cleanup timer
	pvar.cleanup_timer = Timer.new();
	pvar.cleanup_timer.wait_time = pvar.lightning_ability_duration;
	pvar.cleanup_timer.one_shot = true;
	pvar.cleanup_timer.timeout.connect(func():
		if (is_instance_valid(pvar.ball)):
			if (pvar.ball.has_method("deactivate")):
				pvar.ball.deactivate();
			pvar.ball.queue_free();
		pvar.is_lightning_active = false;
	);
	add_child(pvar.cleanup_timer);
	pvar.cleanup_timer.start();

	start_timer(pvar.lightning_ability_cooldown, psig._on_lightning_cooldown_timeout);

	start_timer(pvar.lightning_ability_duration, psig._on_lightning_ability_end);

# Function to Update Lightning Ball Position
func update_lightning_ball_position() -> void:
	if (is_instance_valid(pvar.lightning_ball_instance) and pvar.lightning_ball_instance.visible):
		pvar.offset = Vector2(50, 0) if pvar.facing_right else Vector2(-50, 0);
		pvar.lightning_ball_instance.global_position = pvar.global_position + pvar.offset;
		pvar.lightning_ball_instance.scale.x = abs(pvar.lightning_ball_instance.scale.x) if pvar.facing_right else -abs(pvar.lightning_ball_instance.scale.x)
		
		if (pvar.lightning_ball_instance.has_method("set_direction")):
			pvar.ightning_ball_instance.set_direction(Vector2(1,0) if pvar.facing_right else Vector2(-1,0));

# Function to Handle Player Animaion
func handle_animation() -> void:
	if (pvar.is_shooting):
		return;

	if (pvar.god_mode and velocity.length() > 0):
		pvar.sprite.play("idle");
	
	elif (not is_on_floor()):
		if (not pvar.jump_anim_played):
			pvar.sprite.play("jump", false);
			pvar.jump_anim_played = true;
	
	elif (abs(velocity.x) > 0):
		pvar.sprite.play("run" if pvar.is_sprinting else "walk");
	
	else:
		pvar.sprite.play("idle");

# Function of a Timer
func start_timer(duration: float, callback: Callable):
	pvar.start_timer_ = Timer.new();
	pvar.start_timer_.wait_time = duration;
	pvar.start_timer_.one_shot = true;
	pvar.start_timer_.timeout.connect(callback);
	add_child(pvar.start_timer_);
	pvar.start_timer_.start();

# Function to be Called When Level Completed
func stop_level_timer() -> void:
	pvar.level_timer.stop();

# Function to get Current Time
func get_current_time() -> float:
	return pvar.time_elapsed;

# Function Handle Start Earn Time
func get_stars_earned() -> int:
	pvar.time_for_3_stars = 90.0;
	pvar.time_for_2_stars = 105.0;
	pvar.time_for_1_star  = 120.0;
	
	if pvar.time_elapsed <= pvar.time_for_3_stars:
		return 3;
	elif pvar.time_elapsed <= pvar.time_for_2_stars:
		return 2;
	elif pvar.time_elapsed <= pvar.time_for_1_star:
		return 1;
	else:
		return 0;

# Function Handle Timer Reset
func reset_level_timer() -> void:
	pvar.time_elapsed = 0.0;
	pvar.timer_label.text = "0.0s";
	pvar.level_timer.start();

# Function Handle Player Damage
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if (pvar.god_mode):
		return;
	pvar.camera.trigger_shake(12.0, 0.3);
	pvar.player_hurt.play();
	pvar.current_health -= amount;
	pvar.knockback = (global_position - source_position).normalized() * 500.0;
	velocity = pvar.knockback;

	if (pvar.current_health <= 0):
		die();

# Function Handle Player Heal
func heal(amount:int):
	pvar.current_health += amount;
	pvar.current_health = clamp(pvar.current_health, 0, pvar.max_health);
	health_changed.emit(pvar.current_health, pvar.max_health);

# Function Handle Bonus Heart
func add_bonus_heart() -> bool:

	if (pvar.bonus_heart_unlocked):
		return false;

	pvar.bonus_heart_unlocked = true;

	pvar.max_health += 25;
	pvar.current_health += 25;

	health_changed.emit(pvar.current_health, pvar.max_health);

	return true;

# Function Handle Player Die
func die() -> void:
	if (pvar.is_dead):
		return;
	pvar.is_dead = true;
	pvar.camera.trigger_shake(20.0, 0.8);
	MusicManager.play_game_over();

	set_process(false);
	set_process_input(false);

	await get_tree().create_timer(0.5).timeout;
	SceneManager.change_scene("retry_menu");
