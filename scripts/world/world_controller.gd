@tool
extends Node3D

## System References
@onready var terrain_system = $TerrainSystem
@onready var player = $Player
@onready var settings_manager = null

## Core Methods
func _ready():
    if Engine.is_editor_hint():
        return

    # Get settings manager
    if has_node("/root/SettingsManager"):
        settings_manager = get_node("/root/SettingsManager")
    else:
        push_error("SettingsManager not found! Please ensure it's properly set up in Project Settings > AutoLoad")
        return

    # Initialize the world
    init_world()

    # Set up input handling for regeneration
    set_process_input(true)

func _input(event):
    if event.is_action_pressed("regenerate"):
        regenerate_world()

## World initialization
func init_world():
    if !terrain_system:
        push_error("TerrainSystem node not found!")
        return

    if !settings_manager:
        push_error("SettingsManager not available!")
        return

    # Initialize the terrain system using settings
    var world_size = settings_manager.get_world_size()
    var max_dimension = max(world_size.x, max(world_size.y, world_size.z))
    terrain_system.initialize(settings_manager.get_chunk_size(), max_dimension)

    # Calculate start positions for chunk generation
    var half_size_x = world_size.x / 2
    var half_size_y = world_size.y / 2
    var half_size_z = world_size.z / 2
    var start_x = -floor(half_size_x)
    var start_y = -floor(half_size_y)
    var start_z = -floor(half_size_z)

    # Generate world chunks centered around origin
    for x in range(world_size.x):
        for y in range(world_size.y):
            for z in range(world_size.z):
                var chunk_pos = Vector3i(
                    start_x + x,
                    start_y + y,
                    start_z + z
                )
                terrain_system.load_chunk(chunk_pos)

## World Regeneration
func regenerate_world():
    # Clear existing chunks
    if terrain_system:
        terrain_system.clear_chunks()
        
        # Generate new seed based on settings
        var new_seed = settings_manager.generate_seed()
        settings_manager.set_noise_seed(new_seed)
        
        # Update noise configuration
        if has_node("TerrainSystem/WorldGenerator"):
            var generator = get_node("TerrainSystem/WorldGenerator")
            generator.configure_noise()
        
        # Regenerate world
        init_world()
        
        # Print seed info
        var custom_seed = settings_manager.get_custom_seed()
        if custom_seed >= 0:
            print("World regenerated with custom seed: ", new_seed)
        else:
            print("World regenerated with random seed: ", new_seed)

## Cleanup
func _exit_tree():
    # Cleanup resources if needed
    pass
