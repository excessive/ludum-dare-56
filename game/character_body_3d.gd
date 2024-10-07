extends CharacterBody3D
class_name Character

@export var avatar: AnimLink

@export var can_connect := false
@export var can_grab := true

@export var jump_height := 0.25
@export var move_speed := 2.0
@export var accel_speed := 5.0
@export var rotation_base := 22.5

const HOLD_TIME := 0.2
const MAX_CABLE_LENGTH := 2.0

# these are validated/pruned every frame
var _nearest_plug: CableSocket
var _current_plug: CableSocket

var _held_time := 0.0
var _active := false
var coins := 0
@onready var max_coins := get_tree().get_nodes_in_group(&"collectible").size()

static var active_character: NodePath
static var characters: Array[NodePath] = []

enum AnimState {
	Idle,
	Run,
	Jump,
	Grab
}

var _anim_state := AnimState.Idle

func _try_play(anim: AnimationPlayer, anim_name: String, revert_to_idle := true):
	if anim.has_animation(anim_name):
		if anim.assigned_animation != anim_name:
			anim.play(anim_name, 0.125)
	elif revert_to_idle:
		_anim_state = AnimState.Idle
		_update_animation()

func _update_animation():
	if not avatar or not avatar.animation_player:
		return

	var anim := avatar.animation_player
	match _anim_state:
		AnimState.Idle:
			_try_play(anim, "idle", false)
		AnimState.Run:
			_try_play(anim, "run")
		AnimState.Jump:
			_try_play(anim, "jump")
		AnimState.Grab:
			_try_play(anim, "grab")

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_anim_state = AnimState.Idle
		if velocity.length() > 0.1:
			_anim_state = AnimState.Run
	else:
		_anim_state = AnimState.Jump
		velocity += get_gravity() * delta

	for item: Node3D in $collectible_grabber.get_overlapping_areas():
		if item.is_in_group(&"collectible"):
			item.queue_free()
			coins += 1
			var total := get_tree().get_nodes_in_group(&"collectible").size()
			Console.print_line("coin get (%d/%d)" % [coins, max_coins], true)
			if coins >= max_coins:
				Console.print_line("all coins collected!", true)

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not _active:
		input_dir *= 0
	var direction := (transform.basis * ($cam_pivot as Node3D).basis * Vector3(input_dir.x, 0, input_dir.y)).limit_length() * move_speed
	direction.y = velocity.y
	velocity = velocity.move_toward(direction, accel_speed * delta)

	var bias := Vector3.UP * 0.0001
	if velocity.length() > 0.001 and absf(velocity.normalized().dot(Vector3.UP)) < 0.99:
		$body_pivot.look_at_from_position(global_position, global_position + velocity, -get_gravity() + bias)
	else:
		$body_pivot.look_at_from_position(global_position, global_position - $body_pivot.global_basis.z * Vector3(1, 0, 1), -get_gravity() + bias)

	if not _active:
		move_and_slide()
		_update_animation()
		return

	if not _try_connect(delta):
		_try_grab(delta)

	$cam_pivot.global_rotation_degrees.y = snappedf($cam_pivot.global_rotation_degrees.y - rotation_base, 90) + rotation_base
	if Input.is_action_just_pressed("view_cw"):
		$cam_pivot.rotate_y(deg_to_rad(-90))

	if Input.is_action_just_pressed("view_ccw"):
		$cam_pivot.rotate_y(deg_to_rad(90))

	if Input.is_action_just_pressed("jump") and is_on_floor():
		_anim_state = AnimState.Jump
		velocity -= get_gravity() * jump_height

	if Input.is_action_just_pressed("switch"):
		Character.active_character = Character.characters.pop_back()
		Character.characters.push_front(Character.active_character)

	move_and_slide()
	_update_animation()

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
			if _nearest_plug and not _nearest_plug.cable_locked():
				var d := _nearest_plug.global_position.distance_to(_current_plug.global_position)
				if d <= MAX_CABLE_LENGTH:
					_current_plug.unplug()
					_nearest_plug.unplug()
					add_child(Cable.new(_nearest_plug, _current_plug))
				else:
					Console.print_line("cable too long, can't connect")
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
		var d := global_position - _current_plug.global_position
		ExDD.draw_line_3d(_current_plug.global_position, _current_plug.global_position + d.limit_length(MAX_CABLE_LENGTH), Color.REBECCA_PURPLE)
