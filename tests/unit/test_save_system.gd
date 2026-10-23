extends GutTest
## Integration test: the SaveSystem autoload saves and restores GameState.

const DIR := "user://test_save_system"
const PATH := DIR + "/save.json"

var _original_state: PlayerState
var _original_path: String


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for file_name in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file_name))
	_original_state = GameState.state
	_original_path = SaveSystem.save_path
	SaveSystem.save_path = PATH


func after_each() -> void:
	SaveSystem.save_path = _original_path
	GameState.replace_state(_original_state)


func test_test_runs_never_use_the_real_save() -> void:
	assert_ne(_original_path, SaveSystem.SAVE_PATH, "the pre-run hook sandboxes saving")


func test_save_and_load_restores_money() -> void:
	GameState.replace_state(PlayerState.new())
	GameState.add_money(77.0)
	SaveSystem.save_game()

	GameState.replace_state(PlayerState.new())
	SaveSystem.load_game()

	assert_eq(GameState.state.money, 77.0)


func test_unreadable_save_is_kept_aside_not_overwritten() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("garbage")
	file.close()

	SaveSystem.load_game()

	assert_false(FileAccess.file_exists(PATH))
	var kept := Array(DirAccess.get_files_at(DIR)).filter(
		func(file_name: String) -> bool: return file_name.begins_with("save.json.unreadable-"))
	assert_eq(kept.size(), 1)
	assert_eq(GameState.state.money, 0.0)
