extends Resource
class_name ItemData

# These boxes will appear in the Inspector for every item you create
@export var item_name: String = ""
@export var category: String = ""      # "Sword", "Axe", "Hoe", etc.
@export var price: int = 0
@export var sprite_texture: Texture2D
