extends CharacterBody3D

const MoveModelScript := preload("res://scripts/move_model.gd")

@export var move_speed: float = 5.0
@export var gravity: float = 18.0

var peer_id: int = 0
var yaw: float = 0.0
var pitch: float = 0.0
var last_processed_seq: int = 0

var _pending: Array = []

func enqueue_input(seq: int, move_x: float, move_y: float, yaw_in: float, pitch_in: float, buttons: int) -> void:
	_pending.append({"seq": seq, "mx": move_x, "my": move_y, "yaw": yaw_in, "pitch": pitch_in, "buttons": buttons})

func server_tick(dt: float) -> void:
	for item in _pending:
		var seq := int(item["seq"])
		if seq <= last_processed_seq:
			continue
		yaw = float(item["yaw"])
		pitch = float(item["pitch"])
		rotation.y = yaw
		MoveModelScript.step(self, yaw, float(item["mx"]), float(item["my"]), dt, move_speed, gravity)
		last_processed_seq = seq
	_pending.clear()

