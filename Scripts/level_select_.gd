extends Control

@onready var back_button: Button = $BackButton

@onready var level1: TextureButton = $GridContainer/level1
@onready var level2: TextureButton = $GridContainer/level2
@onready var level3: TextureButton = $GridContainer/level3
@onready var level4: TextureButton = $GridContainer/level4
@onready var level5: TextureButton = $GridContainer/level5
@onready var level6: TextureButton = $GridContainer/level6
@onready var level7: TextureButton = $GridContainer/level7
@onready var level8: TextureButton = $GridContainer/level8
@onready var level9: TextureButton = $GridContainer/level9
@onready var level10: TextureButton = $GridContainer/level10
@onready var shop_button: TextureButton = $ShopButton;


func _ready():
	# Back button
	back_button.pressed.connect(_on_back_pressed)

	# Playable levels
	level1.pressed.connect(_on_level1_pressed)
	level2.pressed.connect(_on_level2_pressed)
	level3.pressed.connect(_on_level3_pressed)
	shop_button.pressed.connect(_on_shopButton_pressed);

	# Locked levels
	level4.disabled = true
	level5.disabled = true
	level6.disabled = true
	level7.disabled = true
	level8.disabled = true
	level9.disabled = true
	level10.disabled = true


func _on_back_pressed():
	MusicManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	SceneManager.change_scene("main_menu")


func _on_level1_pressed():
	MusicManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	SceneManager.change_scene("level_1")


func _on_level2_pressed():
	MusicManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	SceneManager.change_scene("level_2")

func _on_level3_pressed():
	MusicManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	SceneManager.change_scene("level_3")
	
func _on_shopButton_pressed() -> void:
	var shop_menu: CanvasLayer = SceneManager.get_scene("shop_menu").instantiate();
	self.add_child(shop_menu);
	
