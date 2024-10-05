extends Area3D
class_name CableSocket

enum SocketMode {
	Charge,
	Source,
	Drain,
}

@export var charge_mode: SocketMode = SocketMode.Charge
@export var base_power: float = 0.0
@export_range(-1, 1, 0.01, "or_greater") var idle_drain := 0.0
var label := Label3D.new()
var power: float = base_power

var _wire: Cable

func _ready() -> void:
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true

func cable_connected() -> bool:
	return _wire and is_instance_valid(_wire)

func check_other_socket():
	if cable_connected():
		if _wire.a == self:
			return _wire.b
		else:
			return _wire.a
	return null

func unplug():
	if cable_connected():
		_wire.queue_free()
	_wire = null

func _demand(_qty: float) -> float:
	match charge_mode:
		SocketMode.Source:
			return minf(_qty, base_power)
		SocketMode.Drain:
			return 0
		_: pass
	return _supply(-_qty)

func _supply(_qty: float) -> float:
	match charge_mode:
		SocketMode.Source:
			return _qty
		SocketMode.Drain:
			return 0
		_: pass
	var had := power
	power = clampf(power + _qty, 0, base_power if base_power > 0.0 else 1000.0)
	return had - power

func _physics_process(delta: float) -> void:
	if charge_mode != SocketMode.Charge:
		power = base_power

	if cable_connected():
		if is_ancestor_of(label):
			remove_child(label)
		#if idle_drain > 0:
		return
	else:
		if not is_ancestor_of(label):
			add_child(label)
	if maxf(0, absf(idle_drain) - 0.01) <= 0.0:
		label.text = "%0.2fv" % [power]
		return

	# done regenerating
	if idle_drain < 0 and power >= base_power:
		label.text = "%0.2fv" % [power]
		return

	var want := (1.0 + power) * idle_drain * delta
	if want < 0 and idle_drain < 0:
		_supply(-want)
	else:
		_demand(want)
	label.text = "%0.2fv" % [power]
