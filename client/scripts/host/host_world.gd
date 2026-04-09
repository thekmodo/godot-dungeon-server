extends Node3D

const TICK_HZ := 30.0
const CELL_SIZE := 2.0

@export var player_scene: PackedScene = preload("res://scenes/host_player.tscn")

var _tick_accum := 0.0
var _players_by_peer: Dictionary = {}

var _blocks: Array[Vector2i] = []
var _plates: Array[Vector2i] = []
var _door_open: bool = false
var _invite: String = "dev"

func reset_for_host(invite: String) -> void:
	_invite = invite
	_blocks = [Vector2i(4, 4), Vector2i(5, 4)]
	_plates = [Vector2i(7, 4), Vector2i(7, 5)]
	_door_open = false

func _physics_process(delta: float) -> void:
	_tick_accum += delta
	var tick_dt := 1.0 / TICK_HZ
	while _tick_accum >= tick_dt:
		_tick_accum -= tick_dt
		for peer_id in _players_by_peer.keys():
			_players_by_peer[peer_id].server_tick(tick_dt)

func spawn_player(peer_id: int) -> void:
	var p = player_scene.instantiate()
	p.peer_id = peer_id
	p.global_position = Vector3(2 + peer_id * 1.5, 1, 2)
	add_child(p)
	_players_by_peer[peer_id] = p

func despawn_player(peer_id: int) -> void:
	if _players_by_peer.has(peer_id):
		_players_by_peer[peer_id].queue_free()
		_players_by_peer.erase(peer_id)

func enqueue_player_input(peer_id: int, seq: int, move_x: float, move_y: float, yaw: float, pitch: float, buttons: int) -> void:
	if not _players_by_peer.has(peer_id):
		return
	_players_by_peer[peer_id].enqueue_input(seq, move_x, move_y, yaw, pitch, buttons)

func try_push(peer_id: int) -> void:
	if not _players_by_peer.has(peer_id):
		return
	var p = _players_by_peer[peer_id]
	var fwd := Vector2.ZERO
	var yaw := wrapf(p.yaw, -PI, PI)
	if abs(yaw) < PI * 0.25:
		fwd = Vector2(0, -1)
	elif yaw >= PI * 0.25 and yaw < PI * 0.75:
		fwd = Vector2(1, 0)
	elif yaw <= -PI * 0.25 and yaw > -PI * 0.75:
		fwd = Vector2(-1, 0)
	else:
		fwd = Vector2(0, 1)

	var player_cell := Vector2i(int(round(p.global_position.x / CELL_SIZE)), int(round(p.global_position.z / CELL_SIZE)))
	var src := player_cell + Vector2i(int(fwd.x), int(fwd.y))
	var dst := src + Vector2i(int(fwd.x), int(fwd.y))

	var idx := _blocks.find(src)
	if idx == -1:
		return
	if _blocks.has(dst):
		return
	_blocks[idx] = dst
	_recompute_puzzle()

func _recompute_puzzle() -> void:
	var satisfied := 0
	for plate in _plates:
		if _blocks.has(plate):
			satisfied += 1
	_door_open = (satisfied == _plates.size())

func build_snapshot() -> Dictionary:
	var players_state: Array = []
	var last_input_seq_by_peer: Dictionary = {}
	for peer_id in _players_by_peer.keys():
		var p = _players_by_peer[peer_id]
		players_state.append({"peer_id": peer_id, "pos": p.global_position, "vel": p.velocity, "yaw": p.yaw, "pitch": p.pitch})
		last_input_seq_by_peer[peer_id] = p.last_processed_seq
	return {
		"server_time_ms": Time.get_ticks_msec(),
		"last_input_seq_by_peer": last_input_seq_by_peer,
		"players_state": players_state,
		"puzzle_state": {"blocks": _blocks, "plates": _plates, "door_open": _door_open}
	}

