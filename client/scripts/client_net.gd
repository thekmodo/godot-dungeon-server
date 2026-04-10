extends Node

signal status_changed(text: String)
signal metrics_changed(ping_ms: float, jitter_ms: float)

@export var server_host: String = "127.0.0.1"
@export var server_port: int = 24567

const INPUT_HZ := 30.0

const MoveModelScript := preload("res://scripts/move_model.gd")
const RemotePlayerScene := preload("res://scenes/remote_player.tscn")
const BlockScene := preload("res://scenes/puzzle_block.tscn")

var _peer: ENetMultiplayerPeer
var _seq: int = 0
var _send_accum := 0.0
var _ping_accum := 0.0
var _rtts: Array[float] = []
const RTT_WINDOW := 20

@onready var _player: CharacterBody3D = $"../Player"
@onready var _player_controller: Node = _player

var _input_buffer: Array = [] # {seq, yaw, pitch, mx, my}
var _remote_by_peer: Dictionary = {} # peer_id -> Node3D
var _blocks_visual: Array[Node3D] = []
var _last_interact_pressed := false

@onready var _host_world: Node3D = $"../HostWorld"
@onready var _host_net: Node = $"../HostNet"

func _ready() -> void:
	# Disable built-in local movement; we drive predicted movement here.
	if _player_controller and "allow_local_movement" in _player_controller:
		_player_controller.allow_local_movement = false
	status_changed.emit("idle")

func host_local(port: int, invite: String) -> void:
	# v0: Launch the dedicated server as a separate process (same-machine hosting),
	# then the host can join via 127.0.0.1. This keeps authority boundaries clean.
	var server_exe := ProjectSettings.globalize_path("res://../server_build/DND_Dungeon_Server.exe")
	if not FileAccess.file_exists(server_exe):
		status_changed.emit("server exe missing: %s" % server_exe)
		return
	var args := ["--headless", "--port", str(port)]
	var pid := OS.create_process(server_exe, args)
	if pid <= 0:
		status_changed.emit("failed to launch server")
		return
	status_changed.emit("server launched (pid=%d) on %d" % [pid, port])

func join_remote(host: String, port: int, invite: String) -> void:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(host, port)
	if err != OK:
		status_changed.emit("join failed (err=%d)" % err)
		return

	multiplayer.multiplayer_peer = _peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	status_changed.emit("connecting…")

func _on_connected() -> void:
	status_changed.emit("connected")

func _on_connection_failed() -> void:
	status_changed.emit("connection failed")

func _on_server_disconnected() -> void:
	status_changed.emit("disconnected")

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	_send_accum += delta
	var step_dt := 1.0 / INPUT_HZ
	while _send_accum >= step_dt:
		_send_accum -= step_dt
		_send_input_and_predict(step_dt)

	_ping_accum += delta
	if _ping_accum >= 1.0:
		_ping_accum = 0.0
		_send_ping()

func _send_input_and_predict(dt: float) -> void:
	if _player == null:
		return

	var mx := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var my := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")

	var pc: Node3D = _player.get_node_or_null("CameraPivot")
	var yaw := _player.rotation.y
	var pitch := pc.rotation.x if pc else 0.0

	var interact_pressed := Input.is_action_pressed("interact")
	var buttons := 1 if (interact_pressed and not _last_interact_pressed) else 0
	_last_interact_pressed = interact_pressed

	_seq += 1
	rpc_id(1, "input_frame", _seq, Time.get_ticks_msec(), mx, my, yaw, pitch, buttons)

	MoveModelScript.step(_player, yaw, mx, my, dt, _player.move_speed, _player.gravity)

	_input_buffer.append({"seq": _seq, "yaw": yaw, "pitch": pitch, "mx": mx, "my": my})
	if _input_buffer.size() > 256:
		_input_buffer.pop_front()

@rpc("authority", "unreliable")
func snapshot(server_time_ms: int, last_input_seq_by_peer: Dictionary, players_state: Array, puzzle_state: Dictionary) -> void:
	# v0: reconcile only local player.
	var my_peer := multiplayer.get_unique_id()
	var ack_seq := int(last_input_seq_by_peer.get(my_peer, 0))

	for st in players_state:
		var peer_id := int(st.get("peer_id", -1))
		if peer_id != my_peer:
			_upsert_remote(peer_id, st)
			continue

		_player.global_position = st["pos"]
		_player.velocity = st["vel"]
		_player.rotation.y = float(st["yaw"])

		while _input_buffer.size() > 0 and int(_input_buffer[0]["seq"]) <= ack_seq:
			_input_buffer.pop_front()

		for item in _input_buffer:
			var yaw := float(item["yaw"])
			_player.rotation.y = yaw
			MoveModelScript.step(_player, yaw, float(item["mx"]), float(item["my"]), 1.0 / INPUT_HZ, _player.move_speed, _player.gravity)
		break

	_apply_puzzle_state(puzzle_state)

func _send_ping() -> void:
	rpc_id(1, "ping", Time.get_ticks_msec())

@rpc("any_peer", "reliable")
func ping(sent_ms: int) -> void:
	# Server side: respond.
	rpc_id(multiplayer.get_remote_sender_id(), "pong", sent_ms, Time.get_ticks_msec())

@rpc("authority", "reliable")
func pong(sent_ms: int, server_recv_ms: int) -> void:
	var rtt := float(Time.get_ticks_msec() - int(sent_ms))
	_rtts.append(rtt)
	if _rtts.size() > RTT_WINDOW:
		_rtts.pop_front()
	var avg := 0.0
	for v in _rtts:
		avg += v
	avg /= max(1, _rtts.size())
	var var_sum := 0.0
	for v in _rtts:
		var_sum += (v - avg) * (v - avg)
	var jitter := sqrt(var_sum / max(1, _rtts.size()))
	metrics_changed.emit(avg, jitter)

func _apply_puzzle_state(puzzle_state: Dictionary) -> void:
	if puzzle_state == null:
		return
	var blocks: Array = puzzle_state.get("blocks", []) as Array
	# Ensure visuals exist.
	while _blocks_visual.size() < blocks.size():
		var b: Node3D = BlockScene.instantiate()
		b.name = "Block_%d" % _blocks_visual.size()
		get_parent().add_child(b)
		_blocks_visual.append(b)
	# Update positions.
	for i in range(blocks.size()):
		var cell = blocks[i]
		var x := int(cell.x) if cell is Vector2i else int(cell[0])
		var z := int(cell.y) if cell is Vector2i else int(cell[1])
		_blocks_visual[i].global_position = Vector3(x * 2.0, 1.0, z * 2.0)

func _upsert_remote(peer_id: int, st: Dictionary) -> void:
	var rp: Node3D
	if _remote_by_peer.has(peer_id):
		rp = _remote_by_peer[peer_id]
	else:
		rp = RemotePlayerScene.instantiate()
		rp.name = "Remote_%d" % peer_id
		get_parent().add_child(rp)
		_remote_by_peer[peer_id] = rp

	rp.target_pos = st["pos"]
	rp.target_yaw = float(st.get("yaw", 0.0))

