extends Node3D
class_name AnimLink

var animation_player: AnimationPlayer

func _ready() -> void:
	animation_player = find_child("AnimationPlayer")
