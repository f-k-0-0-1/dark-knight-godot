extends Camera2D

# === SETTINGS ===
@export var max_intensity: float = 15.0
@export var shake_duration: float = 0.4
@export var shake_frequency: float = 25.0 

# === STATE ===
var shake_strength: float = 0.0
var shake_timer: float = 0.0
var is_shaking := false
var original_position: Vector2 = Vector2.ZERO

# === ZOOM STATE (2x, 5x, 8x Zoomed Out) ===
# 0.5 = 2x   |   0.2 = 5x   |   0.125 = 8x
var zoom_levels := [0.5, 0.2, 0.125]
# Labels to display on the button for each level
var zoom_labels := ["2x", "5x", "8x"]
var current_zoom_index := 0 # Starts at 2x (index 0)
var zoom_tween: Tween

func _ready():
	# Save the static position of the camera
	original_position = position
	
	# Set initial zoom to 2x (0.5)
	zoom = Vector2(zoom_levels[current_zoom_index], zoom_levels[current_zoom_index])
	zoom_tween = create_tween()
	zoom_tween.kill()

func _process(delta: float) -> void:
	if not is_shaking:
		return

	# 1. Update the timer
	shake_timer -= delta
	
	# 2. Decay
	shake_strength = max_intensity * (shake_timer / shake_duration)
	shake_strength = max(shake_strength, 0.0)
	
	# 3. Generate the Jitter
	var time = Time.get_ticks_msec() / 1000.0
	var noise_x = sin(time * shake_frequency) * cos(time * (shake_frequency * 0.9))
	var noise_y = cos(time * shake_frequency * 1.1) * sin(time * (shake_frequency * 0.8))
	
	# 4. Apply the offset
	position = original_position + Vector2(
		noise_x * shake_strength,
		noise_y * shake_strength
	)
	
	# 5. Reset when finished
	if shake_timer <= 0.0:
		is_shaking = false
		position = original_position

# === SHAKE TRIGGER ===
func trigger_shake(intensity: float = max_intensity, duration: float = shake_duration):
	if is_shaking:
		return
		
	shake_strength = intensity
	shake_timer = duration
	is_shaking = true

# === ZOOM LOGIC (3 Stages) ===
func toggle_zoom():
	# 1. Move to the next index
	current_zoom_index += 1
	
	# 2. Loop back to 2x (0) if we go past 8x
	if current_zoom_index >= zoom_levels.size():
		current_zoom_index = 0
	
	# 3. Get the target zoom value
	var target_zoom = zoom_levels[current_zoom_index]
	
	# 4. Kill any existing tween
	if zoom_tween and zoom_tween.is_running():
		zoom_tween.kill()
	
	zoom_tween = create_tween()
	zoom_tween.set_trans(Tween.TRANS_QUAD)
	zoom_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Animate the zoom
	zoom_tween.tween_property(self, "zoom", Vector2(target_zoom, target_zoom), 0.4)
	
	# 5. Return the text label (e.g. "5x") for the button
	return zoom_labels[current_zoom_index]
