@tool
extends Node

const Handlers = preload("res://addons/ai_resource_tool/handlers.gd")

# Legacy tilemap import support
func import_tilemap(json_path: String, output_path: String):
    var file = FileAccess.open(json_path, FileAccess.READ)
    if not file:
        push_error("Failed to open file: " + json_path)
        return
        
    var data = JSON.parse_string(file.get_as_text())
    if not data:
        push_error("Failed to parse JSON from: " + json_path)
        return
        
    if not FileAccess.file_exists(data["tileset"]):
        push_error("Tileset not found: " + data["tileset"])
        return
        
    # Create the TileMap as root
    var tilemap = TileMap.new()
    tilemap.name = "TileMap"
    
    # Load and set the tileset
    var tileset = load(data["tileset"])
    tilemap.tile_set = tileset
    
    # Create a new TileMapLayer
    var layer = TileMapLayer.new()
    layer.name = "Layer0"
    tilemap.add_child(layer)
    layer.owner = tilemap
    
    # Default to source_id 0 if not specified in JSON
    var source_id = data.get("source_id", 0)
    var atlas_coords = data.get("atlas_coords", Vector2i(0, 0))
    
    # Fill the tilemap with the specified pattern
    for y in range(len(data["tile_data"])):
        for x in range(len(data["tile_data"][y])):
            # Only place tile if the value is not -1 (empty tile)
            if data["tile_data"][y][x] != -1:
                layer.set_cell(Vector2i(x, y), source_id, atlas_coords)
    
    var scene = PackedScene.new()
    scene.pack(tilemap)
    ResourceSaver.save(scene, output_path)
    log_success("TileMap with TileMapLayer saved to: " + output_path)

# Generic resource import using new handler system
func import_resource(json_path: String, output_path: String, resource_class: String) -> bool:
    var file = FileAccess.open(json_path, FileAccess.READ)
    if not file:
        push_error("Failed to open file: " + json_path)
        return false
        
    var json = JSON.parse_string(file.get_as_text())
    if not json:
        push_error("Failed to parse JSON from: " + json_path)
        return false
    
    var handler = Handlers.create_handler(resource_class)
    if not handler:
        push_error("No handler found for resource class: " + resource_class)
        return false
    
    var resource = handler.create_resource(json)
    if not resource:
        return false
    
    return handler.save_resource(resource, output_path)

# Write errors to a log file for AI feedback
func log_error(message: String):
    var dir = DirAccess.open("res://")
    if !dir.dir_exists("logs"):
        dir.make_dir("logs")
        
    var log_file = FileAccess.open("res://logs/import_log.txt", FileAccess.WRITE)
    if log_file:
        log_file.store_line("Error: " + message)
        log_file.close()

# Write success messages to log file
func log_success(message: String):
    var dir = DirAccess.open("res://")
    if !dir.dir_exists("logs"):
        dir.make_dir("logs")
        
    var log_file = FileAccess.open("res://logs/import_log.txt", FileAccess.WRITE)
    if log_file:
        log_file.store_line("Success: " + message)
        log_file.close()