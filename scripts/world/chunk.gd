@tool
extends Node3D

## Enums
enum VoxelType {
	AIR = 0,
	SOLID = 1,
	# Future types like CLEAR can be added here
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

# Face direction constants for greedy meshing
const DIRECTIONS = [
	{"normal": Vector3i(0, 0, -1), "up": Vector3i(0, 1, 0), "right": Vector3i(1, 0, 0), "color": Color(1.0, 1.0, 1.0)},   # Front
	{"normal": Vector3i(0, 0, 1), "up": Vector3i(0, 1, 0), "right": Vector3i(-1, 0, 0), "color": Color(0.95, 0.95, 0.95)}, # Back
	{"normal": Vector3i(1, 0, 0), "up": Vector3i(0, 1, 0), "right": Vector3i(0, 0, 1), "color": Color(0.9, 0.9, 0.9)},    # Right
	{"normal": Vector3i(-1, 0, 0), "up": Vector3i(0, 1, 0), "right": Vector3i(0, 0, -1), "color": Color(0.85, 0.85, 0.85)}, # Left
	{"normal": Vector3i(0, 1, 0), "up": Vector3i(0, 0, 1), "right": Vector3i(1, 0, 0), "color": Color(1.0, 1.0, 1.0)},   # Top
	{"normal": Vector3i(0, -1, 0), "up": Vector3i(0, 0, -1), "right": Vector3i(1, 0, 0), "color": Color(0.8, 0.8, 0.8)}  # Bottom
]

## Static Resource Management
static func _setup_shared_material():
	if !shared_material:
		shared_material = StandardMaterial3D.new()
		shared_material.albedo_color = Color(0.95, 0.95, 0.95)
		shared_material.metallic_specular = 0.1
		shared_material.roughness = 1.0
		shared_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		shared_material.vertex_color_use_as_albedo = true
		shared_material.cull_mode = BaseMaterial3D.CULL_BACK

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
	voxel_data.fill(VoxelType.AIR)  # Fill with air blocks initially
	
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
		return VoxelType.AIR  # Treat out of bounds as air
	
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
	var current_voxel = get_voxel(pos)
	if current_voxel == VoxelType.AIR:
		return false
	
	var neighbor_pos = pos + normal
	var neighbor_voxel = get_voxel(neighbor_pos)
	
	# If neighbor is outside chunk or is air, show face
	if !is_position_valid(neighbor_pos) || neighbor_voxel == VoxelType.AIR:
		return true
	
	return false

## Greedy Meshing Implementation
func generate_greedy_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var voxel_size = 1.0
	if settings_manager:
		voxel_size = settings_manager.get_voxel_size()
	
	# For each direction (face)
	for dir_idx in range(DIRECTIONS.size()):
		var dir_data = DIRECTIONS[dir_idx]
		var normal = dir_data.normal
		var up = dir_data.up
		var right = dir_data.right
		var face_color = dir_data.color
		
		# Create visited mask for face merging
		var mask = []
		mask.resize(chunk_size * chunk_size)
		
		# For each layer in current direction
		for layer in range(chunk_size):
			# Reset the mask for new layer
			mask.fill(false)
			
			# Fill mask for this layer
			for i in range(chunk_size):
				for j in range(chunk_size):
					var pos: Vector3i
					
					# Calculate voxel position based on direction
					match dir_idx:
						0: # Front
							pos = Vector3i(i, j, layer)
						1: # Back
							pos = Vector3i(i, j, chunk_size - 1 - layer)
						2: # Right
							pos = Vector3i(chunk_size - 1 - layer, j, i)
						3: # Left
							pos = Vector3i(layer, j, i)
						4: # Top
							pos = Vector3i(i, chunk_size - 1 - layer, j)
						5: # Bottom
							pos = Vector3i(i, layer, j)
					
					if is_face_visible(pos, normal):
						mask[i + j * chunk_size] = true
			
			# Generate merged faces
			var i = 0
			while i < chunk_size:
				var j = 0
				while j < chunk_size:
					if mask[i + j * chunk_size]:
						# Find width of face that can be merged
						var width = 1
						while i + width < chunk_size and mask[i + width + j * chunk_size]:
							width += 1
						
						# Find height of face that can be merged
						var height = 1
						var can_expand = true
						while j + height < chunk_size and can_expand:
							for w in range(width):
								if !mask[i + w + (j + height) * chunk_size]:
									can_expand = false
									break
							if can_expand:
								height += 1
						
						# Calculate base position for face
						var base_pos: Vector3
						match dir_idx:
							0: # Front
								base_pos = Vector3(i, j, layer)
							1: # Back
								base_pos = Vector3(i, j, chunk_size - layer - 1)
							2: # Right
								base_pos = Vector3(chunk_size - layer - 1, j, i)
							3: # Left
								base_pos = Vector3(layer, j, i)
							4: # Top
								base_pos = Vector3(i, chunk_size - layer - 1, j)
							5: # Bottom
								base_pos = Vector3(i, layer, j)
						
						base_pos *= voxel_size
						
						# Add vertices for merged face with correct winding order
						st.set_color(face_color)
						st.set_normal(Vector3(normal))
						
						var v0: Vector3
						var v1: Vector3
						var v2: Vector3
						var v3: Vector3
						
						match dir_idx:
							0: # Front
								v0 = base_pos
								v1 = base_pos + Vector3(width, 0, 0) * voxel_size
								v2 = base_pos + Vector3(width, height, 0) * voxel_size
								v3 = base_pos + Vector3(0, height, 0) * voxel_size
							1: # Back
								v0 = base_pos + Vector3(width, 0, 0) * voxel_size
								v1 = base_pos
								v2 = base_pos + Vector3(0, height, 0) * voxel_size
								v3 = base_pos + Vector3(width, height, 0) * voxel_size
							2: # Right
								v0 = base_pos
								v1 = base_pos + Vector3(0, 0, width) * voxel_size
								v2 = base_pos + Vector3(0, height, width) * voxel_size
								v3 = base_pos + Vector3(0, height, 0) * voxel_size
							3: # Left
								v0 = base_pos + Vector3(0, 0, width) * voxel_size
								v1 = base_pos
								v2 = base_pos + Vector3(0, height, 0) * voxel_size
								v3 = base_pos + Vector3(0, height, width) * voxel_size
							4: # Top
								v0 = base_pos
								v1 = base_pos + Vector3(width, 0, 0) * voxel_size
								v2 = base_pos + Vector3(width, 0, height) * voxel_size
								v3 = base_pos + Vector3(0, 0, height) * voxel_size
							5: # Bottom
								v0 = base_pos + Vector3(width, 0, 0) * voxel_size
								v1 = base_pos
								v2 = base_pos + Vector3(0, 0, height) * voxel_size
								v3 = base_pos + Vector3(width, 0, height) * voxel_size
						
						# Add triangles
						st.add_vertex(v0)
						st.add_vertex(v1)
						st.add_vertex(v2)
						
						st.add_vertex(v0)
						st.add_vertex(v2)
						st.add_vertex(v3)
						
						# Mark merged area as processed
						for h in range(height):
							for w in range(width):
								mask[i + w + (j + h) * chunk_size] = false
						
						j += height - 1
					j += 1
				i += 1
	
	return st.commit()

## Mesh Update
func update_mesh():
	var mesh = generate_greedy_mesh()
	mesh_instance.mesh = mesh

func _exit_tree():
	# Cleanup resources if needed
	pass
