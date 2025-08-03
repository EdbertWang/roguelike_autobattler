extends Node2D
class_name  MapConnection

var from_node: MapNode
var to_node: MapNode
var bidirectional: bool = true

func _init(from: MapNode, to: MapNode, bi: bool = true):
	from_node = from
	to_node = to
	bidirectional = bi
