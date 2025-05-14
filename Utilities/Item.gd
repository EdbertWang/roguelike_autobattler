extends Node
class_name Item

enum TYPE {
	spell_card,
	unit_card
}

# Can either be a spell or 1 stack of a unit

@export var item_name : String
@export var item_type : TYPE

func get_item_type() -> TYPE:
	return item_type
	
func get_item_name() -> String:
	return item_name
	
func on_select():
	match item_type:
		TYPE.spell_card:
			# Add this card to the player hotbar
			# Make sure to check if the player has space left in their hotbar
			return
		TYPE.unit_card:
			
			# Turn current seelcted unit into into its unit formation
			# Allow this formation to "stick" to cursor
			# Each time is clicked 
			return
