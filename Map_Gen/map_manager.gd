extends Node2D

# 2D Map Graph Generator
# Generates a graph of connected battle nodes for campaign progression

@export_group("Map Generation")
@export var map_size := DisplayServer.window_get_size()
@export var node_count := 20
@export var min_node_distance := 80.0
@export var max_connections_per_node := 3
@export var connection_distance_threshold := 200.0

@export_group("Visual Settings")
@export var node_radius := 15.0
@export var draw_connections := true
@export var draw_node_labels := true
@export var highlight_path := true


@export_group("Player Movement")
@export var player_sprite: Node2D  # Reference to your player_location scene

# Map data structures
var nodes: Array[MapNode] = []
var connections: Array[MapConnection] = []
var start_node: MapNode
var end_node: MapNode
var current_node: MapNode
var completed_nodes: Array[MapNode] = []

# Player movement state
var is_player_moving := false
var pending_battle_node: MapNode

# Visual colors
var NODE_COLORS = {
	"normal": Color.BLUE,
	"start": Color.GREEN,
	"end": Color.RED,
	"current": Color.YELLOW,
	"completed": Color.GRAY,
	"available": Color.CYAN
}

# Signals
signal selected_node(node: MapNode)

######### MANAGER CODE ########

func _ready():
	
	# Connect player movement signal if player sprite exists
	if player_sprite and player_sprite.has_signal("done_moving"):
		player_sprite.done_moving.connect(_on_player_movement_finished)
	
	# Position player at start node initially
	if start_node and player_sprite:
		if player_sprite.has_method("set_pos"):
			player_sprite.set_pos(start_node.position)

#func post_ready():
#	generate_map()

func _draw():
	draw_map()

func generate_map():
	"""Generate the complete map graph"""
	print("Generating map graph...")

	generate_nodes()
	connect_nearest_neighbors()
	identify_start_end_nodes()
	calculate_difficulty_progression()
	update_node_availability()
	
	print("Map generation complete. Nodes: %d, Connections: %d" % [nodes.size(), connections.size()])
	queue_redraw()

func generate_nodes():
	"""Generate randomly positioned nodes with minimum distance constraints"""
	nodes.clear()
	
	for i in range(node_count):
		var attempts = 0
		var max_attempts = 100
		var valid_position = false
		var new_position: Vector2
		
		while not valid_position and attempts < max_attempts:
			new_position = Vector2(
				randf_range(node_radius, map_size.x - node_radius),
				randf_range(node_radius, map_size.y - node_radius)
			)
			
			valid_position = true
			for existing_node in nodes:
				if new_position.distance_to(existing_node.position) < min_node_distance:
					valid_position = false
					break
			
			attempts += 1
		
		if valid_position:
			var node = MapNode.new(i, new_position)
			nodes.append(node)
		else:
			push_warning("Could not place node %d after %d attempts" % [i, max_attempts])

func connect_nearest_neighbors():
	"""Connect each node to its nearest neighbors"""
	connections.clear()
	
	for node in nodes:
		# Find nearest neighbors
		var distances: Array = []
		for other_node in nodes:
			if other_node != node:
				var distance = node.position.distance_to(other_node.position)
				if distance <= connection_distance_threshold:
					distances.append({"node": other_node, "distance": distance})
		
		# Sort by distance
		distances.sort_custom(func(a, b): return a.distance < b.distance)
		
		# Connect to closest neighbors (up to max_connections_per_node)
		var connections_made = 0
		for neighbor_data in distances:
			if connections_made >= max_connections_per_node:
				break
			
			var neighbor = neighbor_data.node
			
			# Check if connection already exists
			if not node_is_connected(node, neighbor):
				create_connection(node, neighbor)
				connections_made += 1

func node_is_connected(node1: MapNode, node2: MapNode) -> bool:
	"""Check if two nodes are already connected"""
	return node2 in node1.connections

func create_connection(node1: MapNode, node2: MapNode):
	"""Create a bidirectional connection between two nodes"""
	node1.connections.append(node2)
	node2.connections.append(node1)
	connections.append(MapConnection.new(node1, node2))

func identify_start_end_nodes():
	"""Find leftmost and rightmost nodes as start and end"""
	if nodes.size() == 0:
		return
	
	# Find leftmost node (start)
	start_node = nodes[0]
	for node in nodes:
		if node.position.x < start_node.position.x:
			start_node = node
	
	# Find rightmost node (end)
	end_node = nodes[0]
	for node in nodes:
		if node.position.x > end_node.position.x:
			end_node = node
	
	# Set node types
	start_node.node_type = "start"
	start_node.available = true
	current_node = start_node
	
	end_node.node_type = "end"

func calculate_difficulty_progression():
	"""Calculate difficulty and stage for each node based on distance from start"""
	if not start_node:
		return
	
	# Use breadth-first search to assign stages based on distance from start
	var visited: Array[MapNode] = []
	var queue: Array = [{"node": start_node, "stage": 1}]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var node: MapNode = current.node
		var stage: int = current.stage
		
		if node in visited:
			continue
		
		visited.append(node)
		node.stage = stage
		
		# Assign difficulty based on stage
		if stage <= 3:
			node.difficulty = "easy"
		elif stage <= 6:
			node.difficulty = "medium"
		else:
			node.difficulty = "hard"
		
		# Add connected nodes to queue
		for connected_node in node.connections:
			if connected_node not in visited:
				queue.append({"node": connected_node, "stage": stage + 1})

func update_node_availability():
	"""Update which nodes are available for selection"""
	for node in nodes:
		node.available = false
	
	# Start node is always available initially
	if start_node:
		start_node.available = true
	
	# Make nodes connected to completed nodes available
	for completed_node in completed_nodes:
		for connected_node in completed_node.connections:
			if not connected_node.completed:
				connected_node.available = true

# =============================================================================
# PLAYER MOVEMENT
# =============================================================================

func _on_player_movement_finished():
	"""Called when player finishes moving to a node"""
	is_player_moving = false
	
	if pending_battle_node:
		# Player has reached the node, now start the battle
		start_battle_at_node(pending_battle_node)
		pending_battle_node = null

func move_player_to_node(target_node: MapNode):
	"""Move player sprite to specified node"""
	if not player_sprite:
		push_warning("No player sprite assigned")
		return
	
	if not player_sprite.has_method("move_to"):
		push_warning("Player sprite missing move_to method")
		return
	
	is_player_moving = true
	player_sprite.move_to(target_node.position)

# =============================================================================
# BATTLE INTEGRATION
# =============================================================================

func start_battle_at_node(node: MapNode):
	"""Start a battle at the specified node using the enemy spawner"""
	if not node.available:
		push_warning("Attempted to start battle at unavailable node")
		return
	
	print("Starting battle at node %d (Stage: %d, Difficulty: %s)" % [node.id, node.stage, node.difficulty])
	current_node = node
	
	# Update visual
	queue_redraw()
	
	# Update other nodes
	selected_node.emit(node)

func complete_current_battle():
	"""Mark current battle as completed and update availability"""
	if not current_node:
		push_warning("No current battle to complete")
		return
	
	print("Battle completed at node %d" % current_node.id)
	
	current_node.completed = true
	completed_nodes.append(current_node)
	
	# Update node availability
	update_node_availability()
	
	current_node = null
	queue_redraw()


# =============================================================================
# VISUAL RENDERING
# =============================================================================

func draw_map():
	"""Draw the complete map graph"""
	if draw_connections:
		draw_connections_visual()
	
	draw_nodes_visual()
	
	if draw_node_labels:
		draw_node_labels_visual()

func draw_connections_visual():
	"""Draw lines between connected nodes"""
	for connection in connections:
		var color = Color.WHITE
		var width = 2.0
		
		# Highlight path to current node
		if highlight_path and current_node:
			if (connection.from_node.completed and connection.to_node == current_node) or \
			   (connection.to_node.completed and connection.from_node == current_node):
				color = Color.YELLOW
				width = 3.0
		
		draw_line(connection.from_node.position, connection.to_node.position, color, width)

func draw_nodes_visual():
	"""Draw all nodes with appropriate colors"""
	for node in nodes:
		var color = get_node_color(node)
		draw_circle(node.position, node_radius, color)
		
		# Draw border
		draw_arc(node.position, node_radius, 0, TAU, 32, Color.WHITE, 2.0)

func draw_node_labels_visual():
	"""Draw labels on nodes"""
	var font = ThemeDB.fallback_font
	var font_size = 12
	
	for node in nodes:
		var label = str(node.id)
		var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = node.position - text_size / 2
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func get_node_color(node: MapNode) -> Color:
	"""Get the appropriate color for a node based on its state"""
	if node.completed:
		return NODE_COLORS.completed
	elif node == current_node:
		return NODE_COLORS.current
	elif node.available:
		return NODE_COLORS.available
	elif node == start_node:
		return NODE_COLORS.start
	elif node == end_node:
		return NODE_COLORS.end
	else:
		return NODE_COLORS.normal

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_node_click(event.position)

func handle_node_click(click_position: Vector2):
	"""Handle clicking on nodes with player movement integration"""
	# Don't process clicks while player is moving
	if is_player_moving:
		return
	
	for node in nodes:
		if click_position.distance_to(node.position) <= node_radius:
			if node.available and not node.completed:
				# Check if player needs to move first
				if player_sprite and current_node != node:
					# Player needs to move to this node first
					pending_battle_node = node
					move_player_to_node(node)
				else:
					# Player is already at this node or no player sprite
					start_battle_at_node(node)
			else:
				print("Node %d is not available for battle" % node.id)
			break

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

func regenerate_map():
	"""Regenerate the entire map"""
	completed_nodes.clear()
	current_node = null
	generate_map()
	
	# Reposition player at start node
	if start_node and player_sprite:
		if player_sprite.has_method("set_pos"):
			player_sprite.set_pos(start_node.position)

func get_available_nodes() -> Array[MapNode]:
	"""Get all currently available nodes"""
	var available: Array[MapNode] = []
	for node in nodes:
		if node.available and not node.completed:
			available.append(node)
	return available

func get_map_progress() -> Dictionary:
	"""Get current map progress statistics"""
	return {
		"total_nodes": nodes.size(),
		"completed_nodes": completed_nodes.size(),
		"available_nodes": get_available_nodes().size(),
		"current_stage": current_node.stage if current_node else 0,
		"campaign_complete": end_node.completed if end_node else false
	}

func save_map_state() -> Dictionary:
	"""Save current map state for persistence"""
	var state = {
		"completed_node_ids": [],
		"current_node_id": current_node.id if current_node else -1
	}
	
	for node in completed_nodes:
		state.completed_node_ids.append(node.id)
	
	return state

func load_map_state(state: Dictionary):
	"""Load map state from saved data"""
	completed_nodes.clear()
	
	# Mark completed nodes
	for node_id in state.get("completed_node_ids", []):
		for node in nodes:
			if node.id == node_id:
				node.completed = true
				completed_nodes.append(node)
				break
	
	# Set current node
	var current_id = state.get("current_node_id", -1)
	current_node = null
	for node in nodes:
		if node.id == current_id:
			current_node = node
			break
	
	# Update availability and player position
	update_node_availability()
	
	if current_node and player_sprite:
		if player_sprite.has_method("set_pos"):
			player_sprite.set_pos(current_node.position)
	
	queue_redraw()
