@tool
extends Node3D

## Enums
enum VoxelType {
	AIR = 0,
	SOLID = 1,
}

## Static Resources
static var shared_material: StandardMaterial3D = null

## Chunk Properties
var chunk_position: Vector3i
var voxel_data: Array = []
var mesh_instance: MeshInstance3D
var settings_manager = null
var world_generator = null
var chunk_size: int = 16  # Default, will be updated from settings

# Lookup table for voxel properties
const VOXEL_PROPERTIES = {
	VoxelType.AIR: {"transparent": true},
	VoxelType.SOLID: {"transparent": false}
}

## Static Resource Management
static func _setup_shared_material():
	if !shared_material:
		shared_material = StandardMaterial3D.new()
		shared_material.albedo_color = Color(1.0, 1.0, 1.0)
		shared_material.vertex_color_use_as_albedo = true
		shared_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shared_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

## Lifecycle Methods
func _ready():
	# Ensure shared material is set up
	_setup_shared_material()
	
	if has_node("/root/SettingsManager"):
		settings_manager = get_node("/root/SettingsManager")
		chunk_size = settings_manager.get_chunk_size()
	else:
		push_error("SettingsManager not found! Using default values.")
	
	# Get world generator reference
	var chunk_manager = get_parent()
	if chunk_manager:
		var terrain_system = chunk_manager.get_parent()
		if terrain_system and terrain_system.has_node("WorldGenerator"):
			world_generator = terrain_system.get_node("WorldGenerator")
		else:
			push_error("WorldGenerator not found! Terrain generation will not work properly.")
	
	initialize_chunk()

## Initialization
func initialize_chunk():
	# Initialize voxel data array
	voxel_data.resize(chunk_size * chunk_size * chunk_size)
	voxel_data.fill(VoxelType.AIR)
	
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.material_override = shared_material
	
	# Generate initial terrain
	generate_terrain()

## Terrain Generation
func generate_terrain():
	if !world_generator:
		push_error("Cannot generate terrain: WorldGenerator not found!")
		return
	
	# Generate terrain using world generator
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				# Convert local position to world position
				var world_x = (chunk_position.x * chunk_size + x)
				var world_y = (chunk_position.y * chunk_size + y)
				var world_z = (chunk_position.z * chunk_size + z)
				
				# Get terrain value from world generator
				var value = world_generator.get_voxel_value(world_x, world_y, world_z)
				
				# Set voxel based on terrain value
				var voxel_pos = Vector3i(x, y, z)
				set_voxel(voxel_pos, VoxelType.SOLID if value > 0 else VoxelType.AIR)
	
	# Update the visual mesh
	update_mesh()

## Voxel Management Methods
func set_voxel(local_pos: Vector3i, value: int):
	if !is_position_valid(local_pos):
		push_warning("Invalid voxel position: ", local_pos)
		return
	
	var index = get_voxel_index(local_pos)
	voxel_data[index] = value

func get_voxel(local_pos: Vector3i) -> int:
	if !is_position_valid(local_pos):
		push_warning("Attempted to get invalid voxel position: ", local_pos)
		return VoxelType.AIR
	
	var index = get_voxel_index(local_pos)
	return voxel_data[index]

## Utility Methods
func is_position_valid(pos: Vector3i) -> bool:
	return pos.x >= 0 && pos.x < chunk_size && \
		   pos.y >= 0 && pos.y < chunk_size && \
		   pos.z >= 0 && pos.z < chunk_size

func get_voxel_index(pos: Vector3i) -> int:
	return pos.x + (pos.y * chunk_size * chunk_size) + (pos.z * chunk_size)

func is_face_visible(pos: Vector3i, normal: Vector3i) -> bool:
	if !is_position_valid(pos):
		return false
	
	var neighbor_pos = pos + normal
	if !is_position_valid(neighbor_pos):
		return true
	
	var current_voxel = get_voxel(pos)
	var neighbor_voxel = get_voxel(neighbor_pos)
	
	return VOXEL_PROPERTIES[neighbor_voxel]["transparent"] != VOXEL_PROPERTIES[current_voxel]["transparent"]

## Mesh Generation
func generate_simple_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Set white color for visibility
	st.set_color(Color(1, 1, 1, 1))
	
	var voxel_size = 1.0
	if settings_manager:
		voxel_size = settings_manager.get_voxel_size()
	
	# Generate a simple cube for each solid voxel
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var pos = Vector3i(x, y, z)
				if get_voxel(pos) == VoxelType.SOLID:
					var base_pos = Vector3(x, y, z) * voxel_size
					
					# Front face
					st.set_normal(Vector3(0, 0, -1))
					st.add_vertex(base_pos + Vector3(0, 0, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, 0, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, 0))
					st.add_vertex(base_pos + Vector3(0, 0, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, 0))
					st.add_vertex(base_pos + Vector3(0, voxel_size, 0))
					
					# Back face
					st.set_normal(Vector3(0, 0, 1))
					st.add_vertex(base_pos + Vector3(0, 0, voxel_size))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, voxel_size))
					st.add_vertex(base_pos + Vector3(voxel_size, 0, voxel_size))
					st.add_vertex(base_pos + Vector3(0, 0, voxel_size))
					st.add_vertex(base_pos + Vector3(0, voxel_size, voxel_size))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, voxel_size))
					
					# Right face
					st.set_normal(Vector3(1, 0, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, 0, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, 0, voxel_size))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, voxel_size))
					st.add_vertex(base_pos + Vector3(voxel_size, 0, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, voxel_size))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, 0))
					
					# Left face
					st.set_normal(Vector3(-1, 0, 0))
					st.add_vertex(base_pos + Vector3(0, 0, 0))
					st.add_vertex(base_pos + Vector3(0, voxel_size, voxel_size))
					st.add_vertex(base_pos + Vector3(0, 0, voxel_size))
					st.add_vertex(base_pos + Vector3(0, 0, 0))
					st.add_vertex(base_pos + Vector3(0, voxel_size, 0))
					st.add_vertex(base_pos + Vector3(0, voxel_size, voxel_size))
					
					# Top face
					st.set_normal(Vector3(0, 1, 0))
					st.add_vertex(base_pos + Vector3(0, voxel_size, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, voxel_size))
					st.add_vertex(base_pos + Vector3(0, voxel_size, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, voxel_size, voxel_size))
					st.add_vertex(base_pos + Vector3(0, voxel_size, voxel_size))
					
					# Bottom face
					st.set_normal(Vector3(0, -1, 0))
					st.add_vertex(base_pos + Vector3(0, 0, 0))
					st.add_vertex(base_pos + Vector3(voxel_size, 0, voxel_size))
					st.add_vertex(base_pos + Vector3(voxel_size, 0, 0))
					st.add_vertex(base_pos + Vector3(0, 0, 0))
					st.add_vertex(base_pos + Vector3(0, 0, voxel_size))
					st.add_vertex(base_pos + Vector3(voxel_size, 0, voxel_size))
	
	return st.commit()

## Mesh Update
func update_mesh():
	var mesh = generate_simple_mesh()
	mesh_instance.mesh = mesh

func _exit_tree():
	# Cleanup resources if needed
	pass
