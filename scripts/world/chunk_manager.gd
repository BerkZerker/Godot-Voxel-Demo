@tool
extends Node3D

## Signals
signal chunk_loaded(chunk_pos: Vector3i)
signal chunk_unloaded(chunk_pos: Vector3i)

## Chunk Management Properties
@export var chunk_size: int = 16
@export var render_distance: int = 8
@export var active_chunks: Dictionary = {}

## Resource References
var chunk_scene: PackedScene

## Lifecycle Methods
func _ready():
	# Load the chunk scene from components directory
	chunk_scene = load("res://scenes/components/chunk.tscn")
	if !chunk_scene:
		push_error("Failed to load chunk scene!")

## Initialization
func initialize(size: int, distance: int):
	chunk_size = size
	render_distance = distance

## Chunk Management Methods
func load_chunk(chunk_pos: Vector3i):
	# Skip if chunk already exists
	if chunk_pos in active_chunks:
		return

	# Create new chunk instance
	var chunk = chunk_scene.instantiate()
	if !chunk:
		push_error("Failed to instantiate chunk scene at position: ", chunk_pos)
		return

	# Setup and add chunk to scene
	chunk.position = chunk_position_to_world(chunk_pos)
	chunk.chunk_position = chunk_pos
	add_child(chunk)
	active_chunks[chunk_pos] = chunk
	emit_signal("chunk_loaded", chunk_pos)

func unload_chunk(chunk_pos: Vector3i):
	# Skip if chunk doesn't exist
	if not chunk_pos in active_chunks:
		return
	
	# Remove and cleanup chunk
	var chunk = active_chunks[chunk_pos]
	if is_instance_valid(chunk):
		chunk.queue_free()
	active_chunks.erase(chunk_pos)
	emit_signal("chunk_unloaded", chunk_pos)

## Position Conversion Methods
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

## Utility Methods
func get_chunk_at(world_pos: Vector3) -> Node3D:
	var chunk_pos = world_to_chunk_position(world_pos)
	return active_chunks.get(chunk_pos)
