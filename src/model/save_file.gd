class_name SaveFile
extends RefCounted
## Reads and writes save files atomically and migrates saves from older versions.
## Payload layout: { "version": int, "saved_at_unix": int, "state": Dictionary }

const VERSION := 3


## Writes to a temp file first, keeps the previous save as .bak, then swaps the files,
## so a crash mid-write never destroys the last good save.
static func write_atomic(path: String, payload: Dictionary) -> Error:
	var tmp_path := path + ".tmp"
	var bak_path := path + ".bak"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error

	if FileAccess.file_exists(path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		var err := DirAccess.rename_absolute(path, bak_path)
		if err != OK:
			return err
	return DirAccess.rename_absolute(tmp_path, path)


## Returns the migrated payload, or {} if the file is missing, unreadable or invalid.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	# A JSON instance reports parse errors quietly; corrupt saves are an expected case.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	if not json.data is Dictionary:
		return {}
	return migrate(json.data)


## Tries the main save first, then the backup.
static func load_with_fallback(path: String) -> Dictionary:
	var payload := read(path)
	if payload.is_empty():
		payload = read(path + ".bak")
	return payload


## Upgrades an old payload step by step to VERSION. Returns {} for invalid payloads
## and for saves written by a newer app version.
static func migrate(payload: Dictionary) -> Dictionary:
	if not (payload.get("version") is float or payload.get("version") is int):
		return {}
	if not payload.get("state") is Dictionary:
		return {}
	var version := int(payload["version"])
	if version < 1 or version > VERSION:
		return {}
	var result := payload.duplicate(true)
	while version < VERSION:
		result = _migrate_step(version, result)
		version += 1
		result["version"] = version
	if not result.has("saved_at_unix"):
		result["saved_at_unix"] = 0
	return result


## Converts a payload from `from_version` to `from_version + 1`.
static func _migrate_step(from_version: int, payload: Dictionary) -> Dictionary:
	match from_version:
		1:
			# Version 2 gave each location its own business; PlayerState.from_dict reads the
			# old layout too.
			return payload
		2:
			# Version 3 has one tank and one shop per beach; Site.from_dict merges the old tanks
			# and turns the shops built into shop levels.
			return payload
		_:
			push_error("No save migration from version %d" % from_version)
			return payload
