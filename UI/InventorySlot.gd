extends Button
class_name InventorySlot

var item : Item
var quantity : int
@onready var button_icon : TextureRect = $TextureRect
@onready var quantity_text : Label = $Label
var inventory : Inventory

func set_item (new_item : Item, count : int):
	if new_item == null:
		#button_icon.visible = false
		return
		
	button_icon.visible = true
	item = new_item
	quantity = count
  
	update_quantity_text()

func add_item(count : int):
	quantity += count
	update_quantity_text()

func remove_item(count : int):
	quantity -= count
	if quantity <= 0:
		set_item(null,0)
		return
		
	update_quantity_text()
  
func update_quantity_text ():
	if quantity <= 1:
		quantity_text.text = ""
	else:
		quantity_text.text = str(quantity)


func _on_pressed() -> Item:
	if item == null:
		return
  
	var remove_after_use = item.on_select()
  
	if remove_after_use:
		remove_item(1)
	
	# Return the item
	return item
