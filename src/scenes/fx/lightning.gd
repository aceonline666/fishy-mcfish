class_name Lightning
extends Node2D
## A stroke of lightning in a storm (WeatherCycle.lightning): the whole screen flashes white a few
## times and, if it strikes the sea in view, a jagged bolt with a branch or two comes down from
## the top of the screen to it, with a soft glow along it. Drawn additively over everything but
## the HUD, so it lights up the night too. In screen coordinates. Frees itself when done.

## Seconds a stroke lasts, and the flickers within it: [start, end, brightness].
const DURATION := 0.55
const FLICKERS: Array[Vector3] = [Vector3(0.0, 0.09, 1.0), Vector3(0.14, 0.22, 0.6), Vector3(0.28, 0.55, 0.85)]
## How bright the screen flashes at most, by day and at night.
const FLASH_DAY := 0.35
const FLASH_NIGHT := 0.6
## The bolt: how many segments, how far a segment turns aside (share of its length), its glow.
const SEGMENTS := 14
const JAG := 0.55
const CORE_COLOR := Color(1.0, 1.0, 1.0)
const GLOW_COLOR := Color(0.62, 0.7, 1.0, 0.45)

var _view := Vector2.ZERO
var _strength := 1.0
var _flash := FLASH_DAY
var _bolts: Array[PackedVector2Array] = []
var _elapsed := 0.0


## A stroke of `strength` (0 to 1) over a view of `view_size`, `darkness` 0 by day to 1 at
## night. It strikes at `target` (screen); none if `target` is INF (only the flash).
func _init(view_size: Vector2, target: Vector2, strength: float, darkness: float, rng: RandomNumberGenerator) -> void:
	_view = view_size
	_strength = strength
	_flash = lerpf(FLASH_DAY, FLASH_NIGHT, darkness)
	material = Glow.material()
	Layers.put(self, Layers.NIGHT_LIGHTS)
	if target != Vector2.INF:
		var top := Vector2(target.x + rng.randf_range(-0.25, 0.25) * view_size.x, -40.0)
		var main := bolt(top, target, SEGMENTS, rng)
		_bolts.append(main)
		for branch in rng.randi_range(1, 2):
			var from := main[rng.randi_range(3, SEGMENTS - 5)]
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var to := from + Vector2(side * rng.randf_range(80.0, 200.0), rng.randf_range(120.0, 260.0))
			_bolts.append(bolt(from, to, 6, rng))


## A jagged line from `from` to `to` in `segments`, each turned aside at random.
static func bolt(from: Vector2, to: Vector2, segments: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	var step := (to - from) / segments
	var across := Vector2(-step.y, step.x).normalized() * step.length() * JAG
	for i in range(1, segments):
		points.append(from + step * i + across * rng.randf_range(-1.0, 1.0))
	points.append(to)
	return points


## How bright the stroke is `elapsed` seconds in, 0 to 1.
static func brightness(elapsed: float) -> float:
	for flicker in FLICKERS:
		if elapsed >= flicker.x and elapsed < flicker.y:
			return flicker.z * (1.0 - inverse_lerp(flicker.x, flicker.y, elapsed) * 0.6)
	return 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var light := brightness(_elapsed) * _strength
	if light <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, _view), Color(0.85, 0.88, 1.0, _flash * light))
	for points in _bolts:
		var main := points.size() > 7
		draw_polyline(points, Color(GLOW_COLOR, GLOW_COLOR.a * light), 18.0 if main else 10.0, true)
		draw_polyline(points, Color(CORE_COLOR, light), 4.0 if main else 2.5, true)
