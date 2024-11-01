class_name TargetFocusLerp
extends CameraControllerBase

@export var base_lead_speed: float = 70.0  # Base lead speed
@export var boost_lead_speed: float = 200.0  # Lead speed during boost mode
@export var catchup_speed: float = 40  # Speed to catch up when the player stops
@export var leash_distance: float = 20  # Maximum allowed distance between camera and player
@export var radius: float = 5  # For drawing the cross

@onready var vessel: Vessel = %Vessel
var time_since_stop: float = 0.0  # Tracks the time since the player stopped moving
var is_moving: bool = false  # Tracks whether the player is currently moving

func _ready() -> void:
	super()
	current = true
	position = target.position

func _process(delta: float) -> void:
	if !current:
		return

	
	if draw_camera_logic:
		draw_logic()

	# Calculate the vector offset and distance from the camera to the target
	var offset = target.global_position - transform.origin
	var distance = offset.length()

	# Determine if the vessel is moving and get the input direction
	var input_dir = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	is_moving = input_dir != Vector2.ZERO  # Check if the vessel is moving

	# Check if the vessel is in boost mode (speed = 300)
	var is_boosting = vessel.velocity.length() >= 300

	# Adjust lead speed based on boost mode
	var current_lead_speed = boost_lead_speed if is_boosting else base_lead_speed

	if is_moving:
		
		# Lead the camera in the direction of player input with adjusted lead speed
		var lead_offset = Vector3(input_dir.x, 0, input_dir.y).normalized() * leash_distance
		var target_position = target.global_position + lead_offset
		var lerp_factor = current_lead_speed * delta / distance
		transform.origin = transform.origin.lerp(target_position, min(lerp_factor, 1.0))

	else:
		
		var lerp_factor = catchup_speed * delta / distance
		transform.origin = transform.origin.lerp(target.global_position, min(lerp_factor, 1.0))

	# Ensure camera never falls too far behind the vessel in boost mode
	if distance > leash_distance and is_boosting:
		transform.origin = transform.origin.lerp(target.global_position, min(1.0, current_lead_speed * delta / distance))

	super(delta)

func draw_logic() -> void:
	# Create an ImmediateMesh instance for drawing a cross
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	# Configure material properties
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	
	var left: float = -radius
	var right: float = radius
	var top: float = -radius
	var bottom: float = radius

	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	# Vertical line
	immediate_mesh.surface_add_vertex(Vector3(0, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, bottom))
	
	# Horizontal line
	immediate_mesh.surface_add_vertex(Vector3(right, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, 0))

	immediate_mesh.surface_end()

	# Set the cross position and add mesh to the scene, freeing it after one frame
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(transform.origin.x, target.global_position.y, transform.origin.z)
	await get_tree().process_frame
	mesh_instance.queue_free()
