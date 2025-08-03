extends Node2D
class_name MapNode


var id: int
var connections: Array[MapNode] = []
var node_type: String = "normal"  # normal, start, end, boss, shop, etc.
var difficulty: String = "easy"
var stage: int = 1
var completed: bool = false
var available: bool = false

func _init(node_id: int, pos: Vector2):
	id = node_id
	position = pos
