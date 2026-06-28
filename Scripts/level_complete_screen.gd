extends CanvasLayer

# === BUTTONS ===
@onready var next_button: Button = $MenuPanel/NextLevelButton
@onready var retry_button: Button = $MenuPanel/RetryButton
@onready var main_menu_button: Button = $MenuPanel/MainMenuButton
@onready var quit_button: Button = $MenuPanel/QuitButton

@onready var level_complete_sound: AudioStreamPlayer = $LevelCompleteSound
@onready var star_twinkle_sound: AudioStreamPlayer = $StarTwinkleSound

@onready var star1: AnimatedSprite2D = $MenuPanel/Star1
@onready var star2: AnimatedSprite2D = $MenuPanel/Star2
@onready var star3: AnimatedSprite2D = $MenuPanel/Star3

# === GRAY SHADER ===
@onready var gray_material: ShaderMaterial = preload("res://Shaders/StarEmptyMaterial.tres")

func _ready():
	next_button.pressed.connect(_on_next_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	visible = false

# This function is called by your Flag/Level script
func show_level_complete(stars_earned: int):
	# 1. Show the menu and play sound
	visible = true
	
	if level_complete_sound:
		level_complete_sound.play()
	
	# 2. Reset stars to Empty (Grayed out)
	star1.material = gray_material
	star2.material = gray_material
	star3.material = gray_material
	
	star1.play("empty")
	star2.play("empty")
	star3.play("empty")
	
	# 3. If the player got 0 stars, stop here
	if stars_earned == 0:
		return

	# 4. Animate the stars popping in!
	# First Star
	await get_tree().create_timer(1.0).timeout
	star_twinkle_sound.play()
	star1.material = null  # Remove the gray shader
	star1.play("full")     # Play the full animation
	
	if stars_earned >= 2:
		# Second Star
		await get_tree().create_timer(0.8).timeout
		star_twinkle_sound.play()
		star2.material = null
		star2.play("full")
		
	if stars_earned >= 3:
		# Third Star
		await get_tree().create_timer(0.8).timeout
		star_twinkle_sound.play()
		star3.material = null
		star3.play("full")

# === BUTTON HANDLERS (Kept exactly as you wrote them) ===
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
