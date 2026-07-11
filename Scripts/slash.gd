extends Node2D

@onready var slash_sprite: AnimatedSprite2D = $SlashSprite
@onready var delete_timer: Timer = $AutoDeleteTimer

# Combo variable passed from the Sword script
var current_combo := 0

func init(slash_type: int):
	current_combo = slash_type
	
	# Decide which animation to play based on the combo count
	if current_combo == 2:
		# Combo 3: Play the Multi Slash (Sweep)
		slash_sprite.play("multi_slash")
		
		# Make the Multi Slash bigger and wider!
		scale = Vector2(1.5, 1.5)
	else:
		# Combo 1 or 2: Play the Single Slash
		slash_sprite.play("single_slash")
		
		# Reset scale to normal for single slashes
		scale = Vector2(1.0, 1.0)
		
		# === THE TRICK: Offset Slash 1 and Slash 2 differently ===
		if current_combo == 0:
			# Slash 1: Slightly lower
			position += Vector2(0, 10)
		elif current_combo == 1:
			# Slash 2: Slightly higher
			position += Vector2(0, -10)
	
	# Wait for the animation to finish, then delete
	await slash_sprite.animation_finished
	queue_free()
