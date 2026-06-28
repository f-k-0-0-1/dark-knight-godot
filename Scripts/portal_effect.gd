extends CanvasLayer

# === PORTAL EFFECT ===
@onready var effect_rect: ColorRect = $EffectRect
@onready var shader_material: ShaderMaterial = effect_rect.material
@onready var teleport_sound: AudioStreamPlayer = $TeleportSound  # NEW NODE REFERENCE

signal portal_warp_complete

func _ready():
	if shader_material == null:
		push_error("CRITICAL ERROR: EffectRect has no ShaderMaterial assigned!")
		
	visible = false

func trigger_portal():
	if shader_material == null:
		print("ERROR: Cannot trigger portal effect, material is null.")
		return

	visible = true
	shader_material.set_shader_parameter("progress", 0.0)
	
	# === PLAY THE SOUND LATE IN THE ANIMATION ===
	# We use a separate timer to play the sound 0.2 seconds before the visual ends
	await get_tree().create_timer(0.8).timeout
	if teleport_sound:
		teleport_sound.play()
	
	var tween = create_tween()
	tween.tween_property(shader_material, "shader_parameter/progress", 1.0, 1.5)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	
	visible = false
	portal_warp_complete.emit()
