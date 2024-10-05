extends Node3D
class_name Cable

var a: CableSocket
var b: CableSocket

var label := Label3D.new()

func _init(_a: CableSocket, _b: CableSocket):
	a = _a
	b = _b
	assert(is_instance_valid(a))
	assert(is_instance_valid(b))
	print("%s -> %s" % [a.name, b.name])
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true

func _ready() -> void:
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

	#var want := sa.power * pressure_diff * 0.5
	var want := (1.0 + sa.power) * pressure_diff * delta
	var got := sa._demand(want)
	var rem := sb._supply(got)
	sa._supply(rem) # b filled, return remainder
	label.text = "%0.2fv" % [(sa.power + sb.power) / 2]
	#print("%2.2f <-> %2.2f" % [sa.power, sb.power])

func _process(_delta: float) -> void:
	if not cable_connected():
		queue_free()
		return

	ExDD.draw_line_3d(a.global_position, b.global_position, Color.GREEN_YELLOW)
	label.global_position = (a.global_position + b.global_position) / 2
