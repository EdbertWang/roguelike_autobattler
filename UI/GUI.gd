extends Control
@onready var post_ready_check = false

#### DEBUG VARS
@export var selector_rect_debug : bool = true
var selector_rect : Rect2

var bm
var inventory : Inventory
var unit_board : GridContainer
@onready var spell_bar : GridContainer = $SpellBar

var unit_board_height : int
var unit_board_width : int

var unit_board_space_map : Array[Array] = [] # Stores references to units on the board

# Store these state variables in globals since they are required by the input events
var targetCell
var objectCells = []
var curr_unit : PackedScene
var curr_unit_inst : Item
var curr_inv_slot : InventorySlot
var curr_mouse_tile : Vector2
var isValid = false
var placement_mode : bool = true # True for placing, false for removing
var rotated_placement : bool = false

func post_ready():
	bm = get_parent()
	inventory = get_node("Inventory")
	unit_board = bm.get_node("BoardUI")
	unit_board_height = unit_board.height
	unit_board_width = unit_board.width
	
	# Initialize empty grid
	for i in unit_board_width:
		unit_board_space_map.append([])
		for j in unit_board_height:
			unit_board_space_map[i].append(null)
	
	post_ready_check = true
	
	# Propagate downwards
	for i in get_children():
		if i.has_method("post_ready"):
			i.post_ready()

func _draw():
	if selector_rect_debug:
		draw_rect(selector_rect, Color.RED, false)

func _process(delta):
	check_cell()
	queue_redraw()


func _input(event: InputEvent):
	if Input.is_action_just_pressed("leftClick"):
		if placement_mode:
			if curr_unit and isValid:
				_place_unit()
		else:
			# TODO: Get starting position of the unit, and its rotation state
			var removed_unit = get_unit_at_tile(curr_mouse_tile)
			if removed_unit:
				# TODO : Determine if the removed unit was rotated, then remove the rotated version
				remove_from_board(curr_mouse_tile, removed_unit.placement_size)
	elif Input.is_action_just_pressed("rotatePlacement"):
		rotated_placement = !rotated_placement
		
		# Force cell check to be recomputed
		targetCell = null
		check_cell()
		

func check_cell():
	# Potentially might need to change to work with moving and scaling camera
	# var eventPosition = get_viewport().canvas_transform.affine_inverse().xform(event.position)
	
	var mouse_pos = get_viewport().get_mouse_position()
	curr_mouse_tile = mouse_pos / Vector2(unit_board.cellWidth, unit_board.cellHeight)
	
	var new_target = _get_target_cell(mouse_pos)
	if new_target and new_target != targetCell:
		targetCell = new_target
		if curr_unit_inst:
			curr_unit_inst.global_position = targetCell.global_position + curr_unit_inst.texture.get_size() * curr_unit_inst.scale / 2
			if objectCells.size() > 0:
				_reset_highlight(objectCells)
			objectCells = _get_object_cells()
			isValid = _check_and_highlight_cells(objectCells)

func _get_target_cell(mouse_pos):
	for cell: Control in unit_board.get_children():
		if cell.get_global_rect().has_point(mouse_pos):
			return cell
	return null

func _reset_highlight(cells : Array):
	for cell: Control in cells:
		cell.change_color(Color(0.5, 0.5, 0.5, 0.5))

func _get_object_cells() -> Array:
	var cells = []
	# Size the rectangle to be a bit smaller than 
	var unit_rect : Rect2
	if rotated_placement:
		unit_rect = Rect2(curr_unit_inst.global_position - Vector2(unit_board.cellWidth / 2, unit_board.cellHeight / 2), \
		curr_unit_inst.rotated_placement_size * Vector2(unit_board.cellWidth, unit_board.cellHeight) - Vector2(unit_board.cellWidth / 2, unit_board.cellHeight / 2))
	else:
		unit_rect = Rect2(curr_unit_inst.global_position - Vector2(unit_board.cellWidth / 2, unit_board.cellHeight / 2), \
		curr_unit_inst.placement_size * Vector2(unit_board.cellWidth, unit_board.cellHeight) - Vector2(unit_board.cellWidth / 2, unit_board.cellHeight / 2))
		
	# Store for debugging
	if selector_rect_debug:
		selector_rect = unit_rect
		
	for cell: Control in unit_board.get_children():
		if cell.get_global_rect().intersects(unit_rect):
			cells.append(cell)
	return cells

func _check_and_highlight_cells(cells: Array) -> bool:
	var valid = true

	# cell count check - prevents placing units on the edges of the board
	var expected_count = int(curr_unit_inst.placement_size.x) * int(curr_unit_inst.placement_size.y)
	if expected_count != cells.size():
		valid = false

	for cell in cells:
		if cell.full:
			cell.change_color(Color.RED)
			valid = false
		else:
			cell.change_color(Color.GREEN)

	return valid

func _place_unit():
	for cell in objectCells:
		cell.full = true
	
	var grid_pos : Vector2 = objectCells[0].board_position

	if rotated_placement:
		place_on_board(grid_pos, curr_unit_inst.rotated_placement_size, curr_unit)
		bm.add_unit_to_board(curr_unit_inst, objectCells[0].position, curr_unit_inst.rotated_vectors)
	else:
		place_on_board(grid_pos, curr_unit_inst.placement_size, curr_unit)
		bm.add_unit_to_board(curr_unit_inst, objectCells[0].position, curr_unit_inst.placement_vectors)

	_reset_highlight(objectCells)

	# Allow the player to keep placing this unit as long as there still are cards left
	if curr_inv_slot.remove_item(1) == false:
		curr_unit = null
		curr_unit_inst = null
		if selector_rect_debug:
			selector_rect = Rect2(0,0,0,0)
	else:
		# Visually mark that you cannot keep placing here
		_check_and_highlight_cells(objectCells)
		
	isValid = false
	

	

# Placement logic using logical grid
func check_unit_space_availability(top_corner: Vector2, size: Vector2) -> bool:
	for x in size.x:
		for y in size.y:
			if unit_board_space_map[top_corner.x + x][top_corner.y + y] != null:
				return false
	return true

func place_on_board(top_corner: Vector2, size: Vector2, unit_ref: PackedScene) -> void:
	for x in size.x:
		for y in size.y:
			unit_board_space_map[top_corner.x + x][top_corner.y + y] = unit_ref
	

func get_unit_at_tile(tile: Vector2) -> PackedScene:
	if tile.x >= 0 and tile.x < unit_board_width and tile.y >= 0 and tile.y < unit_board_height:
		return unit_board_space_map[tile.x][tile.y]
	return null

func remove_from_board(top_corner: Vector2, size: Vector2) -> void:
	# Set current unit to reference of removed unit
	curr_unit = unit_board_space_map[top_corner.x][top_corner.y]
	
	for x in size.x:
		for y in size.y:
			unit_board_space_map[top_corner.x + x][top_corner.y + y] = null

	# Reset cells' full flag
	for cell in _get_object_cells():
		cell.full = false

	bm.remove_unit_from_board(top_corner, size)

func set_current_item(slot : InventorySlot):
	curr_inv_slot = slot
	
	curr_unit = slot.item
	curr_unit_inst = slot.item_inst
