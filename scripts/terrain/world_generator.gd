extends Node

## Node References
@onready var settings_manager = null

## Terrain Generation
var noise = FastNoiseLite.new()

func _ready():
    # Get settings manager
    if has_node("/root/SettingsManager"):
        settings_manager = get_node("/root/SettingsManager")
        configure_noise()
    else:
        push_error("SettingsManager not found! Please ensure it's properly set up in Project Settings > AutoLoad")
        # Set default values if settings aren't available
        noise.seed = 12345
        noise.noise_type = FastNoiseLite.TYPE_PERLIN
        noise.frequency = 0.05

## Noise Configuration
func configure_noise():
    if !settings_manager:
        return
        
    # Set up noise parameters for terrain generation using settings
    noise.seed = settings_manager.get_noise_seed()
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = settings_manager.get_noise_frequency()

## Terrain Generation Methods
func get_voxel_value(x: int, y: int, z: int) -> float:
    """
    Gets the terrain value at a given world position.
    Returns a value between -1 and 1, where higher values indicate solid terrain.
    """
    var noise_value = noise.get_noise_3d(x, y, z)
    
    # Use threshold from settings if available, otherwise use default
    var threshold = 0.2
    if settings_manager:
        threshold = settings_manager.get_terrain_threshold()
        
    return noise_value