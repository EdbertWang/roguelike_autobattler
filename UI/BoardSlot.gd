extends PanelContainer
class_name BoardSlot

@export var full = false

var board_position : Vector2
var cell_rect : Rect2

func change_color(color:Color):
	var styleBox := get_theme_stylebox("panel").duplicate()
	styleBox.bg_color = color
	add_theme_stylebox_override("panel",styleBox)


func _ready():
	cell_rect = get_global_rect()
	change_color(Color(0.5, 0.5, 0.5, 0.5))
