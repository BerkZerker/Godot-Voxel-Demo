@tool
extends SceneTree

func _init():
    # Create a new TileSet
    var tileset = TileSet.new()
    
    # Set grid size to 16x16
    tileset.tile_size = Vector2i(16, 16)
    
    # Add a physics layer
    tileset.add_physics_layer()
    
    # Add a source
    var atlas_source = TileSetAtlasSource.new()
    tileset.add_source(atlas_source)
    
    # Create a simple tile
    atlas_source.texture_region_size = Vector2i(16, 16)
    atlas_source.create_tile(Vector2i(0, 0))
    
    # Create the resources directory if it doesn't exist
    DirAccess.make_dir_recursive_absolute("res://resources")
    
    # Save the tileset
    var err = ResourceSaver.save(tileset, "res://resources/basic_tileset.tres")
    print("Tileset saved: ", err == OK)
    
    quit()