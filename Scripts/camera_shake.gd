extends Camera2D

# === SETTINGS ===
@export var max_intensity: float = 15.0
@export var shake_duration: float = 0.4
@export var shake_frequency: float = 25.0  # How many times it jitters per second (Higher = sharper)

# === STATE ===
var shake_strength: float = 0.0
var shake_timer: float = 0.0
var is_shaking := false
var original_position: Vector2 = Vector2.ZERO

func _ready():
	# Save the static position of the camera relative to the player
	original_position = position

func _process(delta: float) -> void:
	if not is_shaking:
		return

	# 1. Update the timer
	shake_timer -= delta
	
	# 2. Decay (The shaking gets weaker over time)
	shake_strength = max_intensity * (shake_timer / shake_duration)
	shake_strength = max(shake_strength, 0.0)
	
	# 3. Generate the Jitter (Snapping)
	# We use sine waves with random offsets to create fast, chaotic movements
	var time = Time.get_ticks_msec() / 1000.0
	var noise_x = sin(time * shake_frequency) * cos(time * (shake_frequency * 0.9))
	var noise_y = cos(time * shake_frequency * 1.1) * sin(time * (shake_frequency * 0.8))
	
	# 4. Apply the offset to the camera position
	position = original_position + Vector2(
		noise_x * shake_strength,
		noise_y * shake_strength
	)
	
	# 5. Reset when finished
	if shake_timer <= 0.0:
		is_shaking = false
		position = original_position

# Call this to trigger the shake!
func trigger_shake(intensity: float = max_intensity, duration: float = shake_duration):
	if is_shaking:
		return # Don't interrupt a shake in progress
		
	shake_strength = intensity
	shake_timer = duration
	is_shaking = true
