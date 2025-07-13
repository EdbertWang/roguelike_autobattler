@tool
extends GridContainer

@export var width := 5:
	set(value): 
		width = value
		_remove_grid()
		_create_grid()
@export var height := 5:
	set(value): 
		height = value
		_remove_grid()
		_create_grid()
@export var cellWidth := 100:
	set(value): 
		cellWidth = value
		_remove_grid()
		_create_grid()
@export var cellHeight := 100:
	set(value):
		cellHeight = value
		_remove_grid()
		_create_grid()
@export var borderSize = 0:
	set(value):
		borderSize = value
		_remove_grid()
		_create_grid()

@export var GRID_CELL : PackedScene

func _create_grid():
	add_theme_constant_override("h_separation", borderSize)
	add_theme_constant_override("v_separation", borderSize)
	
	columns = width

	for i in width * height:
		var gridCellNode : BoardSlot = GRID_CELL.instantiate()
		gridCellNode.custom_minimum_size = Vector2(cellWidth, cellHeight)
		gridCellNode.board_position = Vector2(i % width, int(i / width))
		add_child(gridCellNode.duplicate())

func _remove_grid():
	for node in get_children():
		node.queue_free()

func post_ready():
	for i in get_children():
		i.post_ready()

#func _ready() -> void:
#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Pass the grid event to the main gui node
#func _on_gui_input(event: InputEvent) -> void:
#	get_parent().get_node("GUI").check_cell()
