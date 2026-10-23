extends GutTest

const DIR := "user://test_saves"
const PATH := DIR + "/save.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for file_name in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file_name))


func _payload(money: float) -> Dictionary:
	return {"version": SaveFile.VERSION, "saved_at_unix": 1000, "state": {"money": money}}


func test_write_then_read() -> void:
	assert_eq(SaveFile.write_atomic(PATH, _payload(42.0)), OK)
	var loaded := SaveFile.read(PATH)
	assert_eq(loaded["state"]["money"], 42.0)
	assert_eq(int(loaded["saved_at_unix"]), 1000)
	assert_false(FileAccess.file_exists(PATH + ".tmp"))


func test_second_write_keeps_previous_save_as_backup() -> void:
	SaveFile.write_atomic(PATH, _payload(1.0))
	SaveFile.write_atomic(PATH, _payload(2.0))
	assert_eq(SaveFile.read(PATH)["state"]["money"], 2.0)
	assert_eq(SaveFile.read(PATH + ".bak")["state"]["money"], 1.0)


func test_falls_back_to_backup_when_main_save_is_corrupt() -> void:
	SaveFile.write_atomic(PATH, _payload(1.0))
	SaveFile.write_atomic(PATH, _payload(2.0))
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()

	assert_eq(SaveFile.read(PATH), {})
	assert_eq(SaveFile.load_with_fallback(PATH)["state"]["money"], 1.0)


func test_missing_file_reads_as_empty() -> void:
	assert_eq(SaveFile.load_with_fallback(PATH), {})


func test_rejects_saves_from_newer_versions() -> void:
	var payload := _payload(1.0)
	payload["version"] = SaveFile.VERSION + 1
	assert_eq(SaveFile.migrate(payload), {})


func test_rejects_payload_without_state() -> void:
	assert_eq(SaveFile.migrate({"version": SaveFile.VERSION}), {})
