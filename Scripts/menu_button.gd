extends MenuButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	var popup := get_popup()
	popup.clear()
	_set_popup_style(popup)

	# Add menu items with emojis (for visual appeal)
	popup.add_item("⏸ Pause", 0)
	popup.add_item("▶ Resume", 1)
	popup.add_item("🔁 Retry", 2)
	popup.add_item("🏠 Main Menu", 3)
	popup.add_item("🚪 Quit", 4)

	popup.id_pressed.connect(_on_menu_option_selected)

func _on_menu_option_selected(id: int) -> void:
	match id:
		0:
			MusicManager.play_button_click()
			await get_tree().create_timer(0.35, true).timeout
			get_tree().paused = true
		
		1: 
			MusicManager.play_button_click()
			get_tree().paused = false
		
		2:
			MusicManager.play_button_click()
			get_tree().paused = false
			get_tree().reload_current_scene()
			
		3:
			MusicManager.play_button_click()
			get_tree().paused = false
			if SceneManager.scenes.has("main_menu"):
				get_tree().change_scene_to_packed(SceneManager.scenes["main_menu"])
			else:
				push_error("Scene 'main_menu' not found in SceneManager!")
				
		4:
			MusicManager.play_button_click()
			get_tree().paused = false
			get_tree().quit()

func _set_popup_style(popup: PopupMenu) -> void:
	var theme := Theme.new()

	# Optional: Custom font
	if ResourceLoader.exists("res://Fonts/YourCustomFont.tres"):
		var font = load("res://Fonts/YourCustomFont.tres")
		theme.set_font("font", "PopupMenu", font)

	# Set colors
	theme.set_color("font_color", "PopupMenu", Color.WHITE)
	theme.set_color("font_color_hover", "PopupMenu", Color.BLACK)
	theme.set_color("font_color_pressed", "PopupMenu", Color.GRAY)
	theme.set_color("bg_color", "PopupMenu", Color(0.1, 0.1, 0.1, 0.95))  # semi-transparent dark background

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)

	# Set margins using Side enum (Godot 4.x)
	style.set_content_margin(SIDE_LEFT, 12)
	style.set_content_margin(SIDE_RIGHT, 12)
	style.set_content_margin(SIDE_TOP, 6)
	style.set_content_margin(SIDE_BOTTOM, 6)

	theme.set_stylebox("panel", "PopupMenu", style)
	popup.theme = theme
