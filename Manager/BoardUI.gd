extends Node2D

@onready var unit_board : TileMap = $UnitBoard
@onready var spell_bar : HBoxContainer = $SpellBar

@export var unit_board_height : int
@export var unit_board_width : int

var unit_board_space_map : Array[Array] # Store reference to unit at this tile

var curr_unit : PackedScene
var curr_mouse_tile : Vector2

var placement_mode : bool # True for placing, false for removing

var battle_manager

func ready():	
	# Create an fully empty grid
	for i in unit_board_width:
		unit_board_space_map.append([])
		for j in unit_board_height:
			unit_board_space_map[i].append(null)
			

func check_unit_space_availability(top_corner : Vector2, size : Vector2) -> bool:
	for x in size.x:
		for y in size.y:
			if unit_board_space_map[top_corner.x + x][top_corner.y + y] == null:
				return false
	return true
	
func place_on_board(top_corner : Vector2, size : Vector2, unit_ref : PackedScene) -> void:
	for x in size.x:
		for y in size.y:
			unit_board_space_map[top_corner.x + x][top_corner.y + y] = unit_ref
	
	# Signal up to the board manager to spawn these units at the current position
	battle_manager.add_unit_to_board(unit_ref)


func get_unit_at_tile(curr_tile : Vector2) -> PackedScene:
	return unit_board_space_map[curr_tile.x][curr_tile.y]

func remove_from_board(top_corner : Vector2, size : Vector2) -> void:
	for x in size.x:
		for y in size.y:
			unit_board_space_map[top_corner.x + x][top_corner.y + y] = null
	
	# Signal up to board manager to despawn these units
	battle_manager.remove_unit_from_board(top_corner, size)


func checkCell():
	# Step 1: Get the mouse position in the viewport
	var mouse_tile = get_viewport().get_mouse_position()
	
	# Step 2: Convert mouse position to the TileMap's grid position
	curr_mouse_tile = unit_board.local_to_map(mouse_tile)
	
	# Step 3: Convert the grid position back to a local coordinate
	var co = unit_board.map_to_local(curr_mouse_tile)


# Continuously check cell under the mouse
func _process(delta: float) -> void:
	checkCell()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if placement_mode: # Add unit to tile
			if curr_unit != null and check_unit_space_availability(curr_mouse_tile, curr_unit.placement_size):
				place_on_board(curr_mouse_tile, curr_unit.placement_size, curr_unit)
		else: # Remove this unit from the tile
			var removed_unit = get_unit_at_tile(curr_mouse_tile)
			if removed_unit != null:
				remove_from_board(curr_mouse_tile, removed_unit.placement_size)
			

func post_ready():
	battle_manager = get_tree().get_nodes_in_group("BATTLEMANAGER")[0]

# https://archive.is/20250217054951/https://medium.com/godot-dev-digest/grid-based-placement-in-godot-be2231554d09#selection-661.0-701.15
