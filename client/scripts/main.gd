extends Node3D

@onready var player: CharacterBody3D = $Player

func _ready() -> void:
	_ensure_input_actions()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ensure_input_actions() -> void:
	const deadzone := 0.5
	_bind_key("move_forward", KEY_W, deadzone)
	_bind_key("move_back", KEY_S, deadzone)
	_bind_key("move_left", KEY_A, deadzone)
	_bind_key("move_right", KEY_D, deadzone)
	_bind_key("interact", KEY_E, deadzone)
	if not InputMap.has_action("ui_cancel"):
		InputMap.add_action("ui_cancel", deadzone)
		var esc := InputEventKey.new()
		esc.keycode = KEY_ESCAPE
		InputMap.action_add_event("ui_cancel", esc)

func _bind_key(action: StringName, keycode: Key, deadzone: float) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action, deadzone)
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var mode := Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)

