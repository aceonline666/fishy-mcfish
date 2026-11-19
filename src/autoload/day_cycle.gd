extends Node
## The time of day now (DayClock): the fast 20-minute cycle, the device clock, always day
## (DAY_HOUR) or always night (NIGHT_HOUR), as chosen in the settings. In debug builds N moves the
## time on by an hour (and then holds it there, whatever the setting), Shift+N lets it run again.

## The hours held by "Always day" and "Always night": noon and midnight.
const DAY_HOUR := 12.0
const NIGHT_HOUR := 0.0

## A fixed hour (0 to 24) for testing and screenshots; below 0 the clock runs.
var override_hour := -1.0


func hour() -> float:
	if override_hour >= 0.0:
		return override_hour
	match Settings.day_cycle:
		Settings.DAY_CYCLE_DAY:
			return DAY_HOUR
		Settings.DAY_CYCLE_NIGHT:
			return NIGHT_HOUR
		Settings.DAY_CYCLE_REAL:
			return DayClock.clock_hour(Time.get_time_dict_from_system())
	return DayClock.fast_hour(Time.get_unix_time_from_system())


## 0 in daylight to 1 at night.
func darkness() -> float:
	return DayClock.darkness(hour())


func tint() -> Color:
	return DayClock.tint(hour())


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event.is_pressed() or event.is_echo():
		return
	var key := event as InputEventKey
	if key.keycode != KEY_N:
		return
	override_hour = -1.0 if key.shift_pressed else fposmod(floorf(hour()) + 1.0, 24.0)
	print("Time of day: ", "running" if override_hour < 0.0 else "%d:00" % int(override_hour))
