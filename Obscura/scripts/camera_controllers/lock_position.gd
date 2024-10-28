class_name LockPosition
extends CameraControllerBase

@export var radius:float = 2.0

func _ready() -> void:
	super()
	position = target.position
	
	
func _process(delta: float) -> void:
	if !current:
		return
	
	# Center the camera on the target's position, offset by dist_above_target on the y-axis
	global_position = target.global_position + Vector3(0, dist_above_target, 0)

	# Toggle drawing of camera logic if enabled
	if draw_camera_logic:
		draw_logic()

		
	super(delta)
	
	
func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var left:float = -radius 
	var right:float = radius 
	var top:float = -radius 
	var bottom:float = radius
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(0, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, 0))
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
