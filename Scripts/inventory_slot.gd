extends PanelContainer

signal slot_clicked(slot_index: int, is_hotbar: bool)

@onready var item_texture: TextureRect = $MarginContainer/Content/ItemTexture
@onready var item_name_label: Label = $MarginContainer/Content/ItemName
@onready var equipped_indicator: Label = $MarginContainer/Content/EquippedIndicator
@onready var button: Button = $Button

var slot_index: int = 0
var is_hotbar: bool = false
var current_item: ItemData = null

func _ready():
	button.pressed.connect(_on_button_pressed)
	clear_slot()

func set_item(item: ItemData, is_equipped: bool = false):
	current_item = item
	
	if item and item.sprite_texture:
		item_texture.texture = item.sprite_texture
		item_name_label.text = item.item_name
		equipped_indicator.visible = is_equipped
	else:
		clear_slot()

func clear_slot():
	current_item = null
	item_texture.texture = null
	item_name_label.text = " "
	equipped_indicator.visible = false

func _on_button_pressed():
	slot_clicked.emit(slot_index, is_hotbar)