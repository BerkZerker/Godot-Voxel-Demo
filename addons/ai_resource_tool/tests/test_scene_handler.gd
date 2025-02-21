@tool
extends "res://addons/ai_resource_tool/tests/test_base.gd"

var SceneHandler = load("res://addons/ai_resource_tool/handlers/scene_handler.gd")
var handler

func setup():
    handler = SceneHandler.new()
    add_child(handler)

func teardown():
    if handler:
        remove_child(handler)
        handler.queue_free()
        handler = null

func test_validate_json_invalid_resource_class() -> bool:
    var json = {
        "type": "resource",
        "resource_class": "NotAScene",
        "version": "4.x",
        "name": "test",
        "data": {
            "root_type": "Node2D",
            "nodes": []
        }
    }
    
    var result = handler.validate_json(json)
    return assert_false(result["valid"], "Should fail with invalid resource class") and \
           assert_equal(result["error"], handler.ERROR_INVALID_TYPE, "Should report invalid type")

func test_validate_json_missing_scene_fields() -> bool:
    var json = {
        "type": "resource",
        "resource_class": "Scene",
        "version": "4.x",
        "name": "test",
        "data": {
            # Missing required scene fields
        }
    }
    
    var result = handler.validate_json(json)
    return assert_false(result["valid"], "Should fail with missing scene fields") and \
           assert_equal(result["error"], handler.ERROR_MISSING_REQUIRED, "Should report missing required fields")

func test_create_basic_scene() -> bool:
    var json = {
        "type": "resource",
        "resource_class": "Scene",
        "version": "4.x",
        "name": "TestScene",
        "data": {
            "root_type": "Node2D",
            "nodes": []
        }
    }
    
    var resource = handler.create_resource(json)
    return assert_not_null(resource, "Should create scene resource") and \
           assert_true(resource is PackedScene, "Should return a PackedScene")

func test_create_scene_with_children() -> bool:
    var json = {
        "type": "resource",
        "resource_class": "Scene",
        "version": "4.x",
        "name": "TestScene",
        "data": {
            "root_type": "Node2D",
            "nodes": [
                {
                    "type": "Sprite2D",
                    "name": "TestSprite",
                    "properties": {
                        "position": {"x": 100, "y": 100}
                    },
                    "children": []
                }
            ]
        }
    }
    
    var resource = handler.create_resource(json)
    return assert_not_null(resource, "Should create scene with children") and \
           assert_true(resource is PackedScene, "Should return a PackedScene")

func test_create_scene_with_properties() -> bool:
    var json = {
        "type": "resource",
        "resource_class": "Scene",
        "version": "4.x",
        "name": "TestScene",
        "data": {
            "root_type": "Node2D",
            "nodes": [
                {
                    "type": "Label",
                    "name": "TestLabel",
                    "properties": {
                        "text": "Hello World",
                        "horizontal_alignment": 1
                    },
                    "children": []
                }
            ]
        }
    }
    
    var resource = handler.create_resource(json)
    var scene_instance = resource.instantiate()
    var has_label = scene_instance.has_node("TestLabel")
    var label_text = ""
    if has_label:
        label_text = scene_instance.get_node("TestLabel").text
    scene_instance.free()
    
    return assert_not_null(resource, "Should create scene with properties") and \
           assert_true(has_label, "Scene should have a Label node") and \
           assert_equal(label_text, "Hello World", "Label should have correct text")

func test_save_scene() -> bool:
    var json = {
        "type": "resource",
        "resource_class": "Scene",
        "version": "4.x",
        "name": "TestScene",
        "data": {
            "root_type": "Node2D",
            "nodes": []
        }
    }
    
    var resource = handler.create_resource(json)
    var save_path = "res://tests_output/test_scene.tscn"
    
    DirAccess.make_dir_recursive_absolute("res://tests_output")
    var saved = handler.save_resource(resource, save_path)
    
    var file_exists = FileAccess.file_exists(save_path)
    if file_exists:
        DirAccess.remove_absolute(save_path)  # Cleanup
    DirAccess.remove_absolute("res://tests_output")  # Cleanup directory
    
    return assert_true(saved, "Should save successfully") and \
           assert_true(file_exists, "Scene file should exist after save")