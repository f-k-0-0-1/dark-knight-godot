extends Node2D

@onready var music: AudioStreamPlayer = $AudioStreamPlayer
@onready var sfx: AudioStreamPlayer = $GameOver

func _ready():
	music.play()
	
func play_game_over():
	sfx.stream = preload("res://Audio/sfx/game over.mp3")
	sfx.play()
