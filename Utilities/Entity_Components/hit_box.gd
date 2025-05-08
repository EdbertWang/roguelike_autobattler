extends Area2D
class_name HitBox

@export var damage = 1
@onready var coll = $CollisionShape2D
@onready var disableTimer = $Timer

func disable():
	coll.call_deferred("set","disable",true)
	disableTimer.start()


func _on_timer_timeout():
	coll.call_deferred("set","disable",false)


func entity_hit():
	pass


func _on_body_entered(_body):
	pass
