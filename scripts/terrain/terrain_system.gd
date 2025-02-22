extends Node3D

# Node references
@onready var world_generator = $WorldGenerator
@onready var chunk_manager = $ChunkManager

# Signals
signal chunk_loaded(chunk_pos: Vector3i)
signal chunk_unloaded(chunk_pos: Vector3i)

# Initialize the terrain system
func initialize(chunk_size: int, render_distance: int):
	if !chunk_manager:
		push_error("ChunkManager node not found in TerrainSystem!")
		return

	if !world_generator:
		push_error("WorldGenerator node not found in TerrainSystem!")
		return

	# Disconnect existing signals if they exist
	if chunk_manager.chunk_loaded.is_connected(_on_chunk_loaded):
		chunk_manager.chunk_loaded.disconnect(_on_chunk_loaded)
	if chunk_manager.chunk_unloaded.is_connected(_on_chunk_unloaded):
		chunk_manager.chunk_unloaded.disconnect(_on_chunk_unloaded)

	# Initialize chunk manager
	chunk_manager.initialize(chunk_size, render_distance)

	# Connect signals
	chunk_manager.chunk_loaded.connect(_on_chunk_loaded)
	chunk_manager.chunk_unloaded.connect(_on_chunk_unloaded)

# Load a chunk at the specified position
func load_chunk(chunk_pos: Vector3i):
	chunk_manager.load_chunk(chunk_pos)

# Unload a chunk at the specified position
func unload_chunk(chunk_pos: Vector3i):
	chunk_manager.unload_chunk(chunk_pos)

# Clear all chunks from the world
func clear_chunks():
	if chunk_manager:
		# Get list of all active chunks and unload them
		var chunks = chunk_manager.get_active_chunks()
		for chunk in chunks:
			chunk_manager.unload_chunk(chunk.position)
		
		# Reset internal chunk manager state
		chunk_manager.reset()
	else:
		push_error("ChunkManager node not found when trying to clear chunks!")

# Get a chunk at a world position
func get_chunk_at(world_pos: Vector3) -> Node3D:
	return chunk_manager.get_chunk_at(world_pos)

# Convert world position to chunk position
func world_to_chunk_position(world_pos: Vector3) -> Vector3i:
	return chunk_manager.world_to_chunk_position(world_pos)

# Signal handlers
func _on_chunk_loaded(chunk_pos: Vector3i):
	emit_signal("chunk_loaded", chunk_pos)

func _on_chunk_unloaded(chunk_pos: Vector3i):
	emit_signal("chunk_unloaded", chunk_pos)
