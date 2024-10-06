extends Node

var game_time := 0.0
@export var running := false

func start():
	if not running:
		running = true
		set_physics_process(true)

func stop() -> float:
	running = false
	set_physics_process(false)
	return game_time

func reset():
	game_time = 0

func _ready() -> void:
	set_physics_process(running)

func _physics_process(delta: float) -> void:
	game_time += delta
