@tool
extends Node3D

signal chunk_loaded(chunk_pos: Vector3i)
signal chunk_unloaded(chunk_pos: Vector3i)

var chunk_size: int = 16
var render_distance: int = 8
var active_chunks: Dictionary = {}

# Load chunk scene dynamically
var chunk_scene: PackedScene

func _ready():
    chunk_scene = load("res://scenes/chunk.tscn")
    if !chunk_scene:
        push_error("Failed to load chunk scene!")

func initialize(size: int, distance: int):
    chunk_size = size
    render_distance = distance

func load_chunk(chunk_pos: Vector3i):
    if chunk_pos in active_chunks:
        return

    var chunk = chunk_scene.instantiate()
    if !chunk:
        push_error("Failed to instantiate chunk scene at position: ", chunk_pos)
        return

    chunk.position = chunk_position_to_world(chunk_pos)
    chunk.chunk_position = chunk_pos
    add_child(chunk)
    active_chunks[chunk_pos] = chunk
    emit_signal("chunk_loaded", chunk_pos)

func unload_chunk(chunk_pos: Vector3i):
    if not chunk_pos in active_chunks:
        return
    
    var chunk = active_chunks[chunk_pos]
    if is_instance_valid(chunk):
        chunk.queue_free()
    active_chunks.erase(chunk_pos)
    emit_signal("chunk_unloaded", chunk_pos)

func world_to_chunk_position(world_pos: Vector3) -> Vector3i:
    return Vector3i(
        floor(world_pos.x / chunk_size),
        floor(world_pos.y / chunk_size),
        floor(world_pos.z / chunk_size)
    )

func chunk_position_to_world(chunk_pos: Vector3i) -> Vector3:
    return Vector3(
        chunk_pos.x * chunk_size,
        chunk_pos.y * chunk_size,
        chunk_pos.z * chunk_size
    )

func get_chunk_at(world_pos: Vector3) -> Node3D:
    var chunk_pos = world_to_chunk_position(world_pos)
    return active_chunks.get(chunk_pos)