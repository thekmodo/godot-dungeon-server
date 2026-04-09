extends Node3D

@export var cell_size: float = 2.0
@export var wall_height: float = 2.0
@export var map_path: String = "res://../content/maps/dev_map.json"

const MapLoaderScript := preload("res://scripts/content/map_loader.gd")

var _map := [
	"##########",
	"#........#",
	"#..####..#",
	"#..#..#..#",
	"#..#..#..#",
	"#..####..#",
	"#........#",
	"##########",
]

func _ready() -> void:
	_try_load_map()
	_build()

func _try_load_map() -> void:
	var data := MapLoaderScript.load_map_json(map_path)
	if data.is_empty():
		return
	if int(data.get("format_version", 0)) != 1:
		return
	var grid = data.get("grid", null)
	if typeof(grid) != TYPE_ARRAY or grid.size() == 0:
		return
	_map = []
	for row in grid:
		_map.append(String(row))
	cell_size = float(data.get("cell_size", cell_size))
	wall_height = float(data.get("wall_height", wall_height))

func _build() -> void:
	# Simple grid-based walls; floor is handled by the scene's large collider.
	for z in _map.size():
		var row: String = _map[z]
		for x in row.length():
			if row[x] == "#":
				_add_wall_cell(x, z)

func _add_wall_cell(x: int, z: int) -> void:
	var wall := StaticBody3D.new()
	wall.name = "Wall_%d_%d" % [x, z]
	add_child(wall)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(cell_size, wall_height, cell_size)
	mesh.mesh = box
	mesh.position = Vector3(0, wall_height * 0.5, 0)
	wall.add_child(mesh)

	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(cell_size, wall_height, cell_size)
	collider.shape = shape
	collider.position = Vector3(0, wall_height * 0.5, 0)
	wall.add_child(collider)

	wall.position = Vector3(x * cell_size, 0, z * cell_size)

