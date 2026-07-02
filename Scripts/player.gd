extends CharacterBody2D

signal health_changed(new_health: int, max_health: int)

@onready var camera: Camera2D = $Camera2D
@onready var zoom_button: Button = $HUD/ZoomButton

@onready var coin_counter_label: Label = $HUD/CoinCounter
@onready var weapon: Node2D;
@onready var weapon_holder = $WeaponHolder;

var dash_locked := false
@export var speed: float = 650.0
@export var sprint_multiplier: float = 5.0
@export var jump_velocity: float = -1150.0
@export var gravity: float = 1500.0
var cooldown_remaining: float = 0.0
@export var fireball_cooldown: float = 0.5
@export var shoot_anim_duration: float = 0.2
@export var lightning_ball_scene: PackedScene
@export var lightning_ability_duration: float = 3.0
@export var lightning_ability_cooldown: float = 10.0
@export var max_health: int = 100
var bonus_heart_unlocked := false
@onready var ability_cooldown_bar: ProgressBar = $HUD/AbilityCooldownBar
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var double_jump_sound: AudioStreamPlayer = $DoubleJumpSound
@onready var player_hurt: AudioStreamPlayer = $PlayerHurt

var is_dead: bool = false
var fireball_scene: PackedScene
var lightning_ball_instance: Area2D
var cheat_command_scene = null;

@onready var timer_label: Label = $HUD/TimerLabel
@onready var level_timer: Timer = $HUD/LevelTimer

var time_elapsed: float = 0.0

var current_health: int = max_health:
	set(value):
		var old_health = current_health
		current_health = clampi(value, 0, max_health)
		if current_health != old_health:
			health_changed.emit(current_health, max_health)

const MAX_JUMPS := 2
var jump_count := 0
var was_on_floor := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_point: Marker2D = $FirePoint
@onready var heart_ui = $"."

var facing_right := true
var can_shoot := true
var is_shooting := false
var jump_anim_played := false
var is_sprinting := false
var god_mode := false
var can_use_lightning := true
var is_lightning_active := false
var cheat_command := false

func _ready():
	Globals.level_coins_updated.connect(_update_coin_ui)
	_update_coin_ui(Globals.level_coins)
	Globals.reset_level_coins()
	
	fireball_scene = SceneManager.scenes.get("fireball_scene")
	health_changed.emit(current_health, max_health)
	
	if zoom_button:
		zoom_button.pressed.connect(_on_zoom_button_pressed)
		zoom_button.text = "2.0x"
		
	Globals.weapon_equipped.connect(_on_weapon_equipped)
	if Globals.equipped_item_name != "":
		_on_weapon_equipped(Globals.equipped_item_name)


func _on_weapon_equipped(weapon_name: String):
	weapon.equip_weapon(weapon_name)


func _update_coin_ui(new_total: int):
	if coin_counter_label:
		coin_counter_label.text = str(new_total)

func _on_zoom_button_pressed():
	if camera:
		var zoom_label = camera.toggle_zoom()
		zoom_button.text = zoom_label

func _input(event):
	if is_dead:
		return
		
	if event.is_action_pressed("sword_attack"):
		if weapon and weapon.has_method("swing"):
			weapon.swing(facing_right);
			
	if event.is_action_pressed("cheat_command"):
		cheat_command = !cheat_command 
		
	if !cheat_command and event.is_action_pressed("god_mode_toggle"):
		god_mode = !god_mode
		velocity = Vector2.ZERO

	if !cheat_command and event.is_action_pressed("fireball"):
		shoot_fireball()

	if !cheat_command and event.is_action_pressed("lightning_ability"):
		activate_lightning_ball()

	if cheat_command and cheat_command_scene != null and  event.is_action_pressed("Enter"):
		cheat_command_scene.run_command();

func _process(_delta: float) -> void:
	
	# Update the level timer text
	if not level_timer.is_stopped():
		time_elapsed += _delta
		timer_label.text = str(snapped(time_elapsed, 0.1)) + "s"
	
	# Logic for cheat command 
	if cheat_command and cheat_command_scene == null:
		cheat_command_scene = SceneManager.get_scene("cheat_command").instantiate();
		add_child(cheat_command_scene);
	elif cheat_command and cheat_command_scene != null:
		cheat_command_scene.visible = true
	else:
		if !cheat_command and cheat_command_scene != null:
			cheat_command_scene.visible = false

func _physics_process(delta):
	handle_movement_input()
	if not god_mode:
		apply_gravity(delta)

	move_and_slide()
	handle_landing_reset()
	handle_animation()
	update_lightning_ball_position()
	
	if cooldown_remaining > 0:
		cooldown_remaining -= delta
		ability_cooldown_bar.value = lightning_ability_cooldown - cooldown_remaining

	if cooldown_remaining <= 0:
		cooldown_remaining = 0
		ability_cooldown_bar.value = lightning_ability_cooldown

func handle_movement_input():
	if velocity.x != 0:
		facing_right = velocity.x > 0

		sprite.flip_h = !facing_right

	if facing_right:
		weapon_holder.position = Vector2(20, -5);
	else:
		weapon_holder.position = Vector2(-20, -5);
		
	var move_speed := speed
	
	is_sprinting = !cheat_command and Input.is_action_pressed("ui_shift")
	if is_sprinting:
		move_speed *= sprint_multiplier

	if !cheat_command and god_mode :
		velocity = Vector2.ZERO
		if Input.is_action_pressed("move_right"):
			velocity.x += move_speed
		if Input.is_action_pressed("move_left"):
			velocity.x -= move_speed
		if Input.is_action_pressed("move_up"):
			velocity.y -= move_speed
		if Input.is_action_pressed("move_down"):
			velocity.y += move_speed
	else:
		var input_direction := 0.0
		if !cheat_command and Input.is_action_pressed("move_left"):
			input_direction -= 1
		if !cheat_command and Input.is_action_pressed("move_right"):
			input_direction += 1

		velocity.x = input_direction * move_speed

		if !cheat_command and Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
			velocity.y = jump_velocity
			jump_count += 1
			jump_anim_played = false
			if jump_count == 1:
				jump_sound.play()
			else:
				double_jump_sound.play()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_landing_reset():
	if is_on_floor() and not was_on_floor:
		jump_count = 0
		jump_anim_played = false
	was_on_floor = is_on_floor()

func _on_dash_anim_finished():
	dash_locked = false  # Unlock the animation
	
	# Immediately switch back to a valid animation state based on movement
	if abs(velocity.x) > 10.0:
		sprite.play("walk")
	else:
		sprite.play("idle")

func shoot_fireball():
	if not can_shoot or fireball_scene == null or is_shooting:
		return
	if is_sprinting:
		return

	var fireball = fireball_scene.instantiate()
	fireball.direction = Vector2.RIGHT if facing_right else Vector2.LEFT
	fireball.global_position = fire_point.global_position
	get_tree().current_scene.add_child(fireball)

	dash_locked = true
	sprite.play("dash")
	sprite.frame = 0
	
	# === FIX: Safely disconnect before connecting again ===
	if sprite.animation_finished.is_connected(_on_dash_anim_finished):
		sprite.animation_finished.disconnect(_on_dash_anim_finished)
	sprite.animation_finished.connect(_on_dash_anim_finished, CONNECT_ONE_SHOT)
	
	is_shooting = true
	can_shoot = false
	
	@warning_ignore("shadowed_variable")
	var camera: Camera2D = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	if camera:
		camera.trigger_shake(5.0, 0.15)

	start_timer(shoot_anim_duration, _on_shoot_anim_end)
	start_timer(fireball_cooldown, _on_fireball_cooldown_timeout)

func activate_lightning_ball():
	if not can_use_lightning or lightning_ball_scene == null:
		return

	can_use_lightning = false
	is_lightning_active = true
	
	cooldown_remaining = lightning_ability_cooldown
	ability_cooldown_bar.max_value = lightning_ability_cooldown
	ability_cooldown_bar.value = 0
	
	var ball = lightning_ball_scene.instantiate() as Area2D
	ball.scale = Vector2(1.5, 1.5)
	ball.global_position = global_position + Vector2(50 if facing_right else -50, 0)
	
	if ball.has_method("set_direction"):
		ball.set_direction(Vector2(1, 0) if facing_right else Vector2(-1, 0))

	if ball.has_method("activate"):
		ball.activate()

	get_tree().current_scene.add_child(ball)

	# Start cleanup timer
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = lightning_ability_duration
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(ball):
			if ball.has_method("deactivate"):
				ball.deactivate()
			ball.queue_free()
		is_lightning_active = false
	)
	add_child(cleanup_timer)
	cleanup_timer.start()

	start_timer(lightning_ability_cooldown, _on_lightning_cooldown_timeout)

	start_timer(lightning_ability_duration, _on_lightning_ability_end)

func _on_lightning_ability_end():
	is_lightning_active = false
	if is_instance_valid(lightning_ball_instance):
		lightning_ball_instance.visible = false
		if lightning_ball_instance.has_method("deactivate"):
			lightning_ball_instance.deactivate()

func _on_lightning_cooldown_timeout():
	can_use_lightning = true

func update_lightning_ball_position():
	if is_instance_valid(lightning_ball_instance) and lightning_ball_instance.visible:
		var offset = Vector2(50, 0) if facing_right else Vector2(-50, 0)
		lightning_ball_instance.global_position = global_position + offset
		lightning_ball_instance.scale.x = abs(lightning_ball_instance.scale.x) if facing_right else -abs(lightning_ball_instance.scale.x)
		if lightning_ball_instance.has_method("set_direction"):
			lightning_ball_instance.set_direction(Vector2(1,0) if facing_right else Vector2(-1,0))

func handle_animation():
	if is_shooting:
		return

	if god_mode and velocity.length() > 0:
		sprite.play("idle")
	elif not is_on_floor():
		if not jump_anim_played:
			sprite.play("jump", false)
			jump_anim_played = true
	elif abs(velocity.x) > 0:
		sprite.play("run" if is_sprinting else "walk")
	else:
		sprite.play("idle")

func start_timer(duration: float, callback: Callable):
	var timer := Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(callback)
	add_child(timer)
	timer.start()

# Call this from your Flag when the level is complete
func stop_level_timer():
	level_timer.stop()

func get_current_time() -> float:
	return time_elapsed

func get_stars_earned() -> int:
	# EDIT THESE NUMBERS to change how hard it is to get stars!
	var time_for_3_stars = 90.0
	var time_for_2_stars = 105.0
	var time_for_1_star  = 120.0
	
	if time_elapsed <= time_for_3_stars:
		return 3
	elif time_elapsed <= time_for_2_stars:
		return 2
	elif time_elapsed <= time_for_1_star:
		return 1
	else:
		return 0

# Call this if you want to reset the timer (e.g., if the player dies)
func reset_level_timer():
	time_elapsed = 0.0
	timer_label.text = "0.0s"
	level_timer.start()

func _on_shoot_anim_end():
	is_shooting = false
	if abs(velocity.x) > 10.0:
		sprite.play("walk")
	else:
		sprite.play("idle")

func _on_fireball_cooldown_timeout():
	can_shoot = true

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if god_mode:
		return
	camera.trigger_shake(12.0, 0.3)
	player_hurt.play()
	current_health -= amount
	var knockback := (global_position - source_position).normalized() * 500.0
	velocity = knockback

	if current_health <= 0:
		die()

func heal(amount:int):

	current_health += amount
	current_health = clamp(current_health,0,max_health)
	health_changed.emit(current_health,max_health)

func add_bonus_heart() -> bool:

	if bonus_heart_unlocked:
		return false

	bonus_heart_unlocked = true

	max_health += 25
	current_health += 25

	health_changed.emit(current_health, max_health)

	return true

func die() -> void:
	if is_dead:
		return
	is_dead = true
	camera.trigger_shake(20.0, 0.8)
	MusicManager.play_game_over()

	set_process(false)
	set_process_input(false)

	await get_tree().create_timer(0.5).timeout
	SceneManager.change_scene("retry_menu")
