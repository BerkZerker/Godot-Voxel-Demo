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

# Face direction constants
const FACE_AXES = {
	"FRONT": {"axis": "Z", "normal": Vector3i(0, 0, -1), "color": Color(1.0, 1.0, 1.0)},
	"BACK": {"axis": "Z", "normal": Vector3i(0, 0, 1), "color": Color(0.95, 0.95, 0.95)},
	"RIGHT": {"axis": "X", "normal": Vector3i(1, 0, 0), "color": Color(0.9, 0.9, 0.9)},
	"LEFT": {"axis": "X", "normal": Vector3i(-1, 0, 0), "color": Color(0.85, 0.85, 0.85)},
	"TOP": {"axis": "Y", "normal": Vector3i(0, 1, 0), "color": Color(1.0, 1.0, 1.0)},
	"BOTTOM": {"axis": "Y", "normal": Vector3i(0, -1, 0), "color": Color(0.8, 0.8, 0.8)}
}

## Static Resource Management
static func _setup_shared_material():
	if !shared_material:
		shared_material = StandardMaterial3D.new()
		shared_material.albedo_color = Color(0.95, 0.95, 0.95)
		shared_material.metallic_specular = 0.1
		shared_material.roughness = 1.0
		shared_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		shared_material.vertex_color_use_as_albedo = true
		shared_material.cull_mode = BaseMaterial3D.CULL_DISABLED # Disable face culling

## Lifecycle Methods
func _ready():
	_setup_shared_material()
	
	if has_node("/root/SettingsManager"):
		settings_manager = get_node("/root/SettingsManager")
		chunk_size = settings_manager.get_chunk_size()
	else:
		push_error("SettingsManager not found! Using default values.")
	
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
	voxel_data.resize(chunk_size * chunk_size * chunk_size)
	voxel_data.fill(VoxelType.AIR)
	
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.material_override = shared_material
	
	generate_terrain()

## Terrain Generation
func generate_terrain():
	if !world_generator:
		push_error("Cannot generate terrain: WorldGenerator not found!")
		return
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var world_x = (chunk_position.x * chunk_size + x)
				var world_y = (chunk_position.y * chunk_size + y)
				var world_z = (chunk_position.z * chunk_size + z)
				
				var value = world_generator.get_voxel_value(world_x, world_y, world_z)
				var voxel_pos = Vector3i(x, y, z)
				set_voxel(voxel_pos, VoxelType.SOLID if value > 0 else VoxelType.AIR)
	
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

## 3D Greedy Meshing Implementation
func create_2d_mask(axis: String, layer: int) -> Array:
	var mask = []
	var mask_size = chunk_size * chunk_size
	mask.resize(mask_size)
	mask.fill(VoxelType.AIR)
	
	# Fill the mask with solid blocks only
	for i in range(chunk_size):
		for j in range(chunk_size):
			var pos = get_3d_pos(axis, layer, i, j)
			var current_voxel = get_voxel(pos)
			if current_voxel != VoxelType.AIR:
				mask[i + j * chunk_size] = current_voxel
	
	return mask

func get_3d_pos(axis: String, layer: int, i: int, j: int) -> Vector3i:
	match axis:
		"X": return Vector3i(layer, j, i)
		"Y": return Vector3i(i, layer, j)
		"Z": return Vector3i(i, j, layer)
	return Vector3i.ZERO

func get_face_name(axis: String, positive: bool) -> String:
	match axis:
		"X": return "RIGHT" if positive else "LEFT"
		"Y": return "TOP" if positive else "BOTTOM"
		"Z": return "BACK" if positive else "FRONT"
	return ""

func greedy_merge_2d(mask: Array) -> Array:
	var merged = []
	var visited = []
	visited.resize(chunk_size * chunk_size)
	visited.fill(false)
	
	for y in range(chunk_size):
		for x in range(chunk_size):
			if mask[x + y * chunk_size] != VoxelType.AIR && !visited[x + y * chunk_size]:
				var voxel_type = mask[x + y * chunk_size]
				
				# Find maximum width
				var width = 1
				while x + width < chunk_size && \
					  mask[x + width + y * chunk_size] == voxel_type && \
					  !visited[x + width + y * chunk_size]:
					width += 1
				
				# Find maximum height
				var height = 1
				var can_expand = true
				while y + height < chunk_size && can_expand:
					# Check entire row
					for wx in range(width):
						if mask[x + wx + (y + height) * chunk_size] != voxel_type || \
						   visited[x + wx + (y + height) * chunk_size]:
							can_expand = false
							break
					if can_expand:
						height += 1
				
				# Mark as visited
				for vy in range(height):
					for vx in range(width):
						visited[x + vx + (y + vy) * chunk_size] = true
				
				merged.append({
					"x": x,
					"y": y,
					"width": width,
					"height": height,
					"voxel_type": voxel_type
				})
	
	return merged

func generate_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var voxel_size = 1.0 if !settings_manager else settings_manager.get_voxel_size()
	
	# Process each axis (X, Y, Z)
	for axis in ["X", "Y", "Z"]:
		# Process both positive and negative faces
		for is_positive in [true, false]:
			var face_name = get_face_name(axis, is_positive)
			var face_data = FACE_AXES[face_name]
			
			# Process each layer
			for layer in range(chunk_size):
				var mask = create_2d_mask(axis, layer)
				var merged_faces = greedy_merge_2d(mask)
				
				# Generate quads for merged faces
				for face in merged_faces:
					st.set_color(face_data.color)
					st.set_normal(Vector3(face_data.normal))
					
					var base_pos = get_3d_pos(axis, layer, face.x, face.y)
					base_pos = Vector3(base_pos) * voxel_size
					
					var width = face.width * voxel_size
					var height = face.height * voxel_size
					
					var vertices = calculate_face_vertices(
						axis,
						is_positive,
						base_pos,
						width,
						height
					)
					
					# Add vertices in consistent order
					st.add_vertex(vertices[0])
					st.add_vertex(vertices[1])
					st.add_vertex(vertices[2])
					
					st.add_vertex(vertices[0])
					st.add_vertex(vertices[2])
					st.add_vertex(vertices[3])
	
	return st.commit()

func calculate_face_vertices(axis: String, is_positive: bool, base_pos: Vector3, width: float, height: float) -> Array:
	var vertices = []
	match axis:
		"X":
			vertices = [
				base_pos,
				base_pos + Vector3(0, 0, width),
				base_pos + Vector3(0, height, width),
				base_pos + Vector3(0, height, 0)
			]
		"Y":
			vertices = [
				base_pos,
				base_pos + Vector3(width, 0, 0),
				base_pos + Vector3(width, 0, height),
				base_pos + Vector3(0, 0, height)
			]
		"Z":
			vertices = [
				base_pos,
				base_pos + Vector3(width, 0, 0),
				base_pos + Vector3(width, height, 0),
				base_pos + Vector3(0, height, 0)
			]
	return vertices

## Mesh Update
func update_mesh():
	var mesh = generate_mesh()
	mesh_instance.mesh = mesh

func _exit_tree():
	# Cleanup resources if needed
	pass
