class_name FrameAutoScroll
extends CameraControllerBase

# Define the frame bounds and scroll speed
@export var top_left: Vector2 = Vector2(-5, 5)  # Top-left corner of the frame in XZ plane
@export var bottom_right: Vector2 = Vector2(5, -5)  # Bottom-right corner of the frame in XZ plane
@export var autoscroll_speed: float = 1.0  # Units per second to scroll along the X-Z 

@export var box_width:float = 10.0
@export var box_height:float = 10.0

func _ready() -> void:
	current = true  # Enable the camera

func _process(delta: float) -> void:
	if !current:
		return
	# Draw the frame boundary if draw_camera_logic is enabled
	if draw_camera_logic:
		draw_logic()
	# Auto-scroll the camera horizontally by adding autoscroll_speed * delta to the X position
	global_position.x += autoscroll_speed * delta
	global_position.z += autoscroll_speed * delta

	# Ensure the target (player) stays within the frame bounds
	keep_target_within_frame()
	
	super(delta)

func keep_target_within_frame() -> void:
	var tpos = target.global_position  # Target position
	var left_bound = global_position.x + top_left.x
	var right_bound = global_position.x + bottom_right.x
	var top_bound = global_position.z + top_left.y
	var bottom_bound = global_position.z + bottom_right.y

	# If the target touches the left edge, push it forward with the frame
	if tpos.x < left_bound:
		target.global_position.x = left_bound

	# Constrain target within the other boundaries (right, top, bottom)
	target.global_position.x = clamp(tpos.x, left_bound, right_bound)
	target.global_position.z = clamp(tpos.z, bottom_bound, top_bound)

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var left:float = -box_width / 2
	var right:float = box_width / 2
	var top:float = -box_height / 2
	var bottom:float = box_height / 2
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
