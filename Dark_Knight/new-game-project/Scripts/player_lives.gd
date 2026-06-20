# HUD.gd
extends Control

@onready var hearts_container: HBoxContainer = $"HeartsContainer" # Path to your HBoxContainer
@onready var heart_textures: Array[Texture2D] = [
	preload("res://Assets/sprite.png"), # Path to your pink heart texture
	preload("res://Assets/sprite_empty.png")  # Path to your grey heart texture
]

const HEALTH_PER_HEART: int = 25 # Each heart represents 25 health points

func _ready() -> void:
	# Get a reference to the player node (assuming it's in the main scene or a known path)
	# You might need to adjust this path based on your scene tree
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_signal("health_changed"):
		player_node.health_changed.connect(_on_player_health_changed)
	else:
		push_error("Player node or 'health_changed' signal not found!")

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	# Calculate how many full hearts should be displayed
	var full_hearts_count: int = ceil(float(new_health) / HEALTH_PER_HEART)

	# Iterate through each heart TextureRect in the container
	for i in hearts_container.get_child_count():
		var heart_texture_rect: TextureRect = hearts_container.get_child(i)
		if heart_texture_rect:
			if i < full_hearts_count:
				heart_texture_rect.texture = heart_textures[0] # Set to pink heart
			else:
				heart_texture_rect.texture = heart_textures[1] # Set to grey heart
