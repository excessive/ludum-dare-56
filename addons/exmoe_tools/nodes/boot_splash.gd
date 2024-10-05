extends Node

@export var splash: Node

static var first_load := true

func _ready() -> void:
	if not first_load:
		return
	first_load = false
	assert(splash)
	var pack := PackedScene.new()
	pack.pack(splash)
	splash.queue_free()
	ExTransition.auto_transition(pack, null)
