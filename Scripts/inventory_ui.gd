extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var hotbar_slots: HBoxContainer = $InventoryBar/HotbarSlots
@onready var grid_container: GridContainer = $Panel/CenterContainer/VBoxContainer/GridContainer
@onready var close_button: Button = $Panel/CenterContainer/VBoxContainer/CloseButton

const HOTBAR_SIZE = 5
const INVENTORY_GRID_SIZE = 20

var player: CharacterBody2D
var inventory: Inventory
var is_open := false

# Slot scene
var slot_scene = preload("res://Scenes/inventory_slot.tscn")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Hide full inventory panel by default
	panel.visible = false
	
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)
	
	# Wait for player to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	if player and player.has_node("Inventory"):
		inventory = player.get_node("Inventory")
		
		# Connect signals
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)
		inventory.item_equipped.connect(_on_item_equipped)
		
		# Build UI
		_build_hotbar()
		_build_inventory_grid()
		_refresh_all_slots()

func _input(event):
	# Toggle inventory with 'I' key
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_I and event.pressed):
		toggle_inventory()
	
	# Hotbar number keys (1-5)
	for i in range(1, 6):
		var key_name = "hotbar_" + str(i)
		if event.is_action_pressed(key_name):
			_equip_from_hotbar(i - 1)

func toggle_inventory():
	is_open = !is_open
	panel.visible = is_open
	
	if is_open:
		get_tree().paused = true
		_refresh_all_slots()
	else:
		get_tree().paused = false

func _on_close_pressed():
	toggle_inventory()

func _build_hotbar():
	# Clear existing slots
	for child in hotbar_slots.get_children():
		child.queue_free()
	
	# Create 5 hotbar slots
	for i in range(HOTBAR_SIZE):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.is_hotbar = true
		slot.slot_clicked.connect(_on_slot_clicked)
		hotbar_slots.add_child(slot)

func _build_inventory_grid():
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	# Create inventory grid slots
	for i in range(INVENTORY_GRID_SIZE):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.is_hotbar = false
		slot.slot_clicked.connect(_on_slot_clicked)
		grid_container.add_child(slot)

func _refresh_all_slots():
	if not inventory:
		return
	
	var owned_items = inventory.get_all_items()
	var equipped_id = inventory.equipped_weapon_id
	
	# Clear all slots first
	for slot in hotbar_slots.get_children():
		slot.clear_slot()
	
	for slot in grid_container.get_children():
		slot.clear_slot()
	
	# Fill slots with owned items
	var slot_index = 0
	for item in owned_items:
		var slot = null
		
		# Put first 5 items in hotbar
		if slot_index < HOTBAR_SIZE:
			slot = hotbar_slots.get_child(slot_index)
		elif slot_index < INVENTORY_GRID_SIZE + HOTBAR_SIZE:
			slot = grid_container.get_child(slot_index - HOTBAR_SIZE)
		
		if slot:
			slot.set_item(item, item.item_id == equipped_id)
		
		slot_index += 1

func _on_slot_clicked(slot_index: int, is_hotbar_slot: bool):
	if not inventory:
		return
	
	var slot = null
	if is_hotbar_slot and slot_index < hotbar_slots.get_child_count():
		slot = hotbar_slots.get_child(slot_index)
	elif not is_hotbar_slot and slot_index < grid_container.get_child_count():
		slot = grid_container.get_child(slot_index)
	
	if slot and slot.current_item:
		inventory.equip_item(slot.current_item.item_id)
		_refresh_all_slots()

func _equip_from_hotbar(index: int):
	if index >= hotbar_slots.get_child_count():
		return
	
	var slot = hotbar_slots.get_child(index)
	if slot and slot.current_item:
		inventory.equip_item(slot.current_item.item_id)
		_refresh_all_slots()

func _on_item_added(_item: ItemData):
	_refresh_all_slots()

func _on_item_removed(_item: ItemData):
	_refresh_all_slots()

func _on_item_equipped(_item: ItemData):
	_refresh_all_slots()
