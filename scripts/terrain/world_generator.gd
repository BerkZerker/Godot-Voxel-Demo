extends Node

## Node References
@onready var settings_manager = null

## Terrain Generation
var base_noise = FastNoiseLite.new()
var detail_noise = FastNoiseLite.new()
var mountain_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()

func _ready():
	# Get settings manager
	if has_node("/root/SettingsManager"):
		settings_manager = get_node("/root/SettingsManager")
		configure_noise()
	else:
		push_error("SettingsManager not found! Please ensure it's properly set up in Project Settings > AutoLoad")
		# Set default values if settings aren't available
		set_default_noise_parameters()

## Noise Configuration
func configure_noise():
	if !settings_manager:
		return
		
	# Configure base terrain noise
	base_noise.seed = settings_manager.get_noise_seed()
	base_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	base_noise.frequency = settings_manager.get_noise_frequency()
	
	# Configure detail noise for terrain variations
	detail_noise.seed = settings_manager.get_noise_seed() + 1
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = settings_manager.get_noise_frequency() * 2.0
	
	# Configure mountain noise for height variations
	mountain_noise.seed = settings_manager.get_noise_seed() + 2
	mountain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	mountain_noise.frequency = settings_manager.get_noise_frequency() * 0.5
	
	# Configure cave noise for underground features
	cave_noise.seed = settings_manager.get_noise_seed() + 3
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.frequency = settings_manager.get_noise_frequency() * 3.0

func set_default_noise_parameters():
	# Base terrain defaults
	base_noise.seed = 12345
	base_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	base_noise.frequency = 0.05
	
	# Detail noise defaults
	detail_noise.seed = 12346
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = 0.1
	
	# Mountain noise defaults
	mountain_noise.seed = 12347
	mountain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	mountain_noise.frequency = 0.025
	
	# Cave noise defaults
	cave_noise.seed = 12348
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.frequency = 0.15

## Constants
const VoxelType = preload("res://scripts/world/chunk.gd").VoxelType

## Terrain Generation Methods
func get_voxel_value(x: int, y: int, z: int) -> int:
	"""
	Gets the terrain value at a given world position.
	Returns a VoxelType value (AIR or SOLID).
	"""
	# Get base terrain height
	var base_value = base_noise.get_noise_2d(x, z) * 0.5
	var mountain_value = mountain_noise.get_noise_2d(x, z) * 0.3
	
	# Calculate height threshold
	var height_threshold = (base_value + mountain_value) * 20.0  # Amplify height
	
	# Add terrain variations
	var detail_value = detail_noise.get_noise_3d(x * 1.5, y * 1.5, z * 1.5) * 0.2
	
	# Calculate cave value
	var cave_value = cave_noise.get_noise_3d(x, y, z)
	
	# Default to AIR
	var voxel_type = VoxelType.AIR
	
	if y < height_threshold:
		# Default to SOLID below height threshold
		voxel_type = VoxelType.SOLID
		
		# Add caves below surface
		if y < height_threshold - 5 and cave_value > 0.7:
			voxel_type = VoxelType.AIR
	
	return voxel_type

func get_biome_value(x: int, y: int, z: int) -> int:
	"""
	Gets the biome type at a given world position.
	Returns an integer representing the biome type.
	"""
	# To be implemented: return different biome types based on noise values
	return 0  # Default biome for now
