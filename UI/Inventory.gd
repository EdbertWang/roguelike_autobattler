extends Control

class_name Inventory

var slots : Array[InventorySlot]

@onready var inventory_grid : GridContainer = $InventoryGrid
@export var starter_items : Array[Item]
@export var starter_items_count : Array[int]
@export var columns : int
@export var rows : int

@export var slot_autoload : PackedScene 

var can_open_inventory = true

func _ready():
	toggle_window(false)
	
	inventory_grid.columns = columns

	for i in columns * rows:
		var new_slot = slot_autoload.instantiate()
		slots.append(new_slot)
		new_slot.set_item(null, 0)
		new_slot.inventory = self
		inventory_grid.add_child(new_slot)

func post_ready():
	for i in starter_items.size():
		add_item(starter_items[i],starter_items_count[i] )

func _process (delta):
	# TODO: Check if we are in placement mode before allowing this
	if Input.is_action_just_pressed("inventory") and can_open_inventory:
		toggle_window(!visible)

func toggle_window (open : bool):
	visible = open
  
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func on_give_player_item (item : Item, amount : int):
	pass

func add_item (item : Item, count : int):
	var slot = get_slot_to_add(item)
  
	if slot == null:
		return
  
	if slot.item == null:
		slot.set_item(item, count)
	elif slot.item == item:
		slot.add_item(count)

func remove_item (item : Item, count: int) -> bool:
	var slot = get_slot_to_remove(item)
  
	if slot == null or slot.item == item or slot.quantity < count:
		return false
  
	slot.remove_item(count)
	return true

func get_slot_to_add (item : Item) -> InventorySlot:
	for slot in slots:
		if slot.item == item and slot.quantity < item.max_stack_size:
			return slot
  
	for slot in slots:
		if slot.item == null:
			return slot
  
	return null

func get_slot_to_remove (item : Item) -> InventorySlot:
	for slot in slots:
		if slot.item == item:
			return slot
  
	return null

func get_number_of_item (item : Item) -> int:
	var total = 0
  
	for slot in slots:
		if slot.item == item:
			total += slot.quantity
  
	return total
