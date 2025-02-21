@tool
extends Node3D

const CHUNK_SIZE = 16  # Size of each chunk in voxels
const WORLD_SIZE_X = 16  # Half width of the world in chunks (32 total)
const WORLD_SIZE_Y = 4   # Half height of the world in chunks (8 total)
const WORLD_SIZE_Z = 16  # Half depth of the world in chunks (32 total)

@onready var chunk_manager = $ChunkManager

func _ready():
    if Engine.is_editor_hint():
        return
    
    # Initialize the world
    init_world()

func init_world():
    if !chunk_manager:
        push_error("ChunkManager node not found!")
        return
    
    # Initialize the chunk system with largest dimension
    chunk_manager.initialize(CHUNK_SIZE, max(WORLD_SIZE_X, max(WORLD_SIZE_Y, WORLD_SIZE_Z)))
    
    # Generate initial world chunks
    var center_chunk_pos = Vector3i.ZERO
    for x in range(-WORLD_SIZE_X, WORLD_SIZE_X):
        for y in range(-WORLD_SIZE_Y, WORLD_SIZE_Y):
            for z in range(-WORLD_SIZE_Z, WORLD_SIZE_Z):
                var chunk_pos = Vector3i(
                    center_chunk_pos.x + x,
                    center_chunk_pos.y + y,
                    center_chunk_pos.z + z
                )
                chunk_manager.load_chunk(chunk_pos)

func _exit_tree():
    pass