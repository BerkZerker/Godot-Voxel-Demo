@tool
extends Node

const BaseResourceHandler = preload("res://addons/ai_resource_tool/handlers/base_resource_handler.gd")
const SceneHandler = preload("res://addons/ai_resource_tool/handlers/scene_handler.gd")

static func create_handler(resource_class: String) -> BaseResourceHandler:
    match resource_class.to_lower():
        "scene":
            return SceneHandler.new()
        _:
            push_error("Unknown resource class: " + resource_class)
            return null