extends Control

@onready var hearts_container: HBoxContainer = $HeartsContainer

@onready var heart_textures: Array[Texture2D] = [
	preload("res://Assets/sprite.png"),         # Full Heart
	preload("res://Assets/sprite_empty.png")    # Empty Heart
]

const HEALTH_PER_HEART := 25

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)

		# Update immediately when the scene starts
		_on_player_health_changed(player.current_health, player.max_health)
	else:
		push_error("Player or 'health_changed' signal not found!")

func _on_player_health_changed(current_health: int, max_health: int) -> void:

	var total_hearts := int(ceil(float(max_health) / HEALTH_PER_HEART))
	var filled_hearts := int(ceil(float(current_health) / HEALTH_PER_HEART))

	# Add extra hearts if needed
	while hearts_container.get_child_count() < total_hearts:

		var template: TextureRect = hearts_container.get_child(0)
		var new_heart: TextureRect = template.duplicate()

		new_heart.texture = heart_textures[1]

		hearts_container.add_child(new_heart)

	# Remove extra hearts
	while hearts_container.get_child_count() > total_hearts:

		var heart := hearts_container.get_child(hearts_container.get_child_count() - 1)

		hearts_container.remove_child(heart)

		heart.queue_free()

	# Update heart textures
	for i in range(hearts_container.get_child_count()):

		var heart: TextureRect = hearts_container.get_child(i)

		if i < filled_hearts:
			heart.texture = heart_textures[0]
		else:
			heart.texture = heart_textures[1]
