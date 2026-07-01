extends MenuButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Strip the white outline from the main MenuButton itself if focused
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var popup := get_popup()
	popup.clear()
	_set_popup_style(popup)

	# Cleaned up item strings—fancy styling handles the visual depth
	var pause_text = "▶  Resume" if get_tree().paused else "⏸  Pause"
	popup.add_item(pause_text, 0)      # Index 0
	popup.add_item("🔁  Retry", 1)       # Index 1
	
	# Initial Dynamic Text Check
	var bgm_text = "🔇  BGM Mute" if MusicManager.isMusicPlaying else "🔊  BGM Unmute"
	popup.add_item(bgm_text, 2)         # Index 2
	
	popup.add_item("🏠  Main Menu", 3)   # Index 3
	popup.add_item("🚪  Quit", 4)        # Index 4

	popup.id_pressed.connect(_on_menu_option_selected)

func _on_menu_option_selected(id: int) -> void:
	match id:
		0:
			MusicManager.play_button_click()
			
			if get_tree().paused:
				# Game is currently paused -> Resume it
				get_tree().paused = false
				get_popup().set_item_text(0, "⏸  Pause")
			else:
				# Game is running -> Pause it
				await get_tree().create_timer(0.15, true).timeout # Snappier latency feel
				get_tree().paused = true
				get_popup().set_item_text(0, "▶  Resume")
		
		1:
			MusicManager.play_button_click()
			get_tree().paused = false
			get_tree().reload_current_scene()
		
		2:
			MusicManager.play_button_click()
			# Toggled state flip
			MusicManager.isMusicPlaying = !MusicManager.isMusicPlaying
			
			# FIXED: Changed index from 3 to 2 to match its position
			if MusicManager.isMusicPlaying:
				get_popup().set_item_text(2, "🔇  BGM Mute")
				MusicManager.music.play()
			else:
				get_popup().set_item_text(2, "🔊  BGM Unmute")
				MusicManager.music.stop()
		
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
	var luxury_theme = Theme.new()
	
	# --- 1. Typography & Colors ---
	if ResourceLoader.exists("res://Fonts/YourCustomFont.tres"):
		var font = load("res://Fonts/YourCustomFont.tres")
		luxury_theme.set_font("font", "PopupMenu", font)
		
	# High-end Metallic/Neon Text States
	luxury_theme.set_color("font_color", "PopupMenu", Color(0.95, 0.95, 0.98)) # Clean diamond white
	luxury_theme.set_color("font_color_hover", "PopupMenu", Color(1.0, 0.65, 0.0)) # Cyberpunk Gold / Amber hover
	luxury_theme.set_color("font_color_pressed", "PopupMenu", Color(0.6, 0.6, 0.6))
	
	# Extra item vertical padding for a spacious, premium look
	luxury_theme.set_constant("v_separation", "PopupMenu", 12)

	# --- 2. Main Background Panel (Sleek Obsidian Glass) ---
	var panel_style := StyleBoxFlat.new()
	
	# AAA UI trick: Deep charcoal tint with high translucency looks identical to premium frosted glass
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 0.93)
	
	# Clean rounded edges
	panel_style.set_corner_radius_all(8)
	
	# 3D Metallic Rim Light effect (Thin, translucent white outline)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_blend = true 
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.12) # Catches light beautifully without being harsh

	# Deep volumetric soft shadow to give physical depth
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0, 8)

	# Inner Panel Padding layout
	panel_style.set_content_margin(SIDE_LEFT, 16)
	panel_style.set_content_margin(SIDE_RIGHT, 16)
	panel_style.set_content_margin(SIDE_TOP, 12)
	panel_style.set_content_margin(SIDE_BOTTOM, 12)
	
	luxury_theme.set_stylebox("panel", "PopupMenu", panel_style)

	# --- 3. Hover Selection Style (Glow Strip Accent) ---
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 0.65, 0.0, 0.07) # Micro-dose highlight matching the text glow
	hover_style.set_corner_radius_all(4)
	
	# Sharp left vertical indicator accent
	hover_style.border_width_left = 3
	hover_style.border_color = Color(1.0, 0.651, 0.0, 0.0)
	
	hover_style.set_content_margin(SIDE_LEFT, 12)
	hover_style.set_content_margin(SIDE_TOP, 6)
	hover_style.set_content_margin(SIDE_BOTTOM, 6)
	
	luxury_theme.set_stylebox("hover", "PopupMenu", hover_style)

	# --- 4. Safely Hide the Scrollbar ---
	luxury_theme.set_stylebox("scroll", "PopupMenu", StyleBoxEmpty.new())
	luxury_theme.set_stylebox("scroll_focus", "PopupMenu", StyleBoxEmpty.new())
	luxury_theme.set_constant("scrollbar_width", "PopupMenu", 0)

	# Apply final verified theme properties
	popup.theme = luxury_theme
