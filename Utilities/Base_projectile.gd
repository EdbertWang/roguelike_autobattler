extends HitBox

class_name Base_Projectile

@export var id : int = -1
@export var speed : int = 50
var direction : Vector2

var spawner : Base_Spawner


func _physics_process(delta):
	position += direction * speed * delta


func _on_lifetime_timeout():
	#print($Lifetime.wait_time)
	if spawner != null:
		spawner._return_bullet_to_pool(self)
	else:
		queue_free()
	
func entity_hit():
	if spawner != null:
		spawner._return_bullet_to_pool(self)
	else:
		queue_free()
	

func _on_body_entered(_body):
	if spawner != null:
		spawner._return_bullet_to_pool(self)
	else:
		queue_free()


func reset_base_state():
	pass

func set_direction():
	direction = Vector2.from_angle(rotation)
