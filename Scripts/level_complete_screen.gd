extends CanvasLayer

# === BUTTONS ===
@onready var next_button: Button = $MenuPanel/NextLevelButton
@onready var retry_button: Button = $MenuPanel/RetryButton
@onready var main_menu_button: Button = $MenuPanel/MainMenuButton
@onready var quit_button: Button = $MenuPanel/QuitButton
@onready var level_complete_sound: AudioStreamPlayer = $LevelCompleteSound

# === STAR TWINKLE SOUND ===
@onready var star_twinkle_sound: AudioStreamPlayer = $StarTwinkleSound

# === 3 ANIMATED STARS ===
@onready var star1: AnimatedSprite2D = $MenuPanel/Star1
@onready var star2: AnimatedSprite2D = $MenuPanel/Star2
@onready var star3: AnimatedSprite2D = $MenuPanel/Star3

# === BEST TIME LABELS ===
@onready var best_time_label: Label = $MenuPanel/BestTimeLabel
@onready var new_record_label: Label = $MenuPanel/NewRecordLabel

# === GRAY SHADER ===
@onready var gray_material: ShaderMaterial = preload("res://Shaders/StarEmptyMaterial.tres")

func _ready():
	next_button.pressed.connect(_on_next_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	visible = false

func show_level_complete(stars_earned: int, current_time: float, is_new_record: bool = false):
	visible = true
	
	if level_complete_sound:
		level_complete_sound.play()
	
	# === BEST TIME LOGIC ===
	var config = ConfigFile.new()
	var file_path = "user://level_times.ini"
	
	var saved_best = null
	if config.load(file_path) == OK:
		saved_best = config.get_value(SceneManager.current_level, "best_time", null)
	
	if best_time_label != null:
		if saved_best != null and saved_best > 0.0:
			best_time_label.text = "Best Time: " + String.num(float(saved_best), 1) + "s"
		else:
			best_time_label.text = "Best Time: " + String.num(float(current_time), 1) + "s"
			
	if new_record_label != null:
		if is_new_record:
			new_record_label.visible = true
			new_record_label.text = "★ NEW RECORD! (" + String.num(float(current_time), 1) + "s) ★"
			new_record_label.modulate = Color.WHITE
			new_record_label.scale = Vector2(1.0, 1.0)
			new_record_label.position = Vector2(448,224)
			
			var pop_tween = create_tween()
			new_record_label.scale = Vector2(0.5, 0.5)
			pop_tween.tween_property(new_record_label, "scale", Vector2(1.2, 1.2), 0.2)
			pop_tween.tween_property(new_record_label, "scale", Vector2(1.0, 1.0), 0.1)
		else:
			if saved_best != null and saved_best > 0.0:
				new_record_label.visible = true
				new_record_label.text = "Your Time: " + String.num(float(current_time), 1) + "s"
				new_record_label.modulate = Color(0.8, 0.8, 0.8)
				new_record_label.scale = Vector2(1.0, 1.0)
				new_record_label.position = Vector2(448,224)
			else:
				new_record_label.visible = false
				new_record_label.modulate = Color.WHITE

	# === STARS LOGIC ===
	star1.material = gray_material
	star2.material = gray_material
	star3.material = gray_material
	star1.play("empty")
	star2.play("empty")
	star3.play("empty")
	
	if stars_earned == 0:
		return

	await get_tree().create_timer(1.0).timeout
	star_twinkle_sound.play()
	star1.material = null
	star1.play("full")
	
	if stars_earned >= 2:
		await get_tree().create_timer(0.8).timeout
		star_twinkle_sound.play()
		star2.material = null
		star2.play("full")
		
	if stars_earned >= 3:
		await get_tree().create_timer(0.8).timeout
		star_twinkle_sound.play()
		star3.material = null
		star3.play("full")

# === BUTTON HANDLERS ===
func _on_next_pressed():
	get_tree().paused = false
	if level_complete_sound.playing:
		level_complete_sound.stop()

	var next_level: int = SceneManager.current_level.trim_prefix("level_").to_int()
	if (next_level != SceneManager.last_level):
		SceneManager.change_scene("level_" + str(next_level + 1));
	else :
		SceneManager.change_scene("credits") 

func _on_retry_pressed():
	SceneManager.change_scene(SceneManager.current_level)

func _on_main_menu_pressed():
	SceneManager.change_scene("main_menu")

func _on_quit_pressed():
	get_tree().quit()
