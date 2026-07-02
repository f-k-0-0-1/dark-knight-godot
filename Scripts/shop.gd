extends CanvasLayer

@onready var coin_label: Label = $Coin/CoinDisplayLabel
@onready var sprite: AnimatedSprite2D = $Coin/Texture
@onready var item_grid: GridContainer  = $UI/Seperator/Bottom/HBox
@export var all_items: Array[ItemData] = []

func _ready():
	sprite.play("default")
	update_ui()
	remove_items();
	load_category("Sword")
	
func remove_items():
	for child in item_grid.get_children():
		child.queue_free()

func update_ui():
	coin_label.text = str(Globals.player_coins);

# Hide Shop Menu And Free Memory 
func _on_close_button_pressed() -> void:
	self.visible = false;
	queue_free();

func load_category(category_filter: String):
	
	# Clear grid
	remove_items();
	
	# Sami ~ Load the scenes
	var item_scene = preload("res://Scenes/Shop_item.tscn")
	var bg_scene = preload("uid://btthfvjd8d7bn");
	
	# Loop through data and only spawn matching items
	for item_data in all_items:
		if item_data.category == category_filter:
			
			# Sami ~ Init both bg and item
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
