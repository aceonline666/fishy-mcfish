extends Node
## Owns the save files. The running game is kept in a hidden autosave that only autosaving
## writes (every few seconds, when the app is paused and when it closes) and that the game
## resumes from at startup. The player's save slots are only written by saving into them on
## purpose, so autosave never overwrites one.

const SAVE_PATH := "user://save.json"
const AUTOSAVE_INTERVAL_S := 30.0
const SLOT_COUNT := 3

## Changed by use_sandbox() so tests and tools never touch the player's save. This is the file
## of slot 1 (so saves from before there were slots stay in slot 1); the autosave and the other
## slots sit next to it.
var save_path := SAVE_PATH

var _autosave_timer: Timer


func _ready() -> void:
	# Lets us save before quitting on desktop; we quit ourselves in _notification.
	get_tree().set_auto_accept_quit(false)
	load_game()

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL_S
	_autosave_timer.timeout.connect(save_game)
	add_child(_autosave_timer)
	_autosave_timer.start()


## Redirects all saving to `path` and stops autosaving, then starts a fresh game in English.
## Used by the test runner and developer tools.
func use_sandbox(path: String) -> void:
	save_path = path
	if _autosave_timer != null:
		_autosave_timer.stop()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	Settings.use_sandbox(path.get_base_dir().path_join("settings.cfg"))
	# The real save was already loaded at startup; forget what happened offline there.
	GameState.last_offline_earned = 0.0
	GameState.last_offline_stored = 0
	GameState.replace_state(PlayerState.new_game())


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			save_game()
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()
			get_tree().quit()


## The hidden autosave file.
func autosave_path() -> String:
	return save_path.get_base_dir().path_join("autosave." + save_path.get_extension())


## The file of save slot `number` (1..SLOT_COUNT).
func slot_path(number: int) -> String:
	if number == 1:
		return save_path
	return "%s_%d.%s" % [save_path.get_basename(), number, save_path.get_extension()]


## Autosaves the running game. Never touches a save slot.
func save_game() -> void:
	_write(autosave_path())


## Saves the running game into slot `number`, replacing what it held. This is the only way a
## slot is ever written.
func save_to_slot(number: int) -> void:
	_write(slot_path(clampi(number, 1, SLOT_COUNT)))


func has_save(number: int) -> bool:
	return _exists(slot_path(number))


## What slot `number` holds, for showing it: `saved_at_unix` and `money`. Empty for an empty or
## unreadable slot.
func slot_info(number: int) -> Dictionary:
	var payload := SaveFile.load_with_fallback(slot_path(number))
	if payload.is_empty():
		return {}
	var state: Dictionary = payload.get("state", {})
	return {
		"saved_at_unix": int(payload.get("saved_at_unix", 0)),
		"money": float(state.get("money", 0.0)),
	}


## Resumes the game from the autosave, or from slot 1 if there is no autosave yet (saves from
## before autosaving had its own file). The time since saving counts as offline progress.
func load_game() -> void:
	for path: String in [autosave_path(), slot_path(1)]:
		var payload := SaveFile.load_with_fallback(path)
		if not payload.is_empty():
			_apply(payload)
			TimeService.report_offline_since(int(payload["saved_at_unix"]))
			return
		if FileAccess.file_exists(path):
			_quarantine_unreadable_save(path)
	GameState.replace_state(PlayerState.new_game())


## Goes back to the save in slot `number`; the slot itself stays as it is. Returns false if the
## slot holds nothing readable. The catch in the backpack is not saved and gets lost.
func load_slot(number: int) -> bool:
	var payload := SaveFile.load_with_fallback(slot_path(number))
	if payload.is_empty():
		return false
	_apply(payload)
	save_game()
	return true


## Throws the current game away and starts over (the settings and the save slots stay).
func new_game() -> void:
	GameState.last_offline_earned = 0.0
	GameState.last_offline_stored = 0
	GameState.replace_state(PlayerState.new_game())
	save_game()


func _apply(payload: Dictionary) -> void:
	GameState.replace_state(PlayerState.from_dict(payload["state"]))


func _write(path: String) -> void:
	var payload := {
		"version": SaveFile.VERSION,
		"saved_at_unix": TimeService.now_unix(),
		"state": GameState.state.to_dict(),
	}
	var err := SaveFile.write_atomic(path, payload)
	if err != OK:
		push_error("Saving failed: %s" % error_string(err))


func _exists(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


## Keeps a save we could not read (corrupt, or from a newer app version) instead of
## overwriting it with a fresh game.
func _quarantine_unreadable_save(path: String) -> void:
	var target := "%s.unreadable-%d" % [path, TimeService.now_unix()]
	DirAccess.rename_absolute(path, target)
	push_warning("Save file could not be loaded, moved to %s" % target)
