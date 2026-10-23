extends Node
## Drives the simulation: a fixed 1 Hz tick while the app runs, plus offline catch-up
## after the app was in the background.

const TICK_SECONDS := 1.0
const BASE_OFFLINE_CAP_S := 8.0 * 3600.0

var offline_cap_s := BASE_OFFLINE_CAP_S

var _accumulator := 0.0
var _paused_at_unix := 0


func _process(delta: float) -> void:
	_accumulator += delta
	while _accumulator >= TICK_SECONDS:
		_accumulator -= TICK_SECONDS
		EventBus.sim_tick.emit(TICK_SECONDS)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_paused_at_unix = now_unix()
		NOTIFICATION_APPLICATION_RESUMED:
			if _paused_at_unix > 0:
				report_offline_since(_paused_at_unix)
				_paused_at_unix = 0


func now_unix() -> int:
	return int(Time.get_unix_time_from_system())


## Emits offline_progress for the time elapsed since the given timestamp, if any.
func report_offline_since(since_unix: int) -> void:
	var seconds := offline_seconds(now_unix(), since_unix, offline_cap_s)
	if seconds > 0.0:
		EventBus.offline_progress.emit(seconds)


## Seconds the player was away, capped. A clock that moved backwards grants nothing.
static func offline_seconds(now: int, since: int, cap: float) -> float:
	return clampf(float(now - since), 0.0, cap)
