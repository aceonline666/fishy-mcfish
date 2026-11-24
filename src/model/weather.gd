class_name Weather
extends RefCounted
## The weather and how the world looks in it: sunny, rain or a storm (snow and a blizzard where
## the water is polar). The look is a State of a few shares (0 to 1) that ease towards the
## weather's look (target), so a change of weather never pops. Spells of weather follow each
## other at random (next): mostly sunny, now and then rain, and a storm only out of rain.

enum Kind { SUNNY, RAIN, STORM }

## Seconds a share takes to ease all the way (0 to 1).
const BLEND_S := 20.0
## How long a spell of each kind lasts (seconds, shortest and longest).
const SPELLS: Dictionary[Kind, Vector2] = {
	# About 35 minutes of sun, so rain comes about every second (20-minute) day.
	Kind.SUNNY: Vector2(1500.0, 2700.0),
	Kind.RAIN: Vector2(120.0, 300.0),
	Kind.STORM: Vector2(90.0, 180.0),
}
## The chance that rain turns into a storm (else the sun comes out again).
const STORM_CHANCE := 0.35
## The colour the world is multiplied with under rain clouds and in a storm (with the day's tint).
const RAIN_TINT := Color(0.76, 0.8, 0.86)
const STORM_TINT := Color(0.54, 0.58, 0.66)
## A storm's lightning: seconds between two strokes, shortest and longest.
const LIGHTNING_GAP := Vector2(4.0, 12.0)


## How the weather looks now, each share 0 to 1.
class State:
	## Clouds: the sun and the moon hide, the world turns grey.
	var overcast := 0.0
	## How hard it rains (or snows).
	var rain := 0.0
	## How hard the wind blows: the rain slants, the waves grow.
	var wind := 0.0
	## How stormy: lightning, the open sea's swell rolls in towards the shore.
	var storm := 0.0
	## 1 where it snows instead of raining (no rings on the water).
	var snow := 0.0

	func _init(cloud: float = 0.0, rain_share: float = 0.0, wind_share: float = 0.0, storm_share: float = 0.0, snow_share: float = 0.0) -> void:
		overcast = cloud
		rain = rain_share
		wind = wind_share
		storm = storm_share
		snow = snow_share


## The look of `kind`; snow instead of rain if `polar`.
static func target(kind: Kind, polar: bool) -> State:
	var snow := 1.0 if polar else 0.0
	match kind:
		Kind.RAIN:
			return State.new(0.6, 0.5, 0.25, 0.0, snow)
		Kind.STORM:
			return State.new(1.0, 1.0, 1.0, 1.0, snow)
	return State.new(0.0, 0.0, 0.0, 0.0, snow)


## `current` eased `delta` seconds towards `goal`. Snow or rain switches at once (it changes only
## with the location).
static func approach(current: State, goal: State, delta: float) -> State:
	var step := delta / BLEND_S
	return State.new(
		move_toward(current.overcast, goal.overcast, step),
		move_toward(current.rain, goal.rain, step),
		move_toward(current.wind, goal.wind, step),
		move_toward(current.storm, goal.storm, step),
		goal.snow,
	)


## The colour the world is multiplied with in `state`: white in the sun, grey under rain clouds,
## dark blue-grey in a storm.
static func tint(state: State) -> Color:
	var cloudy := clampf(state.overcast / target(Kind.RAIN, false).overcast, 0.0, 1.0)
	return Color.WHITE.lerp(RAIN_TINT, cloudy).lerp(STORM_TINT, state.storm)


## True when lightning can strike in `state`: in a storm, and in a blizzard too (thundersnow).
static func lightning(state: State) -> bool:
	return state.storm > 0.5


## The spell after one of `kind`: [its kind, its length in seconds]. Sun is followed by rain,
## rain by a storm (STORM_CHANCE) or the sun, a storm by rain.
static func next(rng: RandomNumberGenerator, kind: Kind) -> Array:
	var following := Kind.RAIN
	if kind == Kind.RAIN:
		following = Kind.STORM if rng.randf() < STORM_CHANCE else Kind.SUNNY
	return [following, spell(rng, following)]


## A random length for a spell of `kind` (seconds).
static func spell(rng: RandomNumberGenerator, kind: Kind) -> float:
	return rng.randf_range(SPELLS[kind].x, SPELLS[kind].y)
