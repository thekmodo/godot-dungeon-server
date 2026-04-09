extends Node

const DEFAULT_PORT := 24567
const MAX_CLIENTS := 8

var _peer: ENetMultiplayerPeer

func _ready() -> void:
	var port := DEFAULT_PORT
	var args := OS.get_cmdline_args()
	var i := args.find("--port")
	if i != -1 and i + 1 < args.size():
		port = int(args[i + 1])
	elif OS.has_environment("DND_PORT"):
		port = int(OS.get_environment("DND_PORT"))
	_start_server(port)

func _start_server(port: int) -> void:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to start server on port %d (err=%d)" % [port, err])
		get_tree().quit(1)
		return

	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("Server listening on %d" % port)

func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: %d" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: %d" % peer_id)
