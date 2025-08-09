extends Camera2D

@export_group("Camera Controls")
@export var camera_move_speed : int 
@export var camera_default_size : Vector2 # TODO: Ensure concistancy with aspect ratio
@export var camera_max_size: float
@export var camera_min_size: float
@export var camera_scroll_speed : float

func _ready():
	zoom = Vector2.ONE

func _input(event):
	# Mouse click detection
	if event is InputEventMouseButton:
		# Get mouse wheel zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom -= Vector2.ONE * camera_scroll_speed
			zoom = zoom.clamp(Vector2.ONE * camera_min_size, Vector2.ONE * camera_max_size)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom += Vector2.ONE * camera_scroll_speed
			zoom = zoom.clamp(Vector2.ONE * camera_min_size, Vector2.ONE * camera_max_size)


func _process(delta: float) -> void:
	# viewport movement
	var camera_move_dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    camera_move_dir.y -= 1
	if Input.is_action_pressed("move_down"):  camera_move_dir.y += 1
	if Input.is_action_pressed("move_left"):  camera_move_dir.x -= 1
	if Input.is_action_pressed("move_right"): camera_move_dir.x += 1
	
	if camera_move_dir != Vector2.ZERO:
		camera_move_dir = camera_move_dir.normalized()
		position += camera_move_dir * camera_move_speed * delta


func post_ready():
	for i in get_children():
		if i.has_method("post_ready"):
			i.post_ready()
