## Networking protocol (v0)

This document defines the on-wire message schema and authority rules for a **small (≤5 players)** session, with server-authoritative simulation, client prediction for local movement, and interpolation for remote players.

### Transport
- **Godot high-level multiplayer** over **ENet** (`ENetMultiplayerPeer`).
- Server listens on a UDP port (default `24567`).
- Clients connect with IP:port, then send an invite code for admission.

### Authority rules
- **Server authoritative** for:
  - Player transforms (position/velocity/yaw/pitch)
  - Collision and movement validation
  - Puzzle entities (doors, blocks, plates)
- **Client authoritative** only for:
  - Raw input collection (WASD, mouse delta)
  - Camera smoothing / presentation

### Tick & rates (defaults)
- **Server sim tick**: 30 Hz (dt = 33.33ms)
- **Client input send rate**: 30 Hz (coalesced; can burst on input change)
- **Server snapshot send rate**: 15 Hz
- **Interpolation delay**: 100ms (tunable)

### IDs & determinism
- Each replicated entity has a stable **EntityId** (32-bit int).
- Each client has a **PeerId** (Godot peer id) and a server-assigned **PlayerId** (EntityId).
- Input messages carry a monotonically increasing **InputSeq** (uint32) to support reconciliation.

### Message families

#### Connection / admission
- **Client → Server** `rpc_id(1, "hello", client_version, invite_code, display_name)`
  - Server validates invite code.
- **Server → Client** `rpc_id(peer, "welcome", server_time_ms, player_entity_id, snapshot_config)`
  - Includes authoritative config (tick/snapshot rates).
- **Server → All** `rpc("player_joined", player_entity_id, display_name)`
- **Server → All** `rpc("player_left", player_entity_id)`

#### Input (client → server)
Sent at client input rate.

`rpc_id(1, "input_frame", input_seq, client_time_ms, move_x, move_y, yaw, pitch, buttons_bitset)`

- `move_x`, `move_y`: normalized [-1..1]
- `yaw`, `pitch`: absolute angles (preferred) or delta (choose one; v0 uses absolute)
- `buttons_bitset`: jump, interact, sprint, etc.

Server processing:
- Apply in order per-client (`input_seq`).
- Simulate movement with fixed dt.
- Store last processed `input_seq` for each player.

#### State snapshots (server → clients)
Sent at snapshot rate.

`rpc("snapshot", server_time_ms, last_input_seq_by_peer, players_state, puzzle_state)` (unreliable via `@rpc(..., "unreliable")` on `snapshot` in Godot 4.x)

- `players_state`: array of `{entity_id, pos, vel, yaw, pitch}`
- `puzzle_state`: minimal authoritative fields (door open, blocks positions, plate states)
- `last_input_seq_by_peer`: used by clients to reconcile local prediction

Reliability:
- Use **unreliable** for frequent snapshots; clients interpolate.
- Use **reliable** RPCs for discrete events (door toggled, puzzle reset).

#### Discrete interactions (client → server)
`rpc_id(1, "try_interact", input_seq, target_entity_id, action_type)`

Server validates (distance, LOS, permissions), then:
- Updates authoritative puzzle state
- Broadcasts event via reliable RPC

### Client prediction & reconciliation (movement)
- Client simulates local player immediately using the same movement model.
- Client keeps a ring buffer of `(input_seq, input_state, predicted_transform)`.
- When a snapshot arrives:
  - Extract server authoritative transform for local player.
  - If error exceeds threshold, rewind to server transform at `last_processed_input_seq`, then re-sim buffered inputs forward.

### Remote interpolation
- Maintain a time-ordered buffer of remote snapshots.
- Render remote players at `(render_time = now - interpolation_delay)`.
- Interpolate position and yaw; clamp/warp on large errors.

### Cheat / abuse considerations (friend group baseline)
- Server clamps move input magnitude.
- Server enforces collision and max speed.
- Server rejects interactions out of range or through walls.

