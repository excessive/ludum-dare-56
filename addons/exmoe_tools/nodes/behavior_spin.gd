@tool
extends Node3D

@export var _spin := 1.0

func _process(delta: float) -> void:
	rotate_y(_spin * delta)
