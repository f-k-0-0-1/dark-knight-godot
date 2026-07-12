extends Node

# === GLOBALS COMMAND SYSTEM ===
var MAX_ARG_SIZE: int = 3
var MIN_ARG_SIZE: int = 2
var TELE_DIS: float = 1200.00
var PLAYER_TRANS_START: Vector2 = Vector2(0, 0)
var commandsInfo: String = """
\nHere are Some Useful Commands\n
1. Help -l  -> For Sinlge Line Help Commands\n
2. Help -m  -> For Multi Line Help Commands\n 
3. teleport -s -> Teleport to Start\n
4. teleport -e -> Teleport to End\n
5. level -b -> Bypass Level Behind\n
6. level -n -> Bypass to Next Level\n
7. clear -all ->  To Clear The Commands & Error Logs\n
8. shop  - (use '-' for no args) -> To Open Shop Menu\n
9. chat -s -> Add Server Ip\n
10 chat -m -> Send Message \n
"""

# === CURRENCY SYSTEM ===
var player_coins: int = 0
signal coins_updated(new_total: int)

var level_coins: int = 0
signal level_coins_updated(new_total: int)

# === PLAYER INVENTORY ===
var owned_items: Array = []          # Stores the names of bought items (e.g. "Iron Sword")
var equipped_item_name: String = ""   # The name of the currently equipped weapon

# === DATA SYSTEM (Required for Weapon Manager) ===
# This stores the list of all items from the Shop so we can search them
var global_item_list: Array[ItemData] = [
	preload("res://ShopItems/Sword/Diamond_Sword.tres"),
	preload("res://ShopItems/Sword/Gold_Sword.tres"),
	preload("res://ShopItems/Sword/Iron_Sword.tres"),
	preload("res://ShopItems/Sword/Netherite_Sword.tres"),
	preload("res://ShopItems/Sword/Stone_Sword.tres"),
	preload("res://ShopItems/Sword/Wooden_Sword.tres"),
	preload("res://ShopItems/Shovel/Diamond_Shovel.tres"),
	preload("res://ShopItems/Shovel/Gold_Shovel.tres"),
	preload("res://ShopItems/Shovel/Iron_Shovel.tres"),
	preload("res://ShopItems/Shovel/Netherite_Shovel.tres"),
	preload("res://ShopItems/Shovel/Stone_Shovel.tres"),
	preload("res://ShopItems/Shovel/Wooden_Shovel.tres"),
	preload("res://ShopItems/PickAxe/Diamond_PickAxe.tres"),
	preload("res://ShopItems/PickAxe/Gold_PickAxe.tres"),
	preload("res://ShopItems/PickAxe/Iron_PickAxe.tres"),
	preload("res://ShopItems/PickAxe/Netherite_PickAxe.tres"),
	preload("res://ShopItems/PickAxe/Stone_PickAxe.tres"),
	preload("res://ShopItems/PickAxe/Wooden_PickAxe.tres"),
	preload("res://ShopItems/Hoe/Diamond_Hoe.tres"),
	preload("res://ShopItems/Hoe/Gold_Hoe.tres"),
	preload("res://ShopItems/Hoe/Iron_Hoe.tres"),
	preload("res://ShopItems/Hoe/Netherite_Hoe.tres"),
	preload("res://ShopItems/Hoe/Stone_Hoe.tres"),
	preload("res://ShopItems/Hoe/Wooden_Hoe.tres"),
	preload("res://ShopItems/Axe/Diamond_Axe.tres"),
	preload("res://ShopItems/Axe/Gold_Axe.tres"),
	preload("res://ShopItems/Axe/Iron_Axe.tres"),
	preload("res://ShopItems/Axe/Netherite_Axe.tres"),
	preload("res://ShopItems/Axe/Stone_Axe.tres"),
	preload("res://ShopItems/Axe/Wooden_Axe.tres")
]

# === UPDATED SIGNALS ===
@warning_ignore("unused_signal")
signal inventory_updated
signal weapon_equipped(item_data: ItemData) 


func _ready() -> void:
	load_coins()
	load_inventory()
	
	# === AUTO-EQUIP ON LOAD ===
	# If the player closed the game with a weapon equipped, we auto-equip it on startup.
	if equipped_item_name != "":
		var saved_item = get_item_data_by_name(equipped_item_name)
		if saved_item != null:
			weapon_equipped.emit(saved_item)
			print("Auto-equipped saved weapon: ", equipped_item_name)
		else:
			print("Saved equipment not found: ", equipped_item_name)

# =====================
# COIN FUNCTIONS
# =====================

func add_level_coin():
	level_coins += 1
	level_coins_updated.emit(level_coins)
	
	player_coins += 1
	coins_updated.emit(player_coins)
	save_coins()

func reset_level_coins():
	level_coins = 0
	level_coins_updated.emit(level_coins)

func add_coins(amount: int):
	player_coins += amount
	coins_updated.emit(player_coins)
	save_coins()

func save_coins():
	var config = ConfigFile.new()
	var file_path = "user://save_data.ini"
	
	config.load(file_path)
	config.set_value("player_data", "coins", player_coins)
	config.save(file_path)

func load_coins():
	var config = ConfigFile.new()
	var file_path = "user://save_data.ini"
	
	if config.load(file_path) == OK:
		player_coins = config.get_value("player_data", "coins", 0)
	else:
		player_coins = 0
	coins_updated.emit(player_coins)

# =====================
# INVENTORY FUNCTIONS
# =====================

func save_inventory():
	var config = ConfigFile.new()
	var file_path = "user://inventory_data.ini"
	
	config.load(file_path)
	
	var items_string = ";".join(owned_items)
	config.set_value("inventory", "owned_items", items_string)
	config.set_value("inventory", "equipped", equipped_item_name)
	
	config.save(file_path)
	print("Inventory Saved. Equipped: ", equipped_item_name)

func load_inventory():
	var config = ConfigFile.new()
	var file_path = "user://inventory_data.ini"
	
	if config.load(file_path) == OK:
		var items_string = config.get_value("inventory", "owned_items", "")
		if items_string != "":
			owned_items = items_string.split(";")
		else:
			owned_items = []
		
		equipped_item_name = config.get_value("inventory", "equipped", "")

# =====================
# ITEM DATA HELPER
# =====================

func set_global_item_list(items: Array[ItemData]):
	global_item_list = items
	print("Global Item List updated with ", items.size(), " items.")

func get_item_data_by_name(item_name: String) -> ItemData:
	for item in global_item_list:
		if item.item_name == item_name:
			return item
	return null
