extends Control

@onready var play_button: Button = $Panel/Play
@onready var credits_button: Button = $Panel/Credits
@onready var quit_button: Button = $Panel/Quit
@onready var click_sound: AudioStreamPlayer = $clicksound
@onready var mute_sound_btn : Button = $Panel/Sound

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Check for the bg sound flag
	if !MusicManager.isMusicPlaying:
		mute_sound_btn.get_child(0).visible = true;
		mute_sound_btn.get_child(1).visible = false;
	else:
		mute_sound_btn.get_child(1).visible = true
		mute_sound_btn.get_child(0).visible = false;
		
	
	if not play_button or not quit_button:
		push_error("Play or Quit button not found! Check your node names and paths.")
		return

	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().paused = false
	
	if SceneManager.scenes.has("level_select"):
		get_tree().change_scene_to_packed(SceneManager.scenes["level_select"])
	else:
		push_error("Scene 'LevelSelect' not found in SceneManager!")
		
func _on_credits_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().change_scene_to_packed(SceneManager.scenes["credits"])

func _on_quit_pressed():
	click_sound.play()
	await click_sound.finished
	get_tree().paused = false
	get_tree().quit()


func _on_sound_pressed() -> void:
	if MusicManager.isMusicPlaying:
		MusicManager.music.stop();
		mute_sound_btn.get_child(0).visible = true;
		mute_sound_btn.get_child(1).visible = false;
		MusicManager.isMusicPlaying = false;
	else:
		MusicManager.music.play();
		mute_sound_btn.get_child(1).visible = true
		mute_sound_btn.get_child(0).visible = false;
		MusicManager.isMusicPlaying = true;
