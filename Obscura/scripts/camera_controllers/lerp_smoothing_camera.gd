class_name LerpSmoothingCamera
extends CameraControllerBase

@export var follow_speed: float = 30.0  # Speed to follow the player while moving
@export var catchup_speed: float = 20.0  # Speed to catch up when the player stops
@export var leash_distance: float = 20  # Maximum allowed distance between camera and player
@export var radius: float = 5  # For drawing the cross

@onready var vessel: Vessel = %Vessel

func _ready() -> void:
	super()
	current = true
	position = target.position

func _process(delta: float) -> void:
	if !current:
		return

	# Draw cross if draw_camera_logic is enabled
	if draw_camera_logic:
		draw_logic()

	# Calculate the vector offset and distance from the camera to the target
	var offset = target.global_position - transform.origin
	var distance = offset.length()


	var is_moving = vessel.velocity.length() > 0.1  # Adjust threshold if needed

	# Use follow speed if the vessel is moving, otherwise use catchup speed
	var speed = follow_speed if is_moving else catchup_speed

	# Calculate lerp factor based on distance and leash_distance
	var lerp_factor = speed * delta / distance

	
	if distance > leash_distance:
		lerp_factor = 600 * delta / distance
		# Catch up to the vessel when beyond leash distance
		transform.origin = transform.origin.lerp(target.global_position, min(lerp_factor, 1.0))
	else:
		# Smoothly follow the vessel within leash distance
		transform.origin = transform.origin.lerp(target.global_position, 0.05)

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

	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(transform.origin.x, target.global_position.y, transform.origin.z)
	await get_tree().process_frame
	mesh_instance.queue_free()
