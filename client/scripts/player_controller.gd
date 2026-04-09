extends CharacterBody3D

@export var mouse_sensitivity: float = 0.0025
@export var move_speed: float = 5.0
@export var gravity: float = 18.0
@export var allow_local_movement: bool = true

@onready var camera_pivot: Node3D = $CameraPivot

var _yaw: float = 0.0
var _pitch: float = 0.0

func _ready() -> void:
	_yaw = rotation.y
	_pitch = camera_pivot.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-85.0), deg_to_rad(85.0))

func _physics_process(delta: float) -> void:
	rotation.y = _yaw
	camera_pivot.rotation.x = _pitch

	if not allow_local_movement:
		return

	var input_vec := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	var basis := global_transform.basis
	var forward := -basis.z
	var right := basis.x
	var wish_dir := (right * input_vec.x + forward * input_vec.y)
	wish_dir.y = 0.0
	if wish_dir.length() > 0.001:
		wish_dir = wish_dir.normalized()

	velocity.x = wish_dir.x * move_speed
	velocity.z = wish_dir.z * move_speed
	velocity.y -= gravity * delta

	move_and_slide()

