class_name FourWayDoubleBox
extends CameraControllerBase

@export var push_ratio: float = 1.8  # The ratio that the camera should move toward the target when not at the edge of the outer pushbox
@export var pushbox_top_left: Vector2 = Vector2(-15, 15)  # Top-left corner of the outer push zone
@export var pushbox_bottom_right: Vector2 = Vector2(15, -15)  # Bottom-right corner of the outer push zone
@export var speedup_zone_top_left: Vector2 = Vector2(-5, 5)  # Top-left corner of the inner speedup zone
@export var speedup_zone_bottom_right: Vector2 = Vector2(5, -5)  # Bottom-right corner of the inner speedup zone

@onready var vessel: Vessel = %Vessel

func _ready() -> void:
	super()
	current = true
	position = target.position

func _process(delta: float) -> void:
	if not current:
		return

	# Player and camera positions
	var tpos = target.global_position  # vessel position
	var cpos = global_position  # camera position
	
	# Speed of the vessel
	var vessel_speed = vessel.velocity.length()

	# Calculate the boundaries for the inner speedup zone relative to the camera
	var inner_left = cpos.x + speedup_zone_top_left.x
	var inner_right = cpos.x + speedup_zone_bottom_right.x
	var inner_top = cpos.z + speedup_zone_top_left.y
	var inner_bottom = cpos.z + speedup_zone_bottom_right.y

	# Calculate the boundaries for the outer pushbox relative to the camera
	var outer_left = cpos.x + pushbox_top_left.x
	var outer_right = cpos.x + pushbox_bottom_right.x
	var outer_top = cpos.z + pushbox_top_left.y
	var outer_bottom = cpos.z + pushbox_bottom_right.y

	# Check if the vessel is within the inner speedup zone boundaries
	var is_in_inner_zone = (tpos.x - target.WIDTH / 2.0) > inner_left and (tpos.x + target.WIDTH / 2.0) < inner_right and (tpos.z - target.HEIGHT / 2.0) > inner_bottom and (tpos.z + target.HEIGHT / 2.0) < inner_top

	# Determine if the player is in the middle region (between inner and outer box)
	var is_in_middle_region = not is_in_inner_zone and (tpos.x - target.WIDTH / 2.0) > outer_left and (tpos.x + target.WIDTH / 2.0) < outer_right and (tpos.z - target.HEIGHT / 2.0) > outer_bottom and (tpos.z + target.HEIGHT / 2.0) < outer_top

	# Check if there is active input
	var input_dir = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	
	var has_input = input_dir != Vector2.ZERO

	# If the player is inside the inner speedup zone, do not move the camera
	if is_in_inner_zone:
		pass
	
	# If the player is in the middle region and has input, move the camera based on push_ratio
	elif is_in_middle_region:
		if has_input:
			var diff_x = (tpos.x - cpos.x) * push_ratio 
			var diff_z = (tpos.z - cpos.z) * push_ratio 
			global_position += Vector3(diff_x * delta, 0, diff_z * delta)

	# If the player is touching the outer border, move the camera based on the border condition
	else:
		var move_x = 0.0
		var move_z = 0.0

		# Handle horizontal movement at full speed or with push_ratio if along one axis only
		if tpos.x <= outer_left:
			move_x = tpos.x - outer_left
		elif tpos.x >= outer_right:
			move_x = tpos.x - outer_right

		# Handle vertical movement at full speed or with push_ratio if along one axis only
		if tpos.z >= outer_top:
			move_z = tpos.z - outer_top
		elif tpos.z <= outer_bottom:
			move_z = tpos.z - outer_bottom

		# Apply the movement
		global_position += Vector3(move_x, 0, move_z)

	# Draw push zone boundaries if enabled
	if draw_camera_logic:
		draw_logic()
		
	super(delta)

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Draw inner speedup zone
	var left: float = speedup_zone_top_left.x
	var right: float = speedup_zone_bottom_right.x
	var top: float = speedup_zone_top_left.y
	var bottom: float = speedup_zone_bottom_right.y
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))

	# Draw outer pushbox
	left = pushbox_top_left.x
	right = pushbox_bottom_right.x
	top = pushbox_top_left.y
	bottom = pushbox_bottom_right.y

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
	
	# Mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
