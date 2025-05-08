extends FSM

func _init() -> void:
	super() # Get the waiting state
	_add_state("march")
	_add_state("local_march")
	_add_state("attack")
	_add_state("dead")
	
	
func _state_logic(_delta: float) -> void:
	match state:
		states.march:
			target_movement.get_target()
			parent.move_vec = target_movement.get_flow_field()
		states.local_march:
			target_movement.get_target()
			parent.move_vec = target_movement.get_dir_target()
		states.attack:
			parent.move_vec = Vector2.ZERO
			
	
	parent.movement()

func _get_transition() -> int:
	match state:
		states.wait_ready:
			if post_ready_check:
				set_state(states.march)
		
		states.march:
			if target_movement.in_range():
				set_state(states.attack)
			if target_movement.in_same_tile():
				set_state(states.local_march)
		
		states.local_march:
			if target_movement.in_range():
				set_state(states.attack)
			else:
				set_state(states.march)
		
		states.attack:
			if not target_movement.in_range():
				set_state(states.local_march)
	return -1
	
	
func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.march:
			sprite.play("walk")
			
		states.local_march:
			sprite.play("walk")

		states.dead:
			sprite.play("die")
			animation_player.play("dead")

