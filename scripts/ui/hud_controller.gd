extends Control

# Node references
@onready var fps_label = $DebugInfo/FPSLabel
@onready var chunks_label = $DebugInfo/ChunksLabel
@onready var position_label = $DebugInfo/PositionLabel
@onready var seed_label = $DebugInfo/SeedLabel
@onready var settings_manager = null

# Update interval in seconds
const UPDATE_INTERVAL = 0.1  # Increased update frequency for smoother display
var time_since_update = 0.0

func _ready():
    # Ensure we process every frame for FPS counting
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # Get settings manager
    if has_node("/root/SettingsManager"):
        settings_manager = get_node("/root/SettingsManager")

func _process(delta):
    time_since_update += delta
    if time_since_update >= UPDATE_INTERVAL:
        update_debug_info()
        time_since_update = 0.0
        
    # Update FPS every frame for accuracy
    update_fps()

func update_fps():
    fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func update_debug_info():
    # Update chunk count if TerrainSystem exists
    var terrain_system = get_tree().root.find_child("TerrainSystem", true, false)
    if terrain_system:
        var chunk_manager = terrain_system.get_node("ChunkManager")
        if chunk_manager:
            var chunk_count = chunk_manager.active_chunks.size()
            chunks_label.text = "Active Chunks: %d" % chunk_count
    
    # Update position from player's camera
    var player = get_tree().root.find_child("Player", true, false)
    if player:
        var camera = player.get_node("Camera3D")
        if camera:
            var pos = camera.global_position
            position_label.text = "Position: (%.1f, %.1f, %.1f)" % [pos.x, pos.y, pos.z]
    
    # Update seed display
    if settings_manager:
        var current_seed = settings_manager.get_noise_seed()
        var custom_seed = settings_manager.get_custom_seed()
        if custom_seed >= 0:
            seed_label.text = "Seed: %d (Custom)" % current_seed
        else:
            seed_label.text = "Seed: %d" % current_seed