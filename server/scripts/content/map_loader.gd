extends RefCounted
class_name MapLoader

static func load_map_json(map_path: String) -> Dictionary:
	if not FileAccess.file_exists(map_path):
		push_warning("Map file missing: %s" % map_path)
		return {}
	var f := FileAccess.open(map_path, FileAccess.READ)
	if f == null:
		push_warning("Failed to open map: %s" % map_path)
		return {}
	var txt := f.get_as_text()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Map JSON invalid: %s" % map_path)
		return {}
	return data

