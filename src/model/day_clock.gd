class_name DayClock
extends RefCounted
## The time of day and how the world looks at it. An hour is 0 to 24 (local clock time). Dusk and
## dawn take two hours each; between them it is night. The fast cycle (the default) runs a whole
## day in FAST_CYCLE_S, the night shorter than the day; the real cycle follows the device clock.

## Dawn and dusk, from their first hour to their last.
const DAWN := Vector2(5.0, 7.0)
const DUSK := Vector2(19.0, 21.0)
## The fast cycle: its length in seconds and the seconds it spends in day, dusk, night and dawn
## (in that order, from DAWN.y on).
const FAST_CYCLE_S := 1200.0
const FAST_PARTS: Array[float] = [780.0, 90.0, 240.0, 90.0]
## The tint of the world at night (multiplied in): a cool moonlit blue at about a third of the
## day's brightness.
const NIGHT_TINT := Color(0.28, 0.34, 0.58)
## The middle of dusk (a warm sunset gold) and of dawn (a pale pink).
const DUSK_TINT := Color(1.0, 0.76, 0.6)
const DAWN_TINT := Color(0.96, 0.8, 0.8)


## The clock hour of the fast cycle at `unix_seconds`. Every device shows the same time of day at
## the same moment, and the cycle runs on while the game is closed.
static func fast_hour(unix_seconds: float) -> float:
	var t := fposmod(unix_seconds, FAST_CYCLE_S)
	# Day, dusk, night and dawn, each from its first hour to its last.
	var spans: Array[Vector2] = [Vector2(DAWN.y, DUSK.x), DUSK, Vector2(DUSK.y, DAWN.x + 24.0), DAWN]
	for i in FAST_PARTS.size():
		if t < FAST_PARTS[i] or i == FAST_PARTS.size() - 1:
			var share := clampf(t / FAST_PARTS[i], 0.0, 1.0)
			return fposmod(lerpf(spans[i].x, spans[i].y, share), 24.0)
		t -= FAST_PARTS[i]
	return DAWN.y


## The clock hour of a time dictionary (Time.get_time_dict_from_system()).
static func clock_hour(time: Dictionary) -> float:
	return float(time.get("hour", 12)) + float(time.get("minute", 0)) / 60.0 + float(time.get("second", 0)) / 3600.0


## 0 in daylight to 1 at night: the lamps' strength. Lamps come on in the second half of dusk and
## go out in the first half of dawn.
static func darkness(hour: float) -> float:
	var h := fposmod(hour, 24.0)
	return maxf(1.0 - smoothstep(DAWN.x, lerpf(DAWN.x, DAWN.y, 0.6), h), smoothstep(lerpf(DUSK.x, DUSK.y, 0.4), DUSK.y, h))


## The colour the world is multiplied with: white by day, gold through dusk, moonlit blue at night
## and pink through dawn.
static func tint(hour: float) -> Color:
	var h := fposmod(hour, 24.0)
	if h >= DUSK.x and h < DUSK.y:
		return _through(Color.WHITE, DUSK_TINT, NIGHT_TINT, inverse_lerp(DUSK.x, DUSK.y, h))
	if h >= DAWN.x and h < DAWN.y:
		return _through(NIGHT_TINT, DAWN_TINT, Color.WHITE, inverse_lerp(DAWN.x, DAWN.y, h))
	return Color.WHITE if h >= DAWN.y and h < DUSK.x else NIGHT_TINT


## From `from` over `middle` to `to` as `t` runs from 0 to 1.
static func _through(from: Color, middle: Color, to: Color, t: float) -> Color:
	var s := smoothstep(0.0, 1.0, t)
	return from.lerp(middle, s * 2.0) if s < 0.5 else middle.lerp(to, s * 2.0 - 1.0)


## The sun or the moon mirrored on the water (reflection.gdshaderinc): a disc out on the sea towards
## the light, rippled by the waves, with glints flashing around it. Far out and drawn long with
## the light low, close and round with it high.
class Glint:
	## The glints' colour; its alpha is how strongly they show (0: none).
	var color: Color
	## Towards the light along the ground (a unit vector).
	var direction: Vector2
	## How high the light stands, 0 on the horizon to 1 overhead.
	var height: float

	func _init(glint_color: Color, glint_direction: Vector2, glint_height: float) -> void:
		color = glint_color
		direction = glint_direction
		height = glint_height


## The sun is up from half an hour into dawn to half an hour before the end of dusk; the moon from
## the second hour of dusk to the end of the first hour of dawn.
const SUN_UP := Vector2(5.5, 20.5)
const MOON_UP := Vector2(20.0, 30.0)
## The mirrored sun high in the sky, low in the morning and low in the evening, and the moon.
const SUN_GLINT := Color(1.0, 0.97, 0.86)
const MORNING_GLINT := Color(1.0, 0.82, 0.74)
const EVENING_GLINT := Color(1.0, 0.7, 0.36)
const MOON_GLINT := Color(0.9, 0.95, 1.0)
## How far from straight out to sea the light rises and sets (radians).
const LIGHT_SWING := PI * 0.3


## The glints on the water at `hour`: the sun's by day, the moon's at night.
static func glint(hour: float) -> Glint:
	var h := fposmod(hour, 24.0)
	var sun := _arc(h, SUN_UP)
	var moon := _arc(h if h >= MOON_UP.x else h + 24.0, MOON_UP)
	# The low sun is mirrored the most brightly; the moon is pale, but bright against the night.
	var sun_strength := smoothstep(0.0, 0.12, sun.y) * lerpf(1.0, 0.85, sun.y)
	var moon_strength := smoothstep(0.0, 0.12, moon.y) * darkness(h)
	if moon_strength > sun_strength:
		var moon_color := MOON_GLINT
		moon_color.a = moon_strength
		return Glint.new(moon_color, _towards(moon.x), moon.y)
	var low := MORNING_GLINT if sun.x < 0.5 else EVENING_GLINT
	var color := low.lerp(SUN_GLINT, smoothstep(0.1, 0.5, sun.y))
	color.a = sun_strength
	return Glint.new(color, _towards(sun.x), sun.y)


## How far a light up during `up` (first hour, last hour) has come at `hour`, 0 to 1 (x), and how
## high it stands (y, 0 on the horizon or below it).
static func _arc(hour: float, up: Vector2) -> Vector2:
	var along := inverse_lerp(up.x, up.y, hour)
	if along <= 0.0 or along >= 1.0:
		return Vector2(clampf(along, 0.0, 1.0), 0.0)
	return Vector2(along, sin(along * PI))


## Towards a light `along` its way across the sky: it rises out over the sea on one side (towards
## ground +x), stands straight out over the sea (+y) at its highest and sets on the other side.
## Always over the sea, so that it is mirrored on the water and not up the beach.
static func _towards(along: float) -> Vector2:
	var angle := lerpf(-LIGHT_SWING, LIGHT_SWING, along)
	return Vector2(-sin(angle), cos(angle))
