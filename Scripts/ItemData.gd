extends Resource
class_name ItemData

@export var item_name: String = ""
@export var category: String = ""      # "Sword", "Axe", "Hoe", etc.
@export var price: int = 0
@export var damage: int = 1            # <-- NEW: Damage stat!
@export var sprite_texture: Texture2D
