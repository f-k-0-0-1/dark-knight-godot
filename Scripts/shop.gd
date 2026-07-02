extends CanvasLayer

@onready var coin_label: Label = $Panel/CoinDisplayLabel
@onready var sprite: AnimatedSprite2D = $Panel/AnimatedSprite2D
@onready var item_grid: GridContainer  = $UI/Seperator/Bottom/HBox
@export var all_items: Array[ItemData] = []

func _ready():
	sprite.play("default")
	update_ui()
	load_items()
	load_category("Sword")
	
func load_items():
	# 1. Clear any old items out of the grid
	for child in item_grid.get_children():
		child.queue_free()
	
	# 2. Load the ShopItem scene we made in Part 3
	var item_scene = preload("res://Scenes/shop_item.tscn")
	
	# 3. Loop through the data and spawn a card for each one
	for item_data in all_items:
		var new_item_card = item_scene.instantiate()
		
		# Call the "setup" function we wrote in Part 3
		new_item_card.setup(item_data)
		
		# Add it to the grid
		item_grid.add_child(new_item_card)

func update_ui():
	coin_label.text = str(Globals.player_coins)
# Hide Shop Menu And Free Memory 
func _on_close_button_pressed() -> void:
	self.visible = false;
	queue_free();

func load_category(category_filter: String):
	# Clear grid
	for child in item_grid.get_children():
		child.queue_free()
	
	var item_scene = preload("res://Scenes/shop_item.tscn")
	
	# Loop through data and only spawn matching items
	for item_data in all_items:
		if item_data.category == category_filter:
			var new_item_card = item_scene.instantiate()
			new_item_card.setup(item_data)
			item_grid.add_child(new_item_card)
			await get_tree().create_timer(0.05).timeout # Tiny delay prevents lag


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
