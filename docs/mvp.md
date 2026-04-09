## MVP feature spec (one playable session)

### Goal
Run a single D&D “dungeon instance” that up to **5** friends can join, explore in **first-person**, and solve at least one **moving-piece puzzle**, with smooth “light real-time” movement on home-hosted internet.

### Non-goals (MVP)
- Full VTT (character sheets, dice, initiative, chat, handouts)
- Complex lighting/shadows; advanced materials
- NAT traversal/relay service (host will port-forward or use VPN)
- In-app content editor (authoring stays file-driven)

### Roles & permissions
- **Host (GM)**:
  - Start/stop server, load/save instance.
  - Can open/close doors, reset puzzle, move puzzle pieces (admin actions).
- **Player**:
  - Move/look, interact with permitted objects, push/pull puzzle pieces if allowed.

### Player loop (MVP)
- Launch client → Join by IP:port + invite code → Spawn in dungeon → Move/look → Interact (doors/levers) → Solve a moving-piece puzzle → Host can save state.

### World & rendering (MVP)
- **Representation**: grid-based “2.5D” dungeon (orthogonal walls), rendered with simple meshes and textures.
- **Visuals**:
  - Wall/floor/ceiling textures (simple “Doomlike” look).
  - Basic directional + ambient lighting; no dynamic shadows required.
- **Entities**:
  - Players, doors, buttons/levers, moving blocks, goal trigger.

### Movement (MVP)
- **First-person** WASD + mouse look.
- Collision against walls and entities.
- Sprint/crouch optional (skip if it complicates networking).
- Movement should feel good at 100–250ms RTT via prediction/reconciliation.

### Puzzle: “pressure-plate blocks” (MVP)
- Components:
  - 2–4 pushable blocks on a floor grid.
  - 2–4 pressure plates.
  - A door or exit that unlocks when plates are satisfied.
- Rules:
  - Blocks move one cell at a time (grid push) to keep networking simple.
  - Server validates moves and resolves collisions.
- Replication:
  - Block positions replicated as authoritative state.

### Session/room (MVP)
- Host starts server, chooses:
  - Map file
  - Invite code / password (simple shared secret)
- Client joins:
  - IP:port
  - Invite code
  - Display current ping

### Persistence (MVP)
- Host can **save** and **load**:
  - Current map ID/version
  - Puzzle state (block positions, plates satisfied, door open)
  - Player spawn points (optionally last known positions)
- Stored as a JSON file on host machine.

### “Feels good” performance targets
- Client render: 60+ FPS on modest PCs.
- Server sim tick: 30 Hz.
- Snapshot rate: 15 Hz (tunable).
- Remote players interpolated; local player predicted.

