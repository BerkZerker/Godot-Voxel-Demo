@tool
extends "res://addons/ai_resource_tool/handlers/base_resource_handler.gd"
class_name SceneHandler

# Additional required fields for scene data
var _scene_required_fields := [
    "root_type",
    "nodes"
]

# Override validation for scene-specific requirements
func _validate_specific(json_data: Dictionary) -> Dictionary:
    # Check resource class
    if json_data["resource_class"] != "Scene":
        return {
            "valid": false,
            "error": ERROR_INVALID_TYPE,
            "details": "Resource class must be 'Scene', got: " + json_data["resource_class"]
        }
    
    # Check scene-specific required fields
    var scene_data = json_data["data"]
    var missing_fields := []
    for field in _scene_required_fields:
        if not scene_data.has(field):
            missing_fields.append(field)
    
    if missing_fields.size() > 0:
        return {
            "valid": false,
            "error": ERROR_MISSING_REQUIRED,
            "details": "Missing scene fields: " + ", ".join(missing_fields)
        }
    
    return {
        "valid": true
    }

# Override resource creation for scenes
func _create_specific_resource(json_data: Dictionary) -> Resource:
    var scene_data = json_data["data"]
    
    # Create root node
    var root_node = _create_node(scene_data["root_type"])
    if root_node == null:
        push_error("Failed to create root node of type: " + scene_data["root_type"])
        return null
    
    root_node.name = json_data["name"]
    
    # Process child nodes
    for node_data in scene_data["nodes"]:
        var child = _create_node_tree(node_data)
        if child != null:
            root_node.add_child(child)
            child.owner = root_node
    
    # Create packed scene
    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(root_node)
    if result != OK:
        push_error("Failed to pack scene")
        return null
    
    return packed_scene

# Creates a node tree from JSON data
func _create_node_tree(node_data: Dictionary) -> Node:
    # Create the node
    var node = _create_node(node_data["type"])
    if node == null:
        return null
    
    # Set node name
    if node_data.has("name"):
        node.name = node_data["name"]
    
    # Set properties
    if node_data.has("properties"):
        _set_node_properties(node, node_data["properties"])
    
    # Create children
    if node_data.has("children"):
        for child_data in node_data["children"]:
            var child = _create_node_tree(child_data)
            if child != null:
                node.add_child(child)
                child.owner = node
    
    return node

# Creates a single node of the specified type
func _create_node(type: String) -> Node:
    var node = ClassDB.instantiate(type)
    if node == null:
        push_error("Failed to create node of type: " + type)
    return node

# Sets node properties from a dictionary
func _set_node_properties(node: Node, properties: Dictionary) -> void:
    for property in properties:
        var prop_list = node.get_property_list()
        var valid_prop = prop_list.any(func(p):
            return p["name"] == property and (p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE))
        if valid_prop:
            node.set(property, properties[property])
        else:
            push_warning("Property not found or not accessible: " + property)

# Example scene JSON structure:
#{
#    "type": "resource",
#    "resource_class": "Scene",
#    "version": "4.x",
#    "name": "GameScene",
#    "data": {
#        "root_type": "Node2D",
#        "nodes": [
#            {
#                "type": "Sprite2D",
#                "name": "Player",
#                "properties": {
#                    "position": {"x": 100, "y": 100},
#                    "scale": {"x": 2, "y": 2}
#                },
#                "children": []
#            }
#        ]
#    }
#}