extends CharacterBody3D

const SPEED = 2.0

var _nearest_plug: CableSocket
var _current_plug: CableSocket

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).limit_length() * 2.0
	direction.y = velocity.y
	velocity = velocity.move_toward(direction, SPEED * delta)

	move_and_slide()

	if Input.is_action_just_pressed("cut") and _nearest_plug and is_instance_valid(_nearest_plug):
		_nearest_plug.unplug()
	elif Input.is_action_just_pressed("grab") and _nearest_plug and is_instance_valid(_nearest_plug):
		var other = _nearest_plug.check_other_socket()
		if other is CableSocket:
			_current_plug = other
		else:
			_current_plug = _nearest_plug
		_nearest_plug.unplug()
	elif Input.is_action_just_released("grab") and _current_plug:
		_current_plug.unplug()
		if _nearest_plug:
			_nearest_plug.unplug()
			add_child(Cable.new(_nearest_plug, _current_plug))
		_current_plug = null

func _update_nearest_plug():
	_nearest_plug = null
	if not $cable_grabber.has_overlapping_areas():
		return
	var closest_dist := 1e10
	for area: Area3D in $cable_grabber.get_overlapping_areas():
		if area is not CableSocket:
			continue
		var dist := area.global_position.distance_to(global_position)
		if dist < closest_dist:
			_nearest_plug = area

func _update_camera():
	var vp := get_viewport()
	if not vp:
		return
	var cam := vp.get_camera_3d()
	if not cam:
		return
	$cam_tracker.remote_path = cam.get_path()

func _process(_delta: float) -> void:
	_update_nearest_plug()
	_update_camera()

	if _current_plug and is_instance_valid(_current_plug):
		ExDD.draw_line_3d(global_position, _current_plug.global_position, Color.REBECCA_PURPLE)
