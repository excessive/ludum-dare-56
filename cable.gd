extends Node3D
class_name Cable

var a: CableSocket
var b: CableSocket

var label := Label3D.new()
var rope := Rope3D.new()
var locked := false
var show_label := false

func _init(_a: CableSocket, _b: CableSocket, _locked := false):
	a = _a
	b = _b
	locked = _locked
	assert(is_instance_valid(a))
	assert(is_instance_valid(b))
	rope.default_material = preload("res://addons/rope/cable_material.tres")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true

func _ready() -> void:
	if show_label:
		add_child(label)

func cable_connected() -> bool:
	if a and not is_instance_valid(a):
		a = null
	if b and not is_instance_valid(b):
		b = null
	return a and b

func _enter_tree() -> void:
	if a and not a._wire:
		a._wire = self
	if b and not b._wire:
		b._wire = self

func _exit_tree() -> void:
	if a and a._wire == self:
		a._wire = null
	if b and b._wire == self:
		b._wire = null

func _physics_process(delta: float) -> void:
	if not cable_connected():
		queue_free()
		return

	var pa := a.power
	var pb := b.power
	var pressure_diff := pa - pb
	if absf(pressure_diff) < 1e-5:
		label.text = "%0.2fv" % [(pa + pb) / 2]
		return

	var sa := a
	var sb := b
	if pressure_diff < 0:
		var tmp := sa
		sa = sb
		sb = tmp
		pressure_diff = -pressure_diff

	var want := (1.0 + sa.power) * pressure_diff * delta
	var got := sa._demand(want)
	var rem := sb._supply(got)
	sa._supply(rem) # b filled, return remainder
	label.text = "%0.2fv" % [(sa.power + sb.power) / 2]

func _process(_delta: float) -> void:
	if not cable_connected():
		queue_free()
		return

	if not locked:
		ExDD.draw_line_3d(a.global_position, b.global_position, Color.GREEN_YELLOW)
	
	if is_ancestor_of(label):
		label.global_position = (a.global_position + b.global_position) / 2

	if locked:
		if rope:
			rope.queue_free()
			rope = null
		return

	if not is_ancestor_of(rope):
		add_child(rope)
	rope.attach_end_to = b.get_path()
	rope.global_position = a.global_position
	rope.rope_length = a.global_position.distance_to(b.global_position) * 0.5
	rope.stiffness = 0.9
	rope.iterations = 3
	rope.apply_collision = false
	rope.rope_width = 0.025
