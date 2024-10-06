extends Node3D
class_name CableConnection

@export var a: CableSocket
@export var b: CableSocket
@export var locked := false
@export var hidden := false

var power := 0.0

func _ready() -> void:
	if a and b:
		if not hidden:
			a.unplug()
			b.unplug()
			add_child(Cable.new(a, b, true))
	set_physics_process(a and b and hidden)

func _physics_process(_delta: float) -> void:
	var p := minf(a.power, b.power)
	if a.cable_connected() and b.cable_connected():
		p = maxf(a.power, b.power)
	a.power = p
	b.power = p
	power = p
