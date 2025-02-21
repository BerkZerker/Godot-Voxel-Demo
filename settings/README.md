# Game Settings System

## Overview
The game uses a centralized settings system that controls various aspects of gameplay, world generation, and graphics. All settings are stored in `game_settings.tres` and can be modified to adjust the game behavior.

## Available Settings

### World Settings
- `chunk_size`: Size of each chunk in voxels (default: 16)
- `world_size_x/y/z`: Total number of chunks to generate in each direction (default: 3)
  - Example: world_size_x = 1 generates exactly one chunk
  - Example: world_size_x = 3 generates three chunks, centered around origin (-1, 0, 1)
  - Values are clamped between 1 and 32 chunks
- `render_distance`: Distance for chunk loading (default: 2)

### Player Settings
- `movement_speed`: Base movement speed (default: 10.0)
- `sprint_speed`: Speed when sprinting (default: 20.0)
- `mouse_sensitivity`: Mouse look sensitivity (default: 0.002)

### Graphics Settings
- `ambient_light_energy`: Intensity of ambient lighting (default: 0.5)
- `directional_light_energy`: Intensity of directional light (default: 0.2)

### Terrain Generation Settings
- `noise_seed`: Seed for terrain generation (default: 12345)
- `noise_frequency`: Frequency of terrain noise (default: 0.05)
- `terrain_threshold`: Threshold for solid voxels (default: 0.2)

## How to Modify Settings

1. Open the project in Godot Editor
2. Navigate to `settings/game_settings.tres`
3. Modify values in the Inspector panel
4. Save the resource file
5. Re-run the game to apply changes

### World Size Examples:
```
world_size_x = 1, world_size_y = 1, world_size_z = 1
- Generates exactly one chunk at (0,0,0)
- Total chunks: 1

world_size_x = 3, world_size_y = 3, world_size_z = 3
- Generates chunks from -1 to +1 in each direction
- Centered around origin (0,0,0)
- Total chunks: 27

world_size_x = 2, world_size_y = 2, world_size_z = 2
- Generates chunks centered around origin
- From (-0.5,-0.5,-0.5) to (0.5,0.5,0.5)
- Total chunks: 8
```

## Technical Details
- Settings are managed by the `SettingsManager` autoload singleton
- Settings are defined in `scripts/resources/game_settings.gd`
- Default values are stored in `settings/game_settings.tres`
- All game systems reference these settings at runtime
- Systems include fallback values if settings are unavailable
