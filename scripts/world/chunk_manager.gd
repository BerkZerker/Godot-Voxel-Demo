@tool
extends Node3D

## Signals
signal chunk_loaded(chunk_pos: Vector3i)
signal chunk_unloaded(chunk_pos: Vector3i)

## Chunk Management Properties
var chunk_size: int = 16  # Default, will be updated from settings
var render_distance: int = 8
var active_chunks: Dictionary = {}
var visible_chunks: Dictionary = {}  # Chunks currently visible to camera
var settings_manager = null
var player_camera: Camera3D = null

## Resource References
var chunk_scene: PackedScene

## Lifecycle Methods
func _ready():
	# Get settings manager
	if has_node("/root/SettingsManager"):
		settings_manager = get_node("/root/SettingsManager")
		chunk_size = settings_manager.get_chunk_size()
	else:
		push_error("SettingsManager not found! Using default values.")
	
	# Load the chunk scene from components directory
	chunk_scene = load("res://scenes/components/chunk.tscn")
	if !chunk_scene:
		push_error("Failed to load chunk scene!")
	
	# Set up camera reference
	await get_tree().create_timer(0.1).timeout  # Wait for scene to setup
	
	# Try finding player through group first
	var player = get_tree().get_first_node_in_group("Player")
	
	# If not found in group, try finding in scene tree
	if !player:
		player = get_tree().root.find_child("Player", true, false)
	
	if player:
		player_camera = player.find_child("Camera3D")
		if player_camera:
			print("Camera found at position: ", player_camera.global_position)
		else:
			push_error("Player camera not found in node: ", player.name)
	else:
		push_error("Player node not found in scene tree!")

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
	visible_chunks[chunk_pos] = chunk  # Add to visible chunks immediately
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
	visible_chunks.erase(chunk_pos)
	emit_signal("chunk_unloaded", chunk_pos)

# Get all active chunks
func get_active_chunks() -> Array:
	var chunks = []
	for pos in active_chunks:
		var chunk = active_chunks[pos]
		if is_instance_valid(chunk):
			chunks.append({
				"position": pos,
				"node": chunk
			})
	return chunks

# Reset chunk manager state
func reset():
	# Clear all active chunks
	var chunks_to_unload = active_chunks.keys()
	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)
	
	# Reset internal state
	active_chunks.clear()
	visible_chunks.clear()
	
	# Reload settings
	if settings_manager:
		chunk_size = settings_manager.get_chunk_size()
	else:
		chunk_size = 16  # Default value

## Position Conversion Methods
func world_to_chunk_position(world_pos: Vector3) -> Vector3i:
	var voxel_size = 1.0
	if settings_manager:
		voxel_size = settings_manager.get_voxel_size()
	
	# Account for voxel size in position calculation
	var scaled_pos = world_pos / voxel_size
	return Vector3i(
		floor(scaled_pos.x / chunk_size),
		floor(scaled_pos.y / chunk_size),
		floor(scaled_pos.z / chunk_size)
	)

func chunk_position_to_world(chunk_pos: Vector3i) -> Vector3:
	var voxel_size = 1.0
	if settings_manager:
		voxel_size = settings_manager.get_voxel_size()
	
	# Account for voxel size in position calculation
	return Vector3(
		chunk_pos.x * chunk_size * voxel_size,
		chunk_pos.y * chunk_size * voxel_size,
		chunk_pos.z * chunk_size * voxel_size
	)

## Utility Methods
func get_chunk_at(world_pos: Vector3) -> Node3D:
	var chunk_pos = world_to_chunk_position(world_pos)
	return active_chunks.get(chunk_pos)
