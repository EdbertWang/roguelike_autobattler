extends Node

##### External references
var unit
var target_manager
var flow_field

###### Internal variables
var curr_targets : Array
var flow_vec : Vector2

var curr_target_iter : int = -1
var target_idx = 0

##### Primary Functions

func get_N_targets(num_targets : int) -> Array:
	# Check if the target manager has updated recently
	# get a new targets array from the manager and sort them by distanc
	
	if target_manager.target_iter != curr_target_iter:
		curr_target_iter = target_manager.target_iter
		curr_targets = target_manager.get_targets(!unit.faction, unit.position, num_targets)
		curr_targets.sort_custom(_sort_ascending_distance)
		
	var results : Array = []
	for i in curr_targets:
		if i != null:
			results.append(i)
	curr_targets = results
	
	target_idx = 0
	return curr_targets


func get_target() -> Base_Unit:
	var result = get_N_targets(1)
	if result and result[0] != null:
		return result[0]
	else:
		return null
		
func get_flow_field() -> Vector2:
	flow_vec = flow_field.get_flow(!unit.faction, unit.position)
	return flow_vec

func get_dir_target() -> Vector2:
	if _get_non_null_idx():
		return  (curr_targets[target_idx].position - unit.position).normalized()
	return flow_vec
	
func in_same_tile() -> bool:
	if _get_non_null_idx():
		# use larger than the size of a tile to prevent getting stuck at edges
		return (curr_targets[target_idx].position - unit.position).length_squared() < (target_manager.get_parent().tile_size * 1.5) ** 2
	return false

####### Helper functions

func post_ready() -> void:
	unit = get_parent()
	target_manager = get_tree().get_nodes_in_group("TARGETMANAGER")[0]
	flow_field = get_tree().get_nodes_in_group("FLOWGEN")[0]

func _get_non_null_idx():
	while target_idx < curr_targets.size() and curr_targets[target_idx] == null:
		target_idx += 1
	
	# Case: No non-null targets left
	if target_idx == curr_targets.size():
		return false
	return true

func _sort_ascending_distance(a, b):
	# Move Nulls to the back of the array
	if a == null and b == null:
		return true
	if a == null:
		return false
	if b == null:
		return true
		
	# Sort by which unit is closer
	if (unit.position - a.position).length_squared() < (unit.position - b.position).length_squared():
		return true
	return false
