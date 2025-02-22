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

## Cleanup
func _exit_tree():
    # Cleanup resources if needed
    pass