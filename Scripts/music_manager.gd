extends Node2D

@onready var music: AudioStreamPlayer = $AudioStreamPlayer
@onready var sfx: AudioStreamPlayer = $GameOver
@onready var button_click: AudioStreamPlayer = $buttonclick

func _ready():
	music.play()
	
func play_game_over():
	sfx.stream = preload("res://Audio/sfx/game over.mp3")
	sfx.play()

func play_button_click():
	button_click.play()
