@tool
extends EditorPlugin

const ToolbarUI = preload("res://addons/ai_resource_tool/ui_elements/toolbar.gd")
const SceneImporter = preload("res://addons/ai_resource_tool/importers/scene_importer.gd")
const TilemapImporter = preload("res://addons/ai_resource_tool/importers/tilemap_importer.gd")

var toolbar_ui

func _enter_tree():
    # Initialize UI
    toolbar_ui = ToolbarUI.new()
    add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_ui)
    toolbar_ui.connect("import_pressed", Callable(self, "import_all_resources"))
    toolbar_ui.connect("test_pressed", Callable(self, "run_tests"))
    
    print("AI Resource Tool Loaded")

func _exit_tree():
    if toolbar_ui:
        remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_ui)
        toolbar_ui.queue_free()
        toolbar_ui = null
    
    print("AI Resource Tool Unloaded")

func run_tests():
    var test_runner = load("res://addons/ai_resource_tool/tests/run_tests.gd").new()
    test_runner._run()
    test_runner.free()

func import_all_resources():
    var scene_importer = SceneImporter.new()
    var tilemap_importer = TilemapImporter.new()
    
    # Ensure directories exist
    scene_importer.ensure_directories()
    tilemap_importer.ensure_directories()

    # Import scenes
    var import_path = scene_importer.get_import_path()
    var output_path = scene_importer.get_output_path()
    var dir = DirAccess.open(import_path)
    if dir:
        for file in dir.get_files():
            if file.ends_with("_scene.json") or file == "test_scene.json":
                var json_path = import_path.path_join(file)
                var out_path = output_path.path_join(file.replace(".json", ".tscn"))
                scene_importer.import_resource(json_path, out_path)

    # Import tilemaps
    tilemap_importer.import_resource(import_path.path_join("tilemap.json"), output_path.path_join("tilemap.tscn"))