extends Control

@onready var item_sprite: TextureRect = $ItemSprite
@onready var item_name_label: Label = $ItemInfo/ItemName
@onready var item_price_label: Label = $ItemPrice/Text
@onready var buy_button: Button = $BuyButton

var current_item_data: ItemData

func setup(item_data: ItemData):
	current_item_data = item_data

	call_deferred("_assign_texture", item_data)

func _assign_texture(item_data: ItemData):

	item_sprite.texture = item_data.sprite_texture
	item_name_label.text = item_data.item_name
	item_price_label.text = str(item_data.price) + " coins"
	buy_button.pressed.connect(_on_buy_pressed)

	_update_button_state()
	
func _update_button_state():

	if current_item_data.item_name == Globals.equipped_item_name:
		buy_button.text = "EQUIPPED"
		buy_button.disabled = true

	elif current_item_data.item_name in Globals.owned_items:
		buy_button.text = "EQUIP"
		buy_button.disabled = false

	else:
		buy_button.text = "BUY (" + str(current_item_data.price) + ")"
		buy_button.disabled = false

func _on_buy_pressed():
	var item_name = current_item_data.item_name
	var price = current_item_data.price
	
	if item_name in Globals.owned_items:
		
		Globals.equipped_item_name = item_name
		Globals.save_inventory()
		Globals.weapon_equipped.emit(item_name)
		Globals.inventory_updated.emit()
		print("Equipped:", item_name)
		return
	
	if Globals.player_coins >= price:

		Globals.add_coins(-price)
		Globals.owned_items.append(item_name)
		Globals.equipped_item_name = item_name
		Globals.save_inventory()
		Globals.inventory_updated.emit()
		Globals.weapon_equipped.emit(item_name)

		print("Purchased and equipped: ", item_name)

		_update_button_state()
