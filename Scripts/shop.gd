extends CanvasLayer

@onready var coin_label: Label = $Coin/CoinDisplayLabel
@onready var sprite: AnimatedSprite2D = $Coin/Texture
@onready var item_grid: GridContainer  = $UI/Seperator/Bottom/HBox

var shop_items: Array[ItemData] = [
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

var current_category: String = "sword"
var item_scene = preload("res://Scenes/Shop_item.tscn")
var bg_scene = preload("res://Scenes/Shop_item_bg.tscn")

func _ready():
	sprite.play("default")
	
	Globals.coins_updated.connect(update_ui)
	Globals.inventory_updated.connect(_refresh_shop)
	
	# Wait 1 frame for scene initialization
	await get_tree().process_frame
		
	Globals.set_global_item_list(shop_items)
	
	update_ui(Globals.player_coins)
	remove_items()
	load_category("sword")
	
func _refresh_shop():
	load_category(current_category)
	
func remove_items():
	for child in item_grid.get_children():
		child.queue_free()
	await get_tree().process_frame

func update_ui(new_total: int):
	coin_label.text = str(new_total)

# Hide Shop Menu And Free Memory 
func _on_close_button_pressed() -> void:
	self.visible = false
	queue_free()

func load_category(category_filter: String):
	current_category = category_filter
	await remove_items()
	for item_data in shop_items:
		if item_data.category == category_filter:
			# Create the background
			var bg_init = bg_scene.instantiate()
			item_grid.add_child(bg_init)
			
			# Create the item card
			var item_init = item_scene.instantiate()
			bg_init.add_child(item_init)
			item_init.setup(item_data)
			
			await get_tree().create_timer(0.05).timeout


func _on_swords_pressed() -> void:
	load_category("sword")


func _on_axe_pressed() -> void:
	load_category("axe")


func _on_hoe_pressed() -> void:
	load_category("hoe")


func _on_pick_axe_pressed() -> void:
	load_category("pickaxe")


func _on_shovel_pressed() -> void:
	load_category("shovel")
