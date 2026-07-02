extends Control

@onready var item_sprite: TextureRect = $ItemSprite
@onready var item_name_label: Label = $ItemName
@onready var item_price_label: Label = $ItemPrice
@onready var buy_button: Button = $BuyButton

var current_item_data: ItemData

func setup(item_data: ItemData):
	current_item_data = item_data
	
	# === THE ULTIMATE SAFE FIX ===
	# Use call_deferred to assign the texture on the next frame safely.
	call_deferred("_assign_texture", item_data)

func _assign_texture(item_data: ItemData):
	# This function runs safely 1 frame later, when the node is 100% alive.
	item_sprite.texture = item_data.sprite_texture
	item_name_label.text = item_data.item_name
	item_price_label.text = str(item_data.price) + " coins"
	
	buy_button.pressed.connect(_on_buy_pressed)

func _on_buy_pressed():
	print("Attempting to buy: ", current_item_data.item_name)
