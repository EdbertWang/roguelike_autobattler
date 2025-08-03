extends Node2D

signal done_moving

var tween: Tween

func _ready() -> void:
	pass

func move_to(pos_to_move_to: Vector2) -> void:
	# Kill any existing tween
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Tween the position
	tween.tween_property(self, "global_position", pos_to_move_to, 0.4)
	
	# Connect to finished signal
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	done_moving.emit()

func set_pos(pos_to_set_to: Vector2) -> void:
	global_position = pos_to_set_to
