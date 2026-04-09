extends Node3D

var target_pos: Vector3
var target_yaw: float = 0.0

func _ready() -> void:
	target_pos = global_position

func _process(delta: float) -> void:
	# Simple interpolation toward last snapshot target.
	global_position = global_position.lerp(target_pos, clamp(delta * 12.0, 0.0, 1.0))
	rotation.y = lerp_angle(rotation.y, target_yaw, clamp(delta * 12.0, 0.0, 1.0))

