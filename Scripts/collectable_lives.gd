extends Area2D

@export var heal_amount := 1

# Float settings
@export var float_height := 4.0
@export var float_speed := 2.0

# Pulse settings
@export var pulse_amount := 0.04
@export var pulse_speed := 2.0

@onready var pickup_sound: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite: Sprite2D = $Sprite2D

var start_position: Vector2
var time := 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	start_position = position

func _process(delta):
	time += delta

	# Gentle floating
	position.y = start_position.y + sin(time * float_speed) * float_height

	# Gentle pulse
	var scale_factor = 1.0 + sin(time * pulse_speed) * pulse_amount
	sprite.scale = Vector2.ONE * scale_factor

func _on_body_entered(body):

	if !body.is_in_group("player"):
		return

	if body.current_health < body.max_health:
		body.heal(heal_amount)

	elif body.add_bonus_heart():

		var floating_text = SceneManager.scenes["floating_text"].instantiate()
		floating_text.text = "Bonus Life"
		floating_text.global_position = global_position

		get_tree().current_scene.add_child(floating_text)

	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)

	if pickup_sound:
		pickup_sound.play()

	sprite.hide()

	await pickup_sound.finished

	queue_free()
