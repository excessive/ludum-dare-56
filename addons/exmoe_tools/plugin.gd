@tool
extends EditorPlugin

func _enter_tree():
	var base := get_editor_interface().get_base_control()
	add_custom_type("ExSmoothing3D", "Node3D", preload("nodes/smoothing.gd"), preload("ui/textures/smoothing.png"))
	add_custom_type("ExFollowCam3D", "Camera3D", preload("nodes/follow_cam.gd"), base.get_theme_icon("Camera3D"))
	add_autoload_singleton("ExInput", "res://addons/exmoe_tools/autoloads/input.gd")
	add_autoload_singleton("ExTransition", "res://addons/exmoe_tools/autoloads/transition.gd")
	add_autoload_singleton("ExDD", "res://addons/exmoe_tools/autoloads/debug_draw.gd")

func _exit_tree():
	remove_custom_type("ExSmoothing3D")
	remove_custom_type("ExFollowCam3D")
	remove_autoload_singleton("ExInput")
	remove_autoload_singleton("ExTransition")
