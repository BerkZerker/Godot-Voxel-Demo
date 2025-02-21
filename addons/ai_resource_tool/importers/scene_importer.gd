@tool
extends "./base_importer.gd"

const Handlers = preload("../handlers.gd")

func import_resource(json_path: String, output_path: String) -> bool:
    var json = read_json_file(json_path)
    if not json:
        return false
        
    var handler = Handlers.create_handler("Scene")
    if not handler:
        push_error("Failed to create scene handler")
        return false
        
    var resource = handler.create_resource(json)
    if not resource:
        push_error("Failed to create scene resource")
        return false
        
    if handler.save_resource(resource, output_path):
        log_success("Successfully created scene: " + output_path)
        return true
    else:
        log_error("Failed to save scene to: " + output_path)
        return false