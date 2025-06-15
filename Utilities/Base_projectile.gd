extends Area2D

class_name Base_Projectile

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape : CollisionShape2D = $CollisionShape2D
@onready var lifetime : Timer = $Lifetime
@onready var animation : AnimationPlayer = $AnimationPlayer

###### Internal Vars
@export var speed : int = 50
@export var lifetime_val : float = 1.0
var direction : Vector2
var target_faction : bool

###### Standard Functions

func _physics_process(delta):
	position += direction * speed * delta


func _on_lifetime_timeout():
		queue_free()
	
func entity_hit():
		queue_free()
	

func _on_body_entered(body):
	if body.faction == target_faction:
		queue_free()
	else:
		pass

func set_direction():
	direction = Vector2.from_angle(rotation)
