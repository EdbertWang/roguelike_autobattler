extends Control
@onready var post_ready_check = false

var bm
var unit_board : GridContainer
@onready var spell_bar : GridContainer = $SpellBar

var unit_board_height : int
var unit_board_width : int

var unit_board_space_map : Array[Array] = [] # Stores references to units on the board

# Store these state variables in globals since they are required by the input events
var targetCell
var objectCells = []
var curr_unit : PackedScene
var curr_mouse_tile : Vector2
var isValid = false
var placement_mode : bool = true # True for placing, false for removing

func post_ready():
	bm = get_parent()
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

func _process(delta):
	check_cell()

func _input(event: InputEvent):
	if Input.is_action_just_pressed("leftClick"):
		if placement_mode:
			if curr_unit and isValid:
				_place_unit()
		else:
			var removed_unit = get_unit_at_tile(curr_mouse_tile)
			if removed_unit:
				remove_from_board(curr_mouse_tile, removed_unit.placement_size)

func check_cell():
	# Potentially might need to change to work with moving and scaling camera
	# var eventPosition = get_viewport().canvas_transform.affine_inverse().xform(event.position)
	
	var mouse_pos = get_viewport().get_mouse_position()
	curr_mouse_tile = mouse_pos / Vector2(unit_board.cellWidth, unit_board.cellHeight)
	
	var new_target = _get_target_cell(mouse_pos)
	if new_target and new_target != targetCell:
		targetCell = new_target
		if curr_unit:
			curr_unit.global_position = targetCell.global_position + curr_unit.rect_size / 2
			_reset_highlight()
			objectCells = _get_object_cells()
			isValid = _check_and_highlight_cells(objectCells)

func _get_target_cell(mouse_pos):
	for cell: Control in unit_board.get_children():
		if cell.get_global_rect().has_point(mouse_pos):
			return cell
	return null

func _reset_highlight():
	for cell: Control in unit_board.get_children():
		cell.change_color(Color(0.5, 0.5, 0.5, 0.5))

func _get_object_cells() -> Array:
	var cells = []
	for cell: Control in unit_board.get_children():
		if cell.get_global_rect().intersects(Rect2(curr_unit.global_position, curr_unit.rect_size)):
			cells.append(cell)
	return cells

func _check_and_highlight_cells(cells: Array) -> bool:
	var valid = true

	# Optional size-based cell count check
	var expected_count = int(curr_unit.placement_size.x / unit_board.rect_size.x) * int(curr_unit.placement_size.y / unit_board.rect_size.y)
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
	
	var grid_pos = unit_board.local_to_map(curr_unit.global_position)
	place_on_board(grid_pos, curr_unit.placement_size, curr_unit)
	bm.add_unit_to_board(curr_unit)

	_reset_highlight()
	curr_unit = null
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

func set_current_item(item : PackedScene):
	#curr_unit = item.
	pass
