extends Node
## Owns the save file: loads it at startup, autosaves, and saves when the app is
## paused or closed.

const SAVE_PATH := "user://save.json"
const AUTOSAVE_INTERVAL_S := 30.0

## Overridden by tests so they never touch the real save.
var save_path := SAVE_PATH


func _ready() -> void:
	# Lets us save before quitting on desktop; we quit ourselves in _notification.
	get_tree().set_auto_accept_quit(false)
	load_game()

	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_INTERVAL_S
	timer.timeout.connect(save_game)
	add_child(timer)
	timer.start()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			save_game()
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()
			get_tree().quit()


func save_game() -> void:
	var payload := {
		"version": SaveFile.VERSION,
		"saved_at_unix": TimeService.now_unix(),
		"state": GameState.state.to_dict(),
	}
	var err := SaveFile.write_atomic(save_path, payload)
	if err != OK:
		push_error("Saving failed: %s" % error_string(err))


func load_game() -> void:
	var payload := SaveFile.load_with_fallback(save_path)
	if payload.is_empty():
		if FileAccess.file_exists(save_path):
			_quarantine_unreadable_save()
		GameState.replace_state(PlayerState.new())
		return
	GameState.replace_state(PlayerState.from_dict(payload["state"]))
	TimeService.report_offline_since(int(payload["saved_at_unix"]))


## Keeps a save we could not read (corrupt, or from a newer app version) instead of
## overwriting it with a fresh game.
func _quarantine_unreadable_save() -> void:
	var target := "%s.unreadable-%d" % [save_path, TimeService.now_unix()]
	DirAccess.rename_absolute(save_path, target)
	push_warning("Save file could not be loaded, moved to %s" % target)
