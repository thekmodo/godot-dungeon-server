## Content format (v0)

Goal: make maps and character data importable without changing core engine code. All content is **versioned**, **file-driven**, and validated at load time with safe fallbacks.

### Folder layout
- `content/maps/*.json`
- `content/characters/*.json`

### Map JSON (v0)
File: `content/maps/<map_id>.json`

```json
{
  "format_version": 1,
  "map_id": "dev_map",
  "cell_size": 2.0,
  "wall_height": 2.0,
  "grid": [
    "##########",
    "#........#",
    "#..####..#",
    "#..#..#..#",
    "#..#..#..#",
    "#..####..#",
    "#........#",
    "##########"
  ],
  "spawns": [{ "id": "start", "x": 2, "z": 2, "y": 1.0, "yaw": 0.0 }],
  "puzzle": {
    "type": "pressure_plate_blocks",
    "blocks": [{ "x": 4, "z": 4 }, { "x": 5, "z": 4 }],
    "plates": [{ "x": 7, "z": 4 }, { "x": 7, "z": 5 }]
  }
}
```

### Character JSON (v0)
File: `content/characters/<character_id>.json`

```json
{
  "format_version": 1,
  "character_id": "keller_fighter",
  "display_name": "Keller",
  "class": "Fighter",
  "level": 3,
  "stats": { "str": 16, "dex": 12, "con": 14, "int": 10, "wis": 10, "cha": 8 }
}
```

