extends Node3D

## Node References
@onready var settings_manager = null
@onready var directional_light = $DirectionalLight3D
@onready var world_environment = $WorldEnvironment

func _ready():
    # Get settings manager
    if has_node("/root/SettingsManager"):
        settings_manager = get_node("/root/SettingsManager")
        apply_lighting_settings()
    else:
        push_error("SettingsManager not found! Please ensure it's properly set up in Project Settings > AutoLoad")
        # Use default values if settings aren't available
        set_default_lighting()

func apply_lighting_settings():
    if !settings_manager:
        return
        
    # Apply lighting settings
    if directional_light:
        directional_light.light_energy = settings_manager.get_directional_light_energy()
    
    if world_environment and world_environment.environment:
        world_environment.environment.ambient_light_energy = settings_manager.get_ambient_light_energy()

func set_default_lighting():
    # Set default values if settings aren't available
    if directional_light:
        directional_light.light_energy = 0.2
    
    if world_environment and world_environment.environment:
        world_environment.environment.ambient_light_energy = 0.5