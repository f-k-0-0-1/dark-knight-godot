extends CanvasLayer

# === PORTAL EFFECT ===
@onready var effect_rect: ColorRect = $EffectRect
@onready var shader_material: ShaderMaterial = effect_rect.material

signal portal_warp_complete

func _ready():
	if shader_material == null:
		push_error("CRITICAL ERROR: EffectRect has no ShaderMaterial assigned!")
		print("Go to PortalEffect.tscn -> EffectRect -> Inspector -> Material -> New ShaderMaterial")
		
	visible = false

func trigger_portal():
	if shader_material == null:
		print("ERROR: Cannot trigger portal effect, material is null.")
		return

	visible = true
	shader_material.set_shader_parameter("progress", 0.0)
	
	var tween = create_tween()
	tween.tween_property(shader_material, "shader_parameter/progress", 1.0, 1.5)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# === THE FIX: HIDE THE EFFECT ===
	visible = false
	
	portal_warp_complete.emit()
