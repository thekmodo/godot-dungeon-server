extends Node

const SNAPSHOT_HZ := 15.0

var _world: Node3D
var _snap_accum := 0.0

func enable_for_world(world: Node3D) -> void:
	_world = world
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _physics_process(delta: float) -> void:
	if _world == null:
		return
	_snap_accum += delta
	if _snap_accum >= (1.0 / SNAPSHOT_HZ):
		_snap_accum = 0.0
		var snap := _world.build_snapshot()
		rpc_unreliable("snapshot", snap["server_time_ms"], snap["last_input_seq_by_peer"], snap["players_state"], snap["puzzle_state"])

func _on_peer_connected(peer_id: int) -> void:
	_world.spawn_player(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	_world.despawn_player(peer_id)

@rpc("any_peer", "unreliable_ordered")
func input_frame(seq: int, client_time_ms: int, move_x: float, move_y: float, yaw: float, pitch: float, buttons: int) -> void:
	if _world == null:
		return
	var from_peer := multiplayer.get_remote_sender_id()
	_world.enqueue_player_input(from_peer, seq, move_x, move_y, yaw, pitch, buttons)
	if (buttons & 1) != 0:
		_world.try_push(from_peer)

@rpc("any_peer", "reliable")
func ping(sent_ms: int) -> void:
	rpc_id(multiplayer.get_remote_sender_id(), "pong", sent_ms, Time.get_ticks_msec())

@rpc("authority", "unreliable")
func snapshot(server_time_ms: int, last_input_seq_by_peer: Dictionary, players_state: Array, puzzle_state: Dictionary) -> void:
	# Server only.
	pass

@rpc("authority", "reliable")
func pong(sent_ms: int, server_recv_ms: int) -> void:
	# Server only.
	pass

