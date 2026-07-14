extends Resource
class_name ItemData

@export var item_name: String = ""
@export var category: String = ""      # "Sword", "Axe", "Hoe", etc.
@export var price: int = 0
@export var damage: int = 1
@export var dictionary_key: String = "" # <-- Exact key for WeaponManager lookup
@export var sprite_texture: Texture2D

# REMOVED: func _init() -> void: ...
