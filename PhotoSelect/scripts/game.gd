extends Node3D

@onready var camera_3d := $SpringArm3D
@onready var photo_album := $Photos

@onready var cross_hair := $Label # Crosshair
@onready var instructions = $Instructions

# Moving / Animated Objects
@onready var bowl_cereal := $BowlCereal
@onready var cabbage := $Cabbage
@onready var avocado_half := $Path3D/PathFollow3D/AvocadoHalf
var avocado_time: float = 0.0
var avocado_move_speed: float = 10.0

@onready var ui_animation_player := $UIAnimationPlayer
@onready var cabbage_animation_player := $Cabbage/CabbageAnimationPlayer
@onready var flash_overlay = $ColorRect

var texture_button_scene = preload('res://texture_button.tscn')
var outline_shader = preload('res://vfx/outline.gdshader')

var photo_scene = 'res://2d_view.tscn'

var cereal_tween: Tween

var animated_objects: Array = []
var animated_object_names: Array = []

func _ready():
	photo_album.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if flash_overlay.color != Color(1, 1, 1, 0):
		flash_overlay.color = Color(1, 1, 1, 0)
	ui_animation_player.play('fade_in')
	
	# Add in any moving objects here
	animated_objects = [cabbage, bowl_cereal, avocado_half]
	if animated_objects:
		for i in animated_objects:
			var _s = str(i).split(":")[0]
			animated_object_names.append(_s)
	
	if not Globals.selected_a_photo:
		# Placeholder animations
		cabbage_animation_player.play('cabage_move')
		cereal_tween =  get_tree().create_tween()
		cereal_tween.tween_property(bowl_cereal, "scale", Vector3(14, 14, 14), 2).set_trans(Tween.TRANS_SINE)
		cereal_tween.chain().tween_property(bowl_cereal, "scale", Vector3(10, 10, 10), 1).set_trans(Tween.TRANS_SINE)
		cereal_tween.set_loops()
		
		if Globals.avocado_anim_params:
			avocado_half.get_parent().progress_ratio = Globals.avocado_anim_params.progress_ratio
			avocado_time = Globals.avocado_anim_params.time
		
	else:
		set_animated_object_params_for_photo(Globals.selected_photo_index)
		var photo_data = Globals.selected_photo_data
		camera_3d.global_position = photo_data.cam_position
		camera_3d.global_rotation_degrees = photo_data.cam_rotation
	
	# If photos have been taken, repopulate album when returning to main scene
	if Globals.photo_params:
		var _length = Globals.photo_params.size()
		var _i = 1
		for i in Globals.photo_params.values():
			var _t = texture_button_scene.instantiate()
			_t.texture_normal = i.texture
			photo_album.get_child(1).get_child(0).add_child(_t)
			_t.pressed.connect(photo_selected.bind(_i))
			_i += 1

func _process(delta):
	# Placeholder animations
	if Globals.selected_a_photo: return
	avocado_time += delta
	avocado_half.get_parent().progress = avocado_time * avocado_move_speed 

func _input(event):
	if not Globals.selected_a_photo:
		if Input.is_action_just_pressed('open_album'):
			photo_album.visible = !photo_album.visible
			if photo_album.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				cross_hair.hide()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				cross_hair.show()
		
		if Input.is_action_just_pressed('snap_photo') and not photo_album.visible:
			cross_hair.hide()
			instructions.hide()
			await get_tree().create_timer(0.1).timeout
			ui_animation_player.play('snap')
			Globals.photo_index += 1
			
			var _thumbnail_image = get_viewport().get_texture().get_image()
			_thumbnail_image.resize(270, 180)
		
			var _t = texture_button_scene.instantiate()
			var _tex = ImageTexture.create_from_image(_thumbnail_image)
			_t.texture_normal = _tex
			
			Globals.photo_params[Globals.photo_index] = {}
			Globals.photo_params[Globals.photo_index].animated_objects = {}
			
			if animated_objects:
				var _i = 0
				for i in animated_objects:
					Globals.photo_params[Globals.photo_index].animated_objects[animated_object_names[_i]] = save_animated_object_photo_data(i)
					_i += 1
	
			Globals.photo_params[Globals.photo_index].texture = _tex
			Globals.photo_params[Globals.photo_index].cam_rotation = camera_3d.global_rotation_degrees
			Globals.photo_params[Globals.photo_index].cam_position = camera_3d.global_position
			Globals.photo_params[Globals.photo_index].scene = get_tree().current_scene
			
			photo_album.get_child(1).get_child(0).add_child(_t)
			_t.pressed.connect(photo_selected.bind(Globals.photo_index))
			await get_tree().create_timer(0.1).timeout
			cross_hair.show()
			instructions.show()
	else:
		var _cam = camera_3d.get_child(0)
		var _space_state = get_world_3d().direct_space_state
		var _mouse_position = get_viewport().get_mouse_position()
		var _ray_origin = _cam.project_ray_origin(_mouse_position)
		var _ray_end = _ray_origin + _cam.project_ray_normal(_mouse_position) * 2000
		var _query = PhysicsRayQueryParameters3D.create(_ray_origin, _ray_end)
		var _result = _space_state.intersect_ray(_query)
		var _label = get_tree().root.get_child(1).get_child(5)
		
		if Input.is_action_just_pressed('snap_photo'):
			if _result and _result.collider.is_in_group('Selectable'):
				_label.text = 'You selected: %s' % str(_result.collider).split(":")[0]

		if event is InputEventMouseMotion:
			if _result and _result.collider.is_in_group('Selectable'):
				Input.set_custom_mouse_cursor(preload('res://point.png'), 0 as Input.CursorShape, Vector2(32, 32))
			else:
				_label.text = ''
				Input.set_custom_mouse_cursor(preload('res://cursor.png'), 0 as Input.CursorShape, Vector2(32, 32))

func save_animated_object_photo_data(obj):
	var params = {}
	params.transform = obj.global_transform
	return params
	
func set_animated_object_params_for_photo(photo_index):
	var _i = 0
	for i in Globals.photo_params[photo_index].animated_objects.values():
		animated_objects[_i].global_transform = i.transform
		_i += 1

func photo_selected(photo_index):
	Globals.selected_photo_index = photo_index
	
	cereal_tween.stop()
	cabbage_animation_player.stop()
	Globals.avocado_anim_params.progress_ratio = avocado_half.get_parent().progress_ratio
	Globals.avocado_anim_params.time = avocado_time
	
	Globals.selected_photo_data = Globals.photo_params[Globals.selected_photo_index]
	Globals.selected_a_photo = true
	get_tree().change_scene_to_file(photo_scene)
