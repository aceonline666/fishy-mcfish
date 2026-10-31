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


func test_slots_and_autosave_are_separate_files() -> void:
	assert_eq(SaveSystem.slot_path(1), PATH)
	assert_eq(SaveSystem.slot_path(2), DIR + "/save_2.json")
	assert_eq(SaveSystem.autosave_path(), DIR + "/autosave.json")

	GameState.replace_state(PlayerState.new())
	GameState.add_money(10.0)
	SaveSystem.save_to_slot(2)
	GameState.add_money(5.0)
	SaveSystem.save_to_slot(3)
	GameState.add_money(1.0)
	SaveSystem.save_game()

	assert_false(SaveSystem.has_save(1))
	assert_eq(SaveSystem.slot_info(2)["money"], 10.0)
	assert_eq(SaveSystem.slot_info(3)["money"], 15.0, "autosave left the slot alone")
	assert_true(SaveSystem.slot_info(1).is_empty())

	assert_true(SaveSystem.load_slot(2))
	assert_eq(GameState.state.money, 10.0)
	assert_false(SaveSystem.load_slot(1), "an empty slot cannot be loaded")
	assert_eq(GameState.state.money, 10.0)


func test_startup_resumes_the_autosave_not_a_slot() -> void:
	GameState.replace_state(PlayerState.new())
	GameState.add_money(10.0)
	SaveSystem.save_to_slot(1)
	GameState.add_money(90.0)
	SaveSystem.save_game()

	GameState.replace_state(PlayerState.new())
	SaveSystem.load_game()

	assert_eq(GameState.state.money, 100.0)
	assert_eq(SaveSystem.slot_info(1)["money"], 10.0)


func test_startup_without_autosave_continues_from_an_old_save() -> void:
	GameState.replace_state(PlayerState.new())
	GameState.add_money(42.0)
	SaveSystem.save_to_slot(1)

	GameState.replace_state(PlayerState.new())
	SaveSystem.load_game()

	assert_eq(GameState.state.money, 42.0)


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
