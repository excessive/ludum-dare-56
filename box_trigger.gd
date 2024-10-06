@tool
extends Area3D
class_name BoxTrigger

@export var size := Vector3(1, 1, 1):
	set(v):
		size = v
		_collider.shape.size = size
		if _vis:
			_vis.mesh.size = size
@export var debug_color := Color(Color.BLUE, 0.33)
@export var spawn: PackedScene
@export var spawn_location: Node3D
@export var all_characters := false

var _collider := CollisionShape3D.new()
var _vis: MeshInstance3D

func _init() -> void:
	var box := BoxShape3D.new()
	box.size = size
	_collider.shape = box
	add_child(_collider)

func _ready() -> void:
	if Engine.is_editor_hint():
		_vis = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.albedo_color = debug_color
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		box.material = mat
		_vis.mesh = box
		add_child(_vis)

	body_entered.connect(_on_enter)

func _on_enter(body: Node3D):
	if not spawn or not spawn.can_instantiate():
		return

	if all_characters:
		var found := 0
		var bodies := get_overlapping_bodies()
		if body is Character and not bodies.has(body):
			bodies.push_back(body)
		for path in Character.characters:
			var node = get_node_or_null(path)
			if not node or not bodies.has(node):
				break
			found += 1
		var n := Character.characters.size()
		Console.print_line("%d/%d finished" % [ found, n ])
		if found < n:
			return

	if body is CharacterBody3D:
		var obj := spawn.instantiate()
		add_child(obj)
		if is_instance_valid(spawn_location) and obj is Node3D:
			obj.global_position = spawn_location.global_position
