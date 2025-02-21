# AI Resource Tool

## Overview

This Godot plugin allows you to import AI-generated resources (scenes, tilemaps, etc.) into your Godot project. It uses a JSON-based format to define resources and provides a simple interface for importing them.

## Installation

1. Copy the `addons/ai_resource_tool` folder into your Godot project's `addons` folder.
2. In the Godot editor, go to `Project > Project Settings > Plugins`.
3. Enable the "AI Resource Tool" plugin.

## Usage

1. Place your AI-generated JSON files in the `res://ai_generated/` directory (or the directory you configured in Project Settings).
   - Scene files should end with `_scene.json`.
   - Tilemap files should be named `tilemap.json`.
2. In the Godot editor, click the "Import AI Resources" button in the toolbar.
3. The tool will convert the JSON files into Godot resources and place them in the `res://generated_resources/` directory (or the directory you configured).

## Configuration

You can configure the following settings in `Project Settings > General > AI Tool`:

- `ai_tool/import_path`: The directory where the tool will look for JSON files (default: `res://ai_generated/`).
- `ai_tool/output_path`: The directory where the tool will save generated resources (default: `res://generated_resources/`).
- `ai_tool/log_path`: The directory where log files will be stored (default: `user://logs/`).

## Supported Resource Types

- Scenes
- Tilemaps

## JSON Format

### Scene

```json
{
    "type": "resource",
    "resource_class": "Scene",
    "version": "4.x",
    "name": "MyScene",
    "data": {
        "root_type": "Node2D",
        "nodes": [
            {
                "type": "Sprite2D",
                "name": "MySprite",
                "properties": {
                    "position": {"x": 100, "y": 100}
                },
                "children": []
            }
        ]
    }
}
```

### Tilemap

```json
{
    "tileset": "res://path/to/tileset.tres",
    "source_id": 0,
    "atlas_coords": {"x": 0, "y": 0},
    "tile_data": [[...]]
}
```

## Troubleshooting
Check user://logs/ for import_errors.log and import_success.log