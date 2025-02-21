extends Node

var noise = FastNoiseLite.new()
const CHUNK_SIZE = 16

func _ready():
    # Configure noise
    noise.seed = 12345  # Seed for consistent terrain
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = 0.05

func get_voxel_value(x: int, y: int, z: int) -> float:
    # Get the 3D noise value for this X/Y/Z position
    var noise_value = noise.get_noise_3d(x, y, z)
    return noise_value