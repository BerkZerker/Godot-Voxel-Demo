extends Camera3D

@export var movement_speed: float = 10.0  # Base movement speed
@export var fast_speed: float = 20.0    # Speed when "fast mode" is enabled (Shift)
@export var mouse_sensitivity: float = 0.002 # Mouse sensitivity for rotation

var current_speed: float = 0.0       # Current movement speed
var mouse_captured: bool = true        # Whether the mouse is captured
var yaw: float = 0.0                  # Yaw (horizontal rotation)
var pitch: float = 0.0                # Pitch (vertical rotation)
var direction: Vector3 = Vector3.FORWARD # Camera's forward direction

func _ready():
    # Initialization
    current_speed = movement_speed
    position = Vector3(0, 40, 0) # Start position
    pitch = -PI/2 # Look down initially
    update_camera_rotation()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Capture mouse

func _process(delta):
    # Toggle mouse capture with Escape key
    if Input.is_action_just_pressed("ui_cancel"):
        mouse_captured = !mouse_captured
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

func _input(event):
    # Handle mouse input for rotation
    if event is InputEventMouseMotion and mouse_captured:
        yaw -= event.relative.x * mouse_sensitivity
        pitch -= event.relative.y * mouse_sensitivity
        pitch = clamp(pitch, -PI/2, PI/2) # Limit vertical view
        update_camera_rotation()
    # Recapture mouse on click when not captured
    elif event is InputEventMouseButton and event.pressed and not mouse_captured:
        mouse_captured = true
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
    # Handle movement input
    var input_dir = Vector3.ZERO

    # Set current speed based on sprint action
    if Input.is_action_pressed("sprint"):
        current_speed = fast_speed
    else:
        current_speed = movement_speed

    # Horizontal movement (X and Z axes)
    if Input.is_action_pressed("left"):
        input_dir.x -= 1
    if Input.is_action_pressed("right"):
        input_dir.x += 1
    if Input.is_action_pressed("backward"):
        input_dir.z -= 1
    if Input.is_action_pressed("forward"):
        input_dir.z += 1
    
    # Vertical movement (Y axis)
    if Input.is_action_pressed("up"):   # Space to go up
        input_dir.y += 1
    if Input.is_action_pressed("down"): # Control to go down
        input_dir.y -= 1
    
    input_dir = input_dir.normalized() # Normalize input vector

    # Apply movement relative to camera direction
    var forward = Vector3.UP.cross(direction).normalized()
    var right = Vector3.UP.cross(forward).normalized()

    var velocity = Vector3.ZERO
    velocity += forward * input_dir.x * current_speed  # X-axis movement
    velocity += right * input_dir.z * current_speed    # Z-axis movement
    velocity += Vector3.UP * input_dir.y * current_speed # Y-axis movement
    
    # Apply movement
    position += velocity * delta

func update_camera_rotation():
    # Update camera's rotation based on yaw and pitch
    direction.x = cos(pitch) * sin(yaw)
    direction.y = sin(pitch)
    direction.z = cos(pitch) * cos(yaw)
    direction = direction.normalized()

    rotation = Vector3(pitch, yaw, 0) # Apply rotation to camera
