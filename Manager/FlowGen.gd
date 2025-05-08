extends Node

const DIRECTIONS = [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT
]


var friendly_flow = []
var enemy_flow = []
var friendly_border_tiles = []
var enemy_border_tiles = []

# Find all edges 
# Use the positions of the first units hit to create a border that we want to flow towards
# Calculate a flow field for the 10 tiles around this border

# Set up flow field size and fill then with zero vectors
func init_fields():
	var field_size = get_parent().tile_map_size
	for r in range(field_size.x):
		friendly_flow.append([])
		enemy_flow.append([])
		for c in range(field_size.y):  
			friendly_flow[r].append(Vector2.ZERO)
			enemy_flow[r].append(Vector2.ZERO)
			

func get_edge_positions(faction : bool) -> void:
	var matrix
	var border_tiles
	if faction:
		matrix = get_parent().allies_tiles
		border_tiles = friendly_border_tiles
	else:
		matrix = get_parent().enemies_tiles
		border_tiles = enemy_border_tiles
		
	
	var rows = get_parent().tile_map_size.x
	var cols = get_parent().tile_map_size.y
	border_tiles.clear()

	for r in range(rows):
		for c in range(cols):
			if matrix[r][c].size() > 0:
				var edge_tile = false
				# Check 4-directional neighbors
				for dir in DIRECTIONS:
					var nr = r + dir.x
					var nc = c + dir.y
					# Check if this tile is one edge of map
					if nr < 0 or nr >= rows or nc < 0 or nc >= cols or matrix[nr][nc].is_empty():
						edge_tile = true
						break  # Guarenteed to be edge if on edge of map
						# Or if near empty tile 
				
				if edge_tile:
					border_tiles.append(Vector2(r, c))


func calculate_flow_field(faction : bool) -> void:
	
	# Determine which faction this flow is for
	var curr_flow_field
	var border_tiles
	if faction:
		curr_flow_field = friendly_flow
		border_tiles = friendly_border_tiles
	else:
		curr_flow_field = enemy_flow
		border_tiles = enemy_border_tiles

	var rows = get_parent().tile_map_size.x
	var cols = get_parent().tile_map_size.y

	# For each valid tile, create a flow to the closest border tile
	for r in range(rows):
		for c in range(cols):
			var min_dist : int = rows * rows + cols * cols + 1 # Set to max distance
			var min_border = null
			# Search through the borders to find the closest one
			for border in border_tiles:
				if r == border.x and c == border.y: # Do not set flow for border tiles
					min_border = null
					break
				if (border - Vector2(r,c)).length_squared() < min_dist:
					min_border = border
					min_dist = int(border.x - r) ^ 2 + int(border.y - c) ^ 2
			
			# At this flow tile, store the best vector to get to the target
			if min_border != null:
				curr_flow_field[r][c] =  min_border - Vector2(r,c)

			else:
				curr_flow_field[r][c] = Vector2.ZERO
			
			
func get_flow(faction : bool, position : Vector2) -> Vector2:
	var target_location = get_parent().world_to_grid(position)
	
	# Check if we have already seen this location
	if faction:
		return friendly_flow[target_location.x][target_location.y]
	else:
		return enemy_flow[target_location.x][target_location.y]
