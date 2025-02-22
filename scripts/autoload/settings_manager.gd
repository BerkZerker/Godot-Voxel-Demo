extends Node

## Preload the GameSettings class
const GameSettings = preload("res://scripts/resources/game_settings.gd")

## Singleton to manage game settings
const SETTINGS_PATH = "res://settings/game_settings.tres"

var settings: GameSettings

func _ready():
    load_settings()

## Load settings from file or create default
func load_settings():
    if ResourceLoader.exists(SETTINGS_PATH):
        settings = load(SETTINGS_PATH) as GameSettings
        if !settings:
            push_error("Failed to load game settings!")
            create_default_settings()
    else:
        create_default_settings()
        
func create_default_settings():
    settings = GameSettings.new()
    save_settings()
    
## Save current settings to file
func save_settings():
    if !settings:
        push_error("No settings to save!")
        return
    
    # Ensure directory exists
    var dir = DirAccess.open("res://")
    if !dir.dir_exists("settings"):
        dir.make_dir("settings")
    
    var error = ResourceSaver.save(settings, SETTINGS_PATH)
    if error:
        push_error("Failed to save settings! Error: ", error)

## Setter methods
func set_noise_seed(value: int):
    if settings:
        settings.noise_seed = value
        save_settings()

## Getter methods for easy access
func get_chunk_size() -> int:
    return settings.chunk_size
    
func get_world_size() -> Vector3i:
    return Vector3i(settings.world_size_x, settings.world_size_y, settings.world_size_z)
    
func get_render_distance() -> int:
    return settings.render_distance
    
func get_movement_speed() -> float:
    return settings.movement_speed
    
func get_sprint_speed() -> float:
    return settings.sprint_speed
    
func get_mouse_sensitivity() -> float:
    return settings.mouse_sensitivity
    
func get_ambient_light_energy() -> float:
    return settings.ambient_light_energy
    
func get_directional_light_energy() -> float:
    return settings.directional_light_energy
    
func get_custom_seed() -> int:
    return settings.custom_seed
    
func get_noise_seed() -> int:
    return settings.noise_seed
    
func get_noise_frequency() -> float:
    return settings.noise_frequency
    
func get_terrain_threshold() -> float:
<<<<<<< HEAD
    return settings.terrain_threshold
    
func get_voxel_size() -> float:
    return settings.voxel_size

## Generate a seed based on settings
func generate_seed() -> int:
    # If custom seed is set and valid, use it
    if settings.custom_seed >= 0:
        return settings.custom_seed
    # Otherwise generate a random seed
    return randi()
=======
    return settings.terrain_threshold
>>>>>>> parent of a6f277b (voxel and chunk size settings)
