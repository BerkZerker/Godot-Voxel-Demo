extends Resource
class_name GameSettings

## World Generation Settings
@export_group("World Settings")
@export var voxel_size: float = 1.0  # Size of each voxel in world units
@export var chunk_size: int = 16
@export_range(1, 32) var world_size_x: int = 3  # Total number of chunks in X direction
@export_range(1, 32) var world_size_y: int = 3  # Total number of chunks in Y direction
@export_range(1, 32) var world_size_z: int = 3  # Total number of chunks in Z direction
@export var render_distance: int = 2

## Player Settings
@export_group("Player Settings")
@export var movement_speed: float = 10.0
@export var sprint_speed: float = 20.0
@export var mouse_sensitivity: float = 0.002

## Graphics Settings
@export_group("Graphics Settings")
@export var ambient_light_energy: float = 0.5
@export var directional_light_energy: float = 0.2

## Terrain Generation Settings
@export_group("Terrain Settings")
@export var noise_seed: int = 12345
@export var noise_frequency: float = 0.05
@export var terrain_threshold: float = 0.2  # Value above which voxels are solid