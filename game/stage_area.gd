@tool
extends Area3D
class_name StageArea

@export var size := Vector3(100, 10, 100):
	set(v):
		size = v
		_collider.shape.size = size
		if _vis:
			_vis.mesh.size = size

@export_file("*.tscn") var leave_scene: String
var _transitioning := false
var _collider := CollisionShape3D.new()
var _vis: MeshInstance3D

func _init() -> void:
	var box := BoxShape3D.new()
	box.size = size
	_collider.shape = box
	add_child(_collider)

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		Console.pause_enabled = true
		Console.add_command("leave", queue_leave, [], 0, "Leave the area or respawn in overworld")

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		Console.pause_enabled = false
		Console.remove_command("leave")

func _ready() -> void:
	if Engine.is_editor_hint():
		_vis = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.albedo_color = Color(Color.RED, 0.1)
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		box.material = mat
		_vis.mesh = box
		add_child(_vis)

	body_exited.connect(_on_exit)

func _on_exit(body: Node3D):
	if body is CharacterBody3D:
		queue_leave()
	if body is RigidBody3D:
		body.queue_free()

func queue_leave():
	if not _transitioning:
		ExTransition.auto_transition_threaded(leave_scene)
		_transitioning = true
