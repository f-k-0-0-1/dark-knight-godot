extends Node

class_name Inventory

@export var max_slots: int = 20
var owned_items: Dictionary = {} # item_id -> ItemData
var equipped_weapon_id: String = "basic_sword"

signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal item_equipped(item: ItemData)

func _ready():
	load_inventory()

# Add item to inventory
func add_item(item: ItemData) -> bool:
	if owned_items.has(item.item_id):
		push_warning("Item already owned: " + item.item_name)
		return false
	
	if owned_items.size() >= max_slots:
		push_error("Inventory is full!")
		return false
	
	owned_items[item.item_id] = item
	item.is_owned = true
	item_added.emit(item)
	save_inventory()
	return true

# Remove item from inventory
func remove_item(item_id: String) -> bool:
	if not owned_items.has(item_id):
		return false
	
	var item = owned_items[item_id]
	
	# Unequip if equipped
	if item.is_equipped:
		unequip_item()
	
	owned_items.erase(item_id)
	item_removed.emit(item)
	save_inventory()
	return true

# Equip weapon
func equip_item(item_id: String) -> bool:
	if not owned_items.has(item_id):
		return false
	
	# Unequip current
	if equipped_weapon_id != "":
		if owned_items.has(equipped_weapon_id):
			owned_items[equipped_weapon_id].is_equipped = false
	
	# Equip new
	var item = owned_items[item_id]
	item.is_equipped = true
	equipped_weapon_id = item_id
	item_equipped.emit(item)
	save_inventory()
	return true

func unequip_item() -> void:
	if equipped_weapon_id != "" and owned_items.has(equipped_weapon_id):
		owned_items[equipped_weapon_id].is_equipped = false
	equipped_weapon_id = ""
	save_inventory()

func get_equipped_item() -> ItemData:
	if equipped_weapon_id != "" and owned_items.has(equipped_weapon_id):
		return owned_items[equipped_weapon_id]
	return null

func has_item(item_id: String) -> bool:
	return owned_items.has(item_id)

func get_all_items() -> Array:
	return owned_items.values()

# Save inventory to disk
func save_inventory():
	var config = ConfigFile.new()
	var file_path = "user://inventory.ini"
	
	config.set_value("inventory", "equipped_weapon", equipped_weapon_id)
	
	var owned_ids = []
	for item_id in owned_items.keys():
		owned_ids.append(item_id)
	
	config.set_value("inventory", "owned_items", owned_ids)
	config.save(file_path)

# Load inventory from disk
func load_inventory():
	var config = ConfigFile.new()
	var file_path = "user://inventory.ini"
	
	if config.load(file_path) != OK:
		# First time - give default sword
		equipped_weapon_id = "basic_sword"
		return
	
	equipped_weapon_id = config.get_value("inventory", "equipped_weapon", "basic_sword")
	var owned_ids = config.get_value("inventory", "owned_items", [])
	
	# This will be populated by the player when items are registered
	for item_id in owned_ids:
		# Items will be re-added when player initializes
		pass
