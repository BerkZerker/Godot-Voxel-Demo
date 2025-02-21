@tool
extends Node
class_name BaseResourceHandler

# Error codes
const ERROR_INVALID_JSON := "Invalid JSON structure"
const ERROR_MISSING_REQUIRED := "Missing required fields"
const ERROR_INVALID_TYPE := "Invalid resource type"
const ERROR_INVALID_VERSION := "Unsupported Godot version"

# Required fields in JSON
var _required_fields := [
    "type",
    "resource_class",
    "version",
    "name",
    "data"
]

# Abstract method to be implemented by child classes
func _create_specific_resource(_json_data: Dictionary) -> Resource:
    push_error("_create_specific_resource must be implemented by child class")
    return null

# Validates the basic JSON structure
func validate_json(json_data: Dictionary) -> Dictionary:
    # Check if all required fields are present
    var missing_fields := []
    for field in _required_fields:
        if not json_data.has(field):
            missing_fields.append(field)
    
    if missing_fields.size() > 0:
        return {
            "valid": false,
            "error": ERROR_MISSING_REQUIRED,
            "details": "Missing fields: " + ", ".join(missing_fields)
        }
    
    # Validate resource type
    if json_data["type"] != "resource":
        return {
            "valid": false,
            "error": ERROR_INVALID_TYPE,
            "details": "Type must be 'resource', got: " + json_data["type"]
        }
    
    # Validate Godot version
    if json_data["version"] != "4.x":
        return {
            "valid": false,
            "error": ERROR_INVALID_VERSION,
            "details": "Only Godot 4.x is supported, got: " + json_data["version"]
        }
    
    # Additional validation by child class
    return _validate_specific(json_data)

# Abstract method for specific validation by child classes
func _validate_specific(_json_data: Dictionary) -> Dictionary:
    return {
        "valid": true
    }

# Creates a resource from JSON data
func create_resource(json_data: Dictionary) -> Resource:
    # Validate first
    var validation = validate_json(json_data)
    if not validation["valid"]:
        push_error("Validation failed: " + validation["error"] + " - " + validation["details"])
        return null
    
    # Create the specific resource
    var resource = _create_specific_resource(json_data)
    if resource == null:
        push_error("Failed to create resource")
        return null
    
    return resource

# Saves the resource to a file
func save_resource(resource: Resource, path: String) -> bool:
    if resource == null:
        push_error("Cannot save null resource")
        return false
    
    # Create directory if it doesn't exist
    var dir = DirAccess.open("res://")
    var dir_path = path.get_base_dir()
    if not dir.dir_exists(dir_path):
        var err = dir.make_dir_recursive(dir_path)
        if err != OK:
            push_error("Failed to create directory: " + dir_path)
            return false
    
    # Save the resource
    var err = ResourceSaver.save(resource, path)
    if err != OK:
        push_error("Failed to save resource to: " + path)
        return false
    
    return true

# Utility function to log errors
func log_error(message: String) -> void:
    var dir = DirAccess.open("res://")
    if not dir.dir_exists("logs"):
        dir.make_dir("logs")
    
    var log_path = "res://logs/resource_handler.log"
    var log_file
    
    # If file doesn't exist, create it first
    if not FileAccess.file_exists(log_path):
        log_file = FileAccess.open(log_path, FileAccess.WRITE)
    else:
        log_file = FileAccess.open(log_path, FileAccess.READ_WRITE)
        if log_file:
            log_file.seek_end()
    if log_file:
        log_file.store_line("[Error] " + message)
        log_file.close()

# Utility function to log success
func log_success(message: String) -> void:
    var dir = DirAccess.open("res://")
    if not dir.dir_exists("logs"):
        dir.make_dir("logs")
    
    var log_path = "res://logs/resource_handler.log"
    var log_file
    
    # If file doesn't exist, create it first
    if not FileAccess.file_exists(log_path):
        log_file = FileAccess.open(log_path, FileAccess.WRITE)
    else:
        log_file = FileAccess.open(log_path, FileAccess.READ_WRITE)
        if log_file:
            log_file.seek_end()
    if log_file:
        log_file.store_line("[Success] " + message)
        log_file.close()