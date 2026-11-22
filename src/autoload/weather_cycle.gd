extends Node
## The weather now (Weather): spells of sun, rain and storm rolled at random while the game runs,
## or always one of them, as chosen in the settings. `state` is how it looks, eased towards the
## weather's look. In a storm it sends `lightning` now and then. In debug builds W holds the next
## kind of weather (sunny, rain, storm), Shift+W lets it change by itself again.

## Lightning strikes, `strength` 0 to 1.
signal lightning(strength: float)

## A fixed kind (Weather.Kind) for testing and screenshots; below 0 the weather follows the
## settings.
var override_kind := -1
## Set by the fishing spot: snow instead of rain.
var polar := false
## How the weather looks now.
var state := Weather.State.new()

var _rng := RandomNumberGenerator.new()
## The current spell of random weather and the seconds it has left.
var _kind := Weather.Kind.SUNNY
var _left := 0.0
var _lightning_in := 0.0


func _ready() -> void:
	_rng.randomize()
	# The first spell of sun is a short one, so a session does not always start sunny for long.
	_left = _rng.randf_range(60.0, Weather.SPELLS[Weather.Kind.SUNNY].y * 0.6)
	_lightning_in = _rng.randf_range(Weather.LIGHTNING_GAP.x, Weather.LIGHTNING_GAP.y)
	snap()


## The weather now.
func kind() -> Weather.Kind:
	if override_kind >= 0:
		return override_kind as Weather.Kind
	match Settings.weather:
		Settings.WEATHER_SUNNY:
			return Weather.Kind.SUNNY
		Settings.WEATHER_RAIN:
			return Weather.Kind.RAIN
		Settings.WEATHER_STORM:
			return Weather.Kind.STORM
	return _kind


## Shows the weather's look at once, without easing into it.
func snap() -> void:
	state = Weather.target(kind(), polar)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		var following := Weather.next(_rng, _kind)
		_kind = following[0]
		_left = following[1]
	state = Weather.approach(state, Weather.target(kind(), polar), delta)
	if not Weather.lightning(state):
		return
	_lightning_in -= delta
	if _lightning_in <= 0.0:
		_lightning_in = _rng.randf_range(Weather.LIGHTNING_GAP.x, Weather.LIGHTNING_GAP.y)
		lightning.emit(_rng.randf_range(0.6, 1.0) * state.storm)


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event.is_pressed() or event.is_echo():
		return
	var key := event as InputEventKey
	if key.keycode != KEY_W:
		return
	override_kind = -1 if key.shift_pressed else (kind() + 1) % Weather.Kind.size()
	print("Weather: ", "random" if override_kind < 0 else Weather.Kind.keys()[override_kind])
