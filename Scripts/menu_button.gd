extends MenuButton

# Explicit constants for Menu Item IDs
const MENU_ID_PAUSE: int = 0
const MENU_ID_RETRY: int = 1
const MENU_ID_CHAT: int = 2   # <-- Moved to 3rd place (ID 2)
const MENU_ID_BGM: int = 3
const MENU_ID_MAIN_MENU: int = 4
const MENU_ID_QUIT: int = 5

func _ready() -> void:
	# Ensure the menu processes even when the scene tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Strip the white outline from the main MenuButton itself if focused
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var popup: PopupMenu = get_popup()
	if not is_instance_valid(popup):
		push_error("Failed to retrieve PopupMenu from MenuButton.")
		return
		
	popup.clear()
	_set_popup_style(popup)
	
	# Cleaned up item strings
	var pause_text: String = "▶  Resume" if get_tree().paused else "⏸  Pause"
	popup.add_item(pause_text, MENU_ID_PAUSE)
	popup.add_item("🔁  Retry", MENU_ID_RETRY)
	
	# === NEW: Chat button is now the 3rd item ===
	popup.add_item("💬  Chat", MENU_ID_CHAT)
	
	var bgm_text: String = "🔇  BGM Mute" if MusicManager.isMusicPlaying else "🔊  BGM Unmute"
	popup.add_item(bgm_text, MENU_ID_BGM)
	
	popup.add_item("🏠  Main Menu", MENU_ID_MAIN_MENU)
	popup.add_item("🚪  Quit", MENU_ID_QUIT)
	
	# Connect the signal for item selection
	popup.id_pressed.connect(_on_menu_option_selected)

func _on_menu_option_selected(id: int) -> void:
	match id:
		MENU_ID_PAUSE:
			MusicManager.play_button_click()
			if get_tree().paused:
				get_tree().paused = false
				get_popup().set_item_text(MENU_ID_PAUSE, "⏸  Pause")
			else:
				await get_tree().create_timer(0.15, true).timeout
				get_tree().paused = true
				get_popup().set_item_text(MENU_ID_PAUSE, "▶  Resume")
				
		MENU_ID_RETRY:
			MusicManager.play_button_click()
			get_tree().paused = false
			get_tree().reload_current_scene()
			
		MENU_ID_CHAT:  # <-- Chat logic
			MusicManager.play_button_click()
			_open_chat_overlay()
			
		MENU_ID_BGM:
			MusicManager.play_button_click()
			MusicManager.isMusicPlaying = !MusicManager.isMusicPlaying
			
			if MusicManager.isMusicPlaying:
				get_popup().set_item_text(MENU_ID_BGM, "🔇  BGM Mute")
				MusicManager.music.play()
			else:
				get_popup().set_item_text(MENU_ID_BGM, "🔊  BGM Unmute")
				MusicManager.music.stop()
				
		MENU_ID_MAIN_MENU:
			MusicManager.play_button_click()
			get_tree().paused = false
			if SceneManager.scenes.has("main_menu"):
				get_tree().change_scene_to_packed(SceneManager.scenes["main_menu"])
			else:
				push_error("Scene 'main_menu' not found in SceneManager!")
				
		MENU_ID_QUIT:
			MusicManager.play_button_click()
			get_tree().paused = false
			get_tree().quit()

func _open_chat_overlay() -> void:
	
	# 0. If not Global model Return
	if not Globals.is_online_mode:
		# Optionally show a message or do nothing
		print("Chat is only available in multiplayer mode.")
		return
	
	# 1. Preload the Chat scene
	const CHAT_SCENE = preload("res://Scenes/multiplayer_chat_ui.tscn")
	
	# 2. Check if chat is already open to prevent duplicates
	if get_tree().current_scene.get_node_or_null("ChatUI") != null:
		return
		
	# 3. Instantiate the chat
	var chat_instance = CHAT_SCENE.instantiate()
	chat_instance.name = "ChatUI"
	
	# 4. Add it to the current scene (on top of the paused game)
	get_tree().current_scene.add_child(chat_instance)

func _set_popup_style(popup: PopupMenu) -> void:
	var luxury_theme: Theme = Theme.new()
	
	# --- 1. Typography & Colors ---
	if ResourceLoader.exists("res://Fonts/YourCustomFont.tres"):
		var font: Font = load("res://Fonts/YourCustomFont.tres")
		luxury_theme.set_font("font", "PopupMenu", font)
		
	luxury_theme.set_color("font_color", "PopupMenu", Color(0.95, 0.95, 0.98))
	luxury_theme.set_color("font_hover_color", "PopupMenu", Color(1.0, 0.65, 0.0))
	luxury_theme.set_color("font_pressed_color", "PopupMenu", Color(0.6, 0.6, 0.6))
	
	luxury_theme.set_constant("v_separation", "PopupMenu", 12)
	
	# --- 2. Main Background Panel ---
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 0.93)
	panel_style.set_corner_radius_all(8)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_blend = true 
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.12)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0, 8)
	panel_style.set_content_margin(SIDE_LEFT, 16)
	panel_style.set_content_margin(SIDE_RIGHT, 16)
	panel_style.set_content_margin(SIDE_TOP, 12)
	panel_style.set_content_margin(SIDE_BOTTOM, 12)
	
	luxury_theme.set_stylebox("panel", "PopupMenu", panel_style)
	
	# --- 3. Hover Selection Style ---
	var hover_style: StyleBoxFlat = StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 0.65, 0.0, 0.07)
	hover_style.set_corner_radius_all(4)
	hover_style.border_width_left = 3
	hover_style.border_color = Color(1.0, 0.651, 0.0, 0.0)
	hover_style.set_content_margin(SIDE_LEFT, 12)
	hover_style.set_content_margin(SIDE_TOP, 6)
	hover_style.set_content_margin(SIDE_BOTTOM, 6)
	
	luxury_theme.set_stylebox("hover", "PopupMenu", hover_style)
	
	# --- 4. Safely Hide the Scrollbar ---
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	luxury_theme.set_stylebox("scroll", "VScrollBar", empty_style)
	luxury_theme.set_stylebox("scroll_focus", "VScrollBar", empty_style)
	luxury_theme.set_stylebox("grabber", "VScrollBar", empty_style)
	luxury_theme.set_stylebox("grabber_highlight", "VScrollBar", empty_style)
	luxury_theme.set_stylebox("grabber_pressed", "VScrollBar", empty_style)
	
	popup.theme = luxury_theme
