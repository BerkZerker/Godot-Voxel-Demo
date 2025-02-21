@tool
extends "res://addons/ai_resource_tool/tests/test_base.gd"

var BaseResourceHandler = load("res://addons/ai_resource_tool/handlers/base_resource_handler.gd")
var handler

func setup():
    handler = BaseResourceHandler.new()
    add_child(handler)
    
    # Clean up old log file if it exists
    var log_path = "res://logs/resource_handler.log"
    if FileAccess.file_exists(log_path):
        DirAccess.remove_absolute(log_path)

func teardown():
    if handler:
        remove_child(handler)
        handler.queue_free()
        handler = null

func test_validate_json_missing_fields() -> bool:
    var json = {
        "type": "resource"
        # Missing other required fields
    }
    
    var result = handler.validate_json(json)
    return assert_false(result["valid"], "Should fail with missing fields") and \
           assert_equal(result["error"], handler.ERROR_MISSING_REQUIRED, "Should report missing required fields")

func test_validate_json_invalid_type() -> bool:
    var json = {
        "type": "not_a_resource",
        "resource_class": "Scene",
        "version": "4.x",
        "name": "test",
        "data": {}
    }
    
    var result = handler.validate_json(json)
    return assert_false(result["valid"], "Should fail with invalid type") and \
           assert_equal(result["error"], handler.ERROR_INVALID_TYPE, "Should report invalid type")

func test_validate_json_invalid_version() -> bool:
    var json = {
        "type": "resource",
        "resource_class": "Scene",
        "version": "3.x",
        "name": "test",
        "data": {}
    }
    
    var result = handler.validate_json(json)
    return assert_false(result["valid"], "Should fail with invalid version") and \
           assert_equal(result["error"], handler.ERROR_INVALID_VERSION, "Should report invalid version")

func test_validate_json_valid() -> bool:
    var json = {
        "type": "resource",
        "resource_class": "Scene",
        "version": "4.x",
        "name": "test",
        "data": {}
    }
    
    var result = handler.validate_json(json)
    return assert_true(result["valid"], "Should succeed with valid data")

func test_create_resource_invalid_json() -> bool:
    var json = {
        "type": "not_a_resource"
    }
    
    var resource = handler.create_resource(json)
    return assert_null(resource, "Should return null for invalid JSON")

func test_save_resource_null() -> bool:
    return assert_false(handler.save_resource(null, "res://test.tres"), 
                       "Should fail when saving null resource")

func test_log_error() -> bool:
    handler.log_error("Test error")
    var file = FileAccess.open("res://logs/resource_handler.log", FileAccess.READ)
    if not file:
        return false
        
    var content = file.get_as_text()
    file.close()
    return assert_true(content.contains("[Error] Test error"), 
                      "Log file should contain error message")

func test_log_success() -> bool:
    handler.log_success("Test success")
    var file = FileAccess.open("res://logs/resource_handler.log", FileAccess.READ)
    if not file:
        return false
        
    var content = file.get_as_text()
    file.close()
    return assert_true(content.contains("[Success] Test success"), 
                      "Log file should contain success message")