@tool
extends Node3D

## Constants
const CHUNK_SIZE = 16

## Chunk Properties
var chunk_position: Vector3i
var voxel_data: Array = []
var mesh_instance: MultiMeshInstance3D

## Lifecycle Methods
func _ready():
    initialize_chunk()

## Initialization
func initialize_chunk():
    # Initialize voxel data array
    voxel_data.resize(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE)
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

    # Create basic cube mesh
    var mesh = BoxMesh.new()
    mesh.size = Vector3(1, 1, 1)

    # Configure multimesh
    multimesh.mesh = mesh
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.instance_count = 0  # Will be updated as voxels are added
    mesh_instance.multimesh = multimesh

    # Setup default material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 1.0, 1.0) # White color
    mesh_instance.material_override = material

## Terrain Generation
func generate_terrain():
    # Get the world generator from the scene tree
    var world_generator = get_tree().root.find_child("WorldGenerator", true, false)
    if world_generator == null:
        push_error("WorldGenerator not found in scene tree!")
        return

    # Generate voxels based on noise
    for x in range(CHUNK_SIZE):
        for y in range(CHUNK_SIZE):
            for z in range(CHUNK_SIZE):
                var world_x = chunk_position.x * CHUNK_SIZE + x
                var world_y = chunk_position.y * CHUNK_SIZE + y
                var world_z = chunk_position.z * CHUNK_SIZE + z

                # Get the 3D noise value
                var noise_value = world_generator.get_voxel_value(world_x, world_y, world_z)

                # Place voxel if noise value is above threshold
                if noise_value > 0.2: # Adjust threshold as needed
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
    return pos.x >= 0 && pos.x < CHUNK_SIZE && \
           pos.y >= 0 && pos.y < CHUNK_SIZE && \
           pos.z >= 0 && pos.z < CHUNK_SIZE

func get_voxel_index(pos: Vector3i) -> int:
    return pos.x + (pos.y * CHUNK_SIZE * CHUNK_SIZE) + (pos.z * CHUNK_SIZE)

## Mesh Update
func update_mesh():
    var visible_voxels = []

    # Count visible voxels
    for x in range(CHUNK_SIZE):
        for y in range(CHUNK_SIZE):
            for z in range(CHUNK_SIZE):
                var pos = Vector3i(x, y, z)
                var voxel_value = get_voxel(pos)
                if voxel_value > 0:
                    visible_voxels.append(pos)

    # Update multimesh
    var multimesh = mesh_instance.multimesh
    multimesh.instance_count = visible_voxels.size()

    # Update transforms
    var i = 0
    for voxel_pos in visible_voxels:
        var transform = Transform3D()
        transform.origin = Vector3(float(voxel_pos.x), float(voxel_pos.y), float(voxel_pos.z))
        multimesh.set_instance_transform(i, transform)
        i += 1

func _exit_tree():
    # Cleanup resources if needed
    pass