extends Area2D

@onready var coll = $CollisionShape2D

var in_range = {}

func _on_body_entered(body):
	#print(body, " entered search space")
	if body not in in_range:
		in_range[body] = 0

func _on_body_exited(body):
	#print(body, " exited search space")
	if body in in_range:
		in_range.erase(body)
