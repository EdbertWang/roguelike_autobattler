extends Node2D

@export var map_size : Vector2i
@export var tile_size : int
var tile_map_size : Vector2i 

@onready var unit_parent = $Unit_Parent
@onready var flow_gen = $FlowGen
@onready var target_man = $TargetManager
@onready var gui = $GUI

var enemies_tiles : Array[Array]
var allies_tiles : Array[Array]

# Triggers after both the manager and all its children have entered the scene
func _ready():
	# Initalize the 2D arrays for enemies and allies
	tile_map_size = map_size / tile_size
	for x in tile_map_size.x:
		allies_tiles.append([])
		enemies_tiles.append([])
		for y in tile_map_size.y:
			allies_tiles[x].append([])
			enemies_tiles[x].append([])
	
	#print("Global Ready")
	flow_gen.init_fields()
	gui.post_ready()
	for node in unit_parent.get_children():
		node.post_ready()


func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(pos / tile_size)

func grid_to_world(coord: Vector2i) -> Vector2:
	return coord * tile_size

func update_tiles():
	# Clear the allies and enemies tiles
	for x in tile_map_size.x:
		for y in tile_map_size.y:
			allies_tiles[x][y].clear()
			enemies_tiles[x][y].clear()
			
	for unit in unit_parent.get_children():
		# Convert position to tile position
		var tile = world_to_grid(unit.position)
		# If unit is an allied unit
		if unit.faction:
			allies_tiles[tile.x][tile.y].append(unit)
		else: # If unit is an enemy unit
			enemies_tiles[tile.x][tile.y].append(unit)
 
func add_unit_to_board(unit_ref : PackedScene) -> void:
	pass
	
func remove_unit_from_board(top_corner: Vector2, size: Vector2) -> void:
	var rect := Rect2(top_corner, size)
	for u in unit_parent.get_children():
		if rect.has_point(u.position):
			u.queue_free()


func _on_manager_update_timeout():
	update_tiles()
	
	# Calculate Border Tiles
	flow_gen.get_edge_positions(true)
	flow_gen.get_edge_positions(false)
	
	# Gen Flow
	flow_gen.calculate_flow_field(true)
	flow_gen.calculate_flow_field(false)
	
	# Reset targetting component
	target_man.reset_cache()
