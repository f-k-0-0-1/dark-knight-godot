extends Node2D

# Get the reference to the AnimatedSprite2D node
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Play the "fire" animation set up in your SpriteFrames
	animated_sprite.play("fire")
