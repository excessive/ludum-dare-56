extends CharacterBody3D
class_name Character

@export var can_connect := false
@export var can_grab := true

@export var jump_height := 0.25
@export var move_speed := 2.0
@export var accel_speed = 5.0

const HOLD_TIME := 0.2

# these are validated/pruned every frame
var _nearest_plug: CableSocket
var _current_plug: CableSocket

var _held_time := 0.0
var _active := false

static var active_character: NodePath
static var characters: Array[NodePath] = []

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not _active:
		input_dir *= 0
	var direction := (transform.basis * ($cam_pivot as Node3D).basis * Vector3(input_dir.x, 0, input_dir.y)).limit_length() * move_speed
	direction.y = velocity.y
	velocity = velocity.move_toward(direction, accel_speed * delta)

	move_and_slide()

	var bias := Vector3.UP * 0.0001
	if velocity and absf(velocity.normalized().dot(Vector3.UP)) < 0.99:
		$body_pivot.look_at_from_position(global_position, global_position + velocity, -get_gravity() + bias)
	else:
		$body_pivot.look_at_from_position(global_position, global_position - $body_pivot.global_basis.z * Vector3(1, 0, 1), -get_gravity() + bias)

	if not _active:
		return

	if not _try_connect(delta):
		_try_grab(delta)

	if Input.is_action_just_pressed("view_cw"):
		$cam_pivot.rotate_y(deg_to_rad(-90))

	if Input.is_action_just_pressed("view_ccw"):
		$cam_pivot.rotate_y(deg_to_rad(90))

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity -= get_gravity() * jump_height

	if Input.is_action_just_pressed("switch"):
		Character.active_character = Character.characters.pop_front()
		Character.characters.push_back(Character.active_character)

func _try_grab(_delta: float):
	if not can_grab:
		return

func _try_connect(delta: float) -> bool:
	if not can_connect:
		return false

	# tap -> remove connection, hold (>0.2s i.e. HOLD_TIME) -> add/move connection
	if Input.is_action_pressed("grab") and (_nearest_plug or _current_plug):
		if Input.is_action_just_pressed("grab") and _nearest_plug:
			var other = _nearest_plug.check_other_socket()
			if other is CableSocket:
				_current_plug = other
			else:
				_current_plug = _nearest_plug
			_nearest_plug.unplug()
		_held_time += delta
		return true
	elif Input.is_action_just_released("grab") and _current_plug:
		if _held_time <= HOLD_TIME:
			_current_plug.unplug()
		else:
			_current_plug.unplug()
			if _nearest_plug and not _nearest_plug.cable_locked():
				_nearest_plug.unplug()
				add_child(Cable.new(_nearest_plug, _current_plug))
		_held_time = 0
		_current_plug = null
		return true

	return false

func _update_nearest_plug():
	_nearest_plug = null
	if _current_plug and not is_instance_valid(_current_plug):
		_current_plug = null

	if not can_connect:
		return

	if not $cable_grabber.has_overlapping_areas():
		return

	var closest_dist := 1e10
	for area: Area3D in $cable_grabber.get_overlapping_areas():
		if area is not CableSocket:
			continue
		var dist := area.global_position.distance_to(global_position)
		if dist < closest_dist and is_instance_valid(area):
			_nearest_plug = area
			closest_dist = dist

func _update_camera():
	var vp := get_viewport()
	if not vp:
		return
	var cam := vp.get_camera_3d()
	if not cam:
		return
	%cam_tracker.visible = _active
	%cam_tracker.remote_path = cam.get_path()

func _update_active():
	var p := get_path()
	if not Character.characters.has(p):
		Character.characters.push_back(p)

	var current_char := get_node_or_null(Character.active_character)
	if current_char == null:
		Character.active_character = p
		current_char = self
	_active = current_char == self

func _process(_delta: float) -> void:
	_update_active()
	_update_nearest_plug()
	_update_camera()

	if _current_plug:
		ExDD.draw_line_3d(global_position, _current_plug.global_position, Color.REBECCA_PURPLE)
