extends Node3D

# Get the camera controller
@onready var camera = $Camera3D

# Called when the node enters the scene tree
func _ready():
    pass

# Called every frame
func _process(delta):
    pass

# Get the current camera
func get_camera() -> Camera3D:
    return camera

# Get the current position in world space
func get_world_position() -> Vector3:
    return global_position