extends CanvasLayer

@onready var coin_label: Label = $Coin/CoinDisplayLabel
@onready var sprite: AnimatedSprite2D = $Coin/Texture
@onready var item_grid: GridContainer  = $UI/Seperator/Bottom/HBox
@export var all_items: Array[ItemData] = []

var current_category: String = "sword"

func _ready():
	sprite.play("default")
	
	Globals.coins_updated.connect(update_ui)
	Globals.inventory_updated.connect(_refresh_shop)
	
	update_ui(Globals.player_coins)
	remove_items();
	load_category("sword")
	
func _refresh_shop():
	load_category(current_category)
	
func remove_items():
	for child in item_grid.get_children():
		child.queue_free()

func update_ui(new_total: int):
	coin_label.text = str(new_total);

# Hide Shop Menu And Free Memory 
func _on_close_button_pressed() -> void:
	self.visible = false;
	queue_free();

func load_category(category_filter: String):
	current_category = category_filter
	# Clear grid
	remove_items();
	
	# Sami ~ Load the scenes
	var item_scene = preload("res://Scenes/Shop_item.tscn")
	var bg_scene = preload("uid://btthfvjd8d7bn");
	
	# Loop through data and only spawn matching items
	for item_data in all_items:
		if item_data.category == category_filter:
			
			# Sami ~ Init both bg and itme 
			var bg_init: Node = bg_scene.instantiate();
			var item_init: Node = item_scene.instantiate();
			
			# Sami ~ Then add bg to grid
			item_grid.add_child(bg_init);
			
			# Sami ~ Then add item to bg
			bg_init.add_child(item_init);
			
			# Sami Then add data
			item_init.setup(item_data);
			
			 # Tiny delay prevents lag
			await get_tree().create_timer(0.05).timeout


func _on_swords_pressed() -> void:
	load_category("sword")


func _on_axe_pressed() -> void:
	load_category("axe")


func _on_hoe_pressed() -> void:
	load_category("hoe")


func _on_pick_axe_pressed() -> void:
	load_category("pick axe")


func _on_shovel_pressed() -> void:
	load_category("shovel")
