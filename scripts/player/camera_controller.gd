extends Camera3D

## Node References
@onready var settings_manager = null

## Movement Properties
var current_speed: float = 10.0     # Default speed until settings are loaded
var mouse_captured: bool = true        # Whether the mouse is captured
var yaw: float = 0.0                  # Yaw (horizontal rotation)
var pitch: float = 0.0                # Pitch (vertical rotation)
var direction: Vector3 = Vector3.FORWARD # Camera's forward direction

## Lifecycle Methods
func _ready():
    # Get settings manager
    if has_node("/root/SettingsManager"):
        settings_manager = get_node("/root/SettingsManager")
        current_speed = settings_manager.get_movement_speed()
    else:
        push_error("SettingsManager not found! Please ensure it's properly set up in Project Settings > AutoLoad")
    
    # Initialize camera
    position = Vector3(0, 40, 0) # Start position
    pitch = -PI/2 # Look down initially
    update_camera_rotation()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Capture mouse

## Input Processing
func _process(delta):
    # Handle mouse capture toggle
    if Input.is_action_just_pressed("ui_cancel"):
        toggle_mouse_capture()

func _input(event):
    handle_mouse_input(event)

func _physics_process(delta):
    handle_movement(delta)

## Mouse Input Methods
func handle_mouse_input(event):
    if !settings_manager:
        return
        
    # Handle mouse movement when captured
    if event is InputEventMouseMotion and mouse_captured:
        yaw -= event.relative.x * settings_manager.get_mouse_sensitivity()
        pitch -= event.relative.y * settings_manager.get_mouse_sensitivity()
        pitch = clamp(pitch, -PI/2, PI/2) # Limit vertical view
        update_camera_rotation()
    # Recapture mouse on click when not captured
    elif event is InputEventMouseButton and event.pressed and not mouse_captured:
        capture_mouse()

## Movement Methods
func handle_movement(delta):
    # Get input direction
    var input_dir = get_input_direction()
    
    # Update current speed based on sprint
    update_current_speed()
    
    # Calculate and apply velocity
    var velocity = calculate_velocity(input_dir)
    position += velocity * delta

## Input Helper Methods
func get_input_direction() -> Vector3:
    var input_dir = Vector3.ZERO
    
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
    
    return input_dir.normalized()

func update_current_speed():
    if !settings_manager:
        return
        
    current_speed = settings_manager.get_sprint_speed() if Input.is_action_pressed("sprint") else settings_manager.get_movement_speed()

func calculate_velocity(input_dir: Vector3) -> Vector3:
    # Calculate movement vectors
    var forward = Vector3.UP.cross(direction).normalized()
    var right = Vector3.UP.cross(forward).normalized()
    
    # Calculate final velocity
    var velocity = Vector3.ZERO
    velocity += forward * input_dir.x * current_speed  # X-axis movement
    velocity += right * input_dir.z * current_speed    # Z-axis movement
    velocity += Vector3.UP * input_dir.y * current_speed # Y-axis movement
    
    return velocity

## Camera Control Methods
func update_camera_rotation():
    # Update camera's direction vector
    direction.x = cos(pitch) * sin(yaw)
    direction.y = sin(pitch)
    direction.z = cos(pitch) * cos(yaw)
    direction = direction.normalized()
    
    # Apply rotation to camera
    rotation = Vector3(pitch, yaw, 0)

func toggle_mouse_capture():
    mouse_captured = !mouse_captured
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

func capture_mouse():
    mouse_captured = true
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED