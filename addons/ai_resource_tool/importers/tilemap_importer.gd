@tool
extends "./base_importer.gd"

func import_resource(json_path: String, output_path: String) -> bool:
    var json = read_json_file(json_path)
    if not json:
        return false

    # Create tileset if specified
    var tileset_path = json.get("tileset", "")
    var tileset_resource = null
    if tileset_path:
        tileset_resource = create_tileset(tileset_path, json)
        if not tileset_resource:
            return false

    # Create TileMap
    var tilemap = TileMap.new()
    tilemap.tile_set = tileset_resource
    var layer = 0

    # Populate tile data
    var tile_data = json.get("tile_data", [])
    for x in range(tile_data.size()):
        for y in range(tile_data[x].size()):
            var cell_data = tile_data[x][y]
            if cell_data != null:
                var source_id = json.get("source_id", -1)
                var atlas_coords = json.get("atlas_coords", Vector2i(-1, -1))
                var alternative_tile = json.get("alternative_tile", 0)
                tilemap.set_cell(layer, Vector2i(x, y), source_id, atlas_coords, alternative_tile)

    # Save the TileMap
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(tilemap)
    if result != OK:
        log_error("Failed to pack TileMap")
        return false

    if ResourceSaver.save(packed_scene, output_path) == OK:
        log_success("Successfully created TileMap: " + output_path)
        return true
    else:
        log_error("Failed to save TileMap to: " + output_path)
        return false

func create_tileset(tileset_path: String, json: Dictionary) -> Resource:
    # Basic tileset creation (adapt from create_tileset.gd)
    var tileset = TileSet.new()
    tileset.tile_size = Vector2i(16, 16)

    var texture = load("res://icon.svg")  # Default texture
    if not texture:
        log_error("Failed to load default texture for tileset")
        return null

    var source = TileSetAtlasSource.new()
    source.texture = texture
    source.texture_region_size = Vector2i(16, 16)
    source.create_tile(Vector2i(0, 0))  # Single tile at 0,0
    tileset.add_source(source)

    if ResourceSaver.save(tileset, tileset_path) == OK:
        log_success("Successfully created tileset: " + tileset_path)
        return tileset
    else:
        log_error("Failed to save tileset to: " + tileset_path)
        return null