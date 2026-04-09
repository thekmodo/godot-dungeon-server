extends RefCounted
class_name MoveModel

static func step(body: CharacterBody3D, yaw: float, move_x: float, move_y: float, delta: float, move_speed: float, gravity: float) -> void:
	var forward := -body.global_transform.basis.z
	var right := body.global_transform.basis.x
	var wish_dir := (right * move_x + forward * move_y)
	wish_dir.y = 0.0
	if wish_dir.length() > 1.0:
		wish_dir = wish_dir.normalized()

	body.velocity.x = wish_dir.x * move_speed
	body.velocity.z = wish_dir.z * move_speed
	body.velocity.y -= gravity * delta
	body.move_and_slide()

