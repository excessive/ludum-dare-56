extends Node3D
class_name LazyRemoteTransform3D

@export var remote_path: NodePath
@export_range(0, 100, 0.01) var position_speed: float = 0.0
@export_range(0, 100, 0.01) var rotation_speed: float = 0.0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := []
	if not get_node_or_null(remote_path):
		warnings.push_back("remote_path is not set to a valid node")
	return warnings

func _physics_process(delta: float) -> void:
	var n := get_node_or_null(remote_path)
	if not n or n is not Node3D:
		return
	var node: Node3D = n
	node.global_transform = Transform3D(
		node.global_basis.slerp(global_basis, 1.0 - exp(-rotation_speed * delta)),
		node.global_position.lerp(global_position, 1.0 - exp(-position_speed * delta))
	)
