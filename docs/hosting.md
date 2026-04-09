## Hosting (friend-hosted)

### v0 approach
Run the dedicated server app, then everyone connects from the client using the host’s IP and port.

### Server (dedicated)
- Project: `server/` (Godot headless build target)
- Default port: `24567`
- Custom port:
  - Command line: `--port 24567`
  - Or env var: `DND_PORT=24567`

### Client
- Join by `host:port` (example `127.0.0.1:24567` for same-machine testing).
- The menu shows **Ping** and **Jitter** once connected.

### Port forwarding (common issue)
If players outside your LAN can’t connect, the host needs to forward UDP port `24567` (or your chosen port) on their router to their PC.

