@tool
extends Node3D

## Chunk Properties
var chunk_position: Vector3i
var voxel_data: Array = []
var mesh_instance: MultiMeshInstance3D
var settings_manager = null
var chunk_size: int = 16  # Default, will be updated from settings

## Lifecycle Methods
func _ready():
    if has_node("/root/SettingsManager"):
        settings_manager = get_node("/root/SettingsManager")
        chunk_size = settings_manager.get_chunk_size()
    else:
        push_error("SettingsManager not found! Using default values.")
    
    initialize_chunk()

## Initialization
func initialize_chunk():
    # Initialize voxel data array
    voxel_data.resize(chunk_size * chunk_size * chunk_size)
    voxel_data.fill(0)  # Fill with air blocks initially

    # Create mesh instance for voxels
    mesh_instance = MultiMeshInstance3D.new()
    add_child(mesh_instance)

    # Setup rendering
    setup_multimesh()

    # Generate initial terrain
    generate_terrain()

## Mesh Setup
func setup_multimesh():
    var multimesh = MultiMesh.new()

    # Create wireframe cube mesh
    var immediate_mesh = ImmediateMesh.new()
    var voxel_size = 1.0
    if settings_manager:
        voxel_size = settings_manager.get_voxel_size()

    # Draw cube edges
    immediate_mesh.clear_surfaces()
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    
    # Front face
    immediate_mesh.surface_add_vertex(Vector3(0, 0, 0))
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, 0, 0))
    
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, 0, 0))
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, voxel_size, 0))
    
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, voxel_size, 0))
    immediate_mesh.surface_add_vertex(Vector3(0, voxel_size, 0))
    
    immediate_mesh.surface_add_vertex(Vector3(0, voxel_size, 0))
    immediate_mesh.surface_add_vertex(Vector3(0, 0, 0))
    
    # Back face
    immediate_mesh.surface_add_vertex(Vector3(0, 0, voxel_size))
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, 0, voxel_size))
    
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, 0, voxel_size))
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, voxel_size, voxel_size))
    
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, voxel_size, voxel_size))
    immediate_mesh.surface_add_vertex(Vector3(0, voxel_size, voxel_size))
    
    immediate_mesh.surface_add_vertex(Vector3(0, voxel_size, voxel_size))
    immediate_mesh.surface_add_vertex(Vector3(0, 0, voxel_size))
    
    # Connecting edges
    immediate_mesh.surface_add_vertex(Vector3(0, 0, 0))
    immediate_mesh.surface_add_vertex(Vector3(0, 0, voxel_size))
    
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, 0, 0))
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, 0, voxel_size))
    
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, voxel_size, 0))
    immediate_mesh.surface_add_vertex(Vector3(voxel_size, voxel_size, voxel_size))
    
    immediate_mesh.surface_add_vertex(Vector3(0, voxel_size, 0))
    immediate_mesh.surface_add_vertex(Vector3(0, voxel_size, voxel_size))
    
    immediate_mesh.surface_end()

    # Configure multimesh with the wireframe mesh
    multimesh.mesh = immediate_mesh
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.instance_count = 0  # Will be updated as voxels are added
    mesh_instance.multimesh = multimesh

    # Setup material for white lines
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 1.0, 1.0)  # Pure white
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.no_depth_test = false
    mesh_instance.material_override = material

## Terrain Generation
func generate_terrain():
    # Generate solid cube - simple solid chunk
    for x in range(chunk_size):
        for y in range(chunk_size):
            for z in range(chunk_size):
                var voxel_pos = Vector3i(x, y, z)
                set_voxel(voxel_pos, 1)  # 1 represents solid voxel

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
        return 0

    var index = get_voxel_index(local_pos)
    return voxel_data[index]

## Utility Methods
func is_position_valid(pos: Vector3i) -> bool:
    return pos.x >= 0 && pos.x < chunk_size && \
           pos.y >= 0 && pos.y < chunk_size && \
           pos.z >= 0 && pos.z < chunk_size

func get_voxel_index(pos: Vector3i) -> int:
    return pos.x + (pos.y * chunk_size * chunk_size) + (pos.z * chunk_size)

## Mesh Update
func update_mesh():
    var visible_voxels = []

    # Count visible voxels
    for x in range(chunk_size):
        for y in range(chunk_size):
            for z in range(chunk_size):
                var pos = Vector3i(x, y, z)
                var voxel_value = get_voxel(pos)
                if voxel_value > 0:
                    visible_voxels.append(pos)

    # Update multimesh
    var multimesh = mesh_instance.multimesh
    multimesh.instance_count = visible_voxels.size()

    # Update transforms
    var i = 0
    var voxel_size = 1.0
    if settings_manager:
        voxel_size = settings_manager.get_voxel_size()
    
    for voxel_pos in visible_voxels:
        var transform = Transform3D()
        transform.origin = Vector3(
            float(voxel_pos.x) * voxel_size,
            float(voxel_pos.y) * voxel_size,
            float(voxel_pos.z) * voxel_size
        )
        multimesh.set_instance_transform(i, transform)
        i += 1

func _exit_tree():
    # Cleanup resources if needed
    pass