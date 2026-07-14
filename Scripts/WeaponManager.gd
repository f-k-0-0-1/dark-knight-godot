extends Node

var weapon_textures: Dictionary = {
	"Wood_Sword": preload("res://Assets/Weapons/Wooden sword-1.png.png"),
	"Stone_Sword": preload("res://Assets/Weapons/Stone sword-1.png.png"),
	"Iron_Sword": preload("res://Assets/Weapons/Iron Sword-1.png.png"),
	"Gold_Sword": preload("res://Assets/Weapons/Gold Sword-1.png.png"),
	"Diamond_Sword": preload("res://Assets/Weapons/Diamond Sword-1.png (1).png"),
	"Netherite_Sword": preload("res://Assets/Weapons/Netherite Sword-1.png.png"),
	"Wood_Axe": preload("res://Assets/Weapons/Wooden Axe-1.png.png"),
	"Stone_Axe": preload("res://Assets/Weapons/Stone axe-1.png.png"),
	"Iron_Axe": preload("res://Assets/Weapons/Iron Axe-1.png.png"),
	"Gold_Axe": preload("res://Assets/Weapons/Gold Axe-1.png.png"),
	"Diamond_Axe": preload("res://Assets/Weapons/Diamond Axe-1.png.png"),
	"Netherite_Axe": preload("res://Assets/Weapons/Netherite Axe-1.png.png"),
	"Wood_Hoe": preload("res://Assets/Weapons/Wooden Hoe-1.png.png"),
	"Stone_Hoe": preload("res://Assets/Weapons/Stone hoe-1.png.png"),
	"Iron_Hoe": preload("res://Assets/Weapons/Iron Hoe-1.png.png"),
	"Gold_Hoe": preload("res://Assets/Weapons/Gold Hoe-1.png.png"),
	"Diamond_Hoe": preload("res://Assets/Weapons/Diamond Hoe-1.png.png"),
	"Netherite_Hoe": preload("res://Assets/Weapons/Netherite Hoe-1.png.png"),
	"Wood_PickAxe": preload("res://Assets/Weapons/Wooden Pickaxe-1.png.png"),
	"Stone_PickAxe": preload("res://Assets/Weapons/Stone Pickaxe-1.png.png"),
	"Iron_PickAxe": preload("res://Assets/Weapons/Iron pickaxe-1.png.png"),
	"Gold_PickAxe": preload("res://Assets/Weapons/Gold Pickaxe-1.png.png"),
	"Diamond_PickAxe": preload("res://Assets/Weapons/Diamond Pickaxe-1.png.png"),
	"Netherite_PickAxe": preload("res://Assets/Weapons/Netherite Pickaxe-1.png.png"),
	"Wood_Shovel": preload("res://Assets/Weapons/Wooden Shovel-1.png.png"),
	"Stone_Shovel": preload("res://Assets/Weapons/Stone shovel-1.png.png"),
	"Iron_Shovel": preload("res://Assets/Weapons/Iron Shovel-1.png (1).png"),
	"Gold_Shovel": preload("res://Assets/Weapons/Gold Shovel-1.png.png"),
	"Diamond_Shovel": preload("res://Assets/Weapons/Diamond Shovel-1.png (1).png"),
	"Netherite_Shovel": preload("res://Assets/Weapons/Netherite Shovel-1.png.png")
}

func get_weapon_texture(material: String, category: String) -> Texture2D:
	var key: String = material.strip_edges() + "_" + category.strip_edges()
	if weapon_textures.has(key):
		return weapon_textures[key]
	else:
		push_error("WeaponManager: Missing texture for key: " + key)
		return null

# === NEW: Direct key lookup to replace brittle string parsing ===
func get_weapon_texture_by_key(key: String) -> Texture2D:
	if weapon_textures.has(key):
		return weapon_textures[key]
	else:
		push_error("WeaponManager: Missing texture for key: " + key)
		return null
