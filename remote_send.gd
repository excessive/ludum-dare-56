extends Node
class_name RemoteSend

@export var source_node: NodePath
@export var source_property: String = ""
@export var destination_node: NodePath
@export var destination_property: String = ""

func _ready() -> void:
	if not source_node:
		source_node = get_path_to(get_parent())

func _process(_delta: float) -> void:
	var a := get_node_or_null(source_node)
	var b := get_node_or_null(destination_node)
	if not a or not b:
		return
	if not source_property or not destination_property:
		return
	b.set_indexed(destination_property, a.get_indexed(source_property))
