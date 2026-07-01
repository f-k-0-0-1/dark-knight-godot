extends CanvasLayer

@onready var tutorial_text: Label = $PopupPanel/TutorialText
@onready var close_button: Button = $PopupPanel/CloseButton
@onready var auto_close_timer: Timer = $PopupPanel/AutoCloseTimer

@warning_ignore("unused_signal")
signal tutorial_closed

func _ready():
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)

	# Connect timer signal
	auto_close_timer.timeout.connect(_on_close_pressed)

func show_tutorial(text: String):
	tutorial_text.text = text
	visible = true
	get_tree().paused = false

	# Start timer for auto-close
	auto_close_timer.wait_time = 4.0
	auto_close_timer.one_shot = true
	auto_close_timer.start()

func _on_close_pressed():
	MusicManager.play_button_click()
	await get_tree().create_timer(0.35, true).timeout
	get_tree().paused = false
	visible = false
