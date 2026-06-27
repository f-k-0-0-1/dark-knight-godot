extends Label

@export var move_distance := 80.0
@export var duration := 1.5

func _ready():

	modulate.a = 1.0

	var tween = create_tween()

	tween.set_parallel(true)

	# Move upward
	tween.tween_property(
		self,
		"global_position:y",
		global_position.y - move_distance,
		duration
	)

	# Fade out
	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		duration
	)

	await tween.finished

	queue_free()
