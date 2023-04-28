extends SpringArm3D

@export var mouse_sensitivity: float = 0.05

var mouse_input: bool = false

#var zoom_factor: float = 1.0
#var zoom_amount: float = 0.5
#var zoom: float = 1.0
#var zoom_speed: float = 2.0
#const MAX_ZOOM = 0.5
#const MIN_ZOOM = 3.5

var move_speed = 8.0

var forward_direction

func _unhandled_input(event):
	if Input.is_action_just_pressed('exit'):
		get_tree().quit()
	if not Globals.selected_a_photo: 
		mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		if mouse_input:
			rotation_degrees.x -= event.relative.y * mouse_sensitivity
			rotation_degrees.x = clamp(rotation_degrees.x, -90.0, 30.0)
			
			rotation_degrees.y -= event.relative.x * mouse_sensitivity
			rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)
#		if event is InputEventMouseButton:
#			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
#				zoom_factor -= zoom_amount
#			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
#				zoom_factor += zoom_amount
#			zoom_factor = clamp(zoom_factor, MAX_ZOOM, MIN_ZOOM)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	if not Globals.selected_a_photo: 
		forward_direction = Vector3.ZERO
		var _camera_forward = -transform.basis.z.normalized()
		var _camera_axis = _camera_forward.abs().max_axis_index()
		forward_direction[_camera_axis] = sign(_camera_forward[_camera_axis])
		
		if Input.is_action_pressed('ui_up'):
			move(forward_direction, delta)
		if Input.is_action_pressed('ui_down'):
			move(-forward_direction, delta)
		if Input.is_action_pressed('ui_left'):
			move(-forward_direction.cross(Vector3.UP), delta)
		if Input.is_action_pressed('ui_right'):
			move(forward_direction.cross(Vector3.UP), delta)

func move(direction, delta):
	transform.origin += direction * move_speed * delta

func _process(_delta):
	if Input.is_action_just_pressed('pan_camera'):
		mouse_sensitivity = 0.5
	elif Input.is_action_just_released('pan_camera'):
		mouse_sensitivity = 0.05
#	zoom = lerp(zoom, zoom_factor, delta * zoom_speed)
#	set_scale(Vector3(zoom, zoom, zoom))
