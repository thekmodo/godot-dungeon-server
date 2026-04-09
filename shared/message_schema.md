## Shared message schema notes

These are reference fields used by both `client/` and `server/` implementations.

### InputFrame
- `seq` (uint32): monotonically increasing
- `move_x`, `move_y` (float): [-1..1]
- `yaw`, `pitch` (float): radians
- `buttons` (uint32 bitset)

### PlayerState
- `peer_id` (int): Godot peer id
- `pos` (Vector3)
- `vel` (Vector3)
- `yaw`, `pitch` (float)

