extends Node

func item_lookup(itemname : String) -> PackedScene:
	if itemname in name_obj_map:
		return name_obj_map[itemname]
	return null

const name_obj_map = {
	"four_melee" : preload("res://Units/unit_cards/four_melee/four_melee.tscn"),
}
