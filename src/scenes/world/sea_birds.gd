class_name SeaBirds
extends Node2D
## Now and then a seabird, or a few, flies over the screen, high above everything (Layers.FLYING):
## gulls on temperate coasts, terns in the tropics, albatrosses in the Southern Ocean and a
## pterosaur over the Jurassic Sea. Drawn in code, seen from above, in the comic look of the
## painted sprites: a dark outline, flat colours, wings that beat and now and then glide.

const OUTLINE := Color(0.07, 0.09, 0.15)
const OUTLINE_WIDTH := 2.5
## Seconds between two flights, shortest and longest.
const INTERVAL := Vector2(25.0, 60.0)
## The first flight comes sooner.
const FIRST_FLIGHT := Vector2(6.0, 20.0)

## The kinds of bird: body length (screen pixels), wingspan as a share of it, flight speed (screen
## pixels per second), wingbeats per second, share of the time spent gliding, how many fly
## together, and colours. "cap" darkens the head, "membrane" draws bat-like wings with a crest.
const KINDS: Dictionary[String, Dictionary] = {
	"gull": {"length": 56.0, "span": 2.6, "speed": 230.0, "beats": 2.2, "glide": 0.35, "flock": Vector2i(1, 3),
			"body": Color(0.98, 0.98, 0.97), "wing": Color(0.74, 0.78, 0.84), "tip": Color(0.12, 0.13, 0.16),
			"beak": Color(1.0, 0.8, 0.2)},
	"tern": {"length": 46.0, "span": 2.8, "speed": 260.0, "beats": 3.0, "glide": 0.2, "flock": Vector2i(2, 4),
			"body": Color(1.0, 1.0, 1.0), "wing": Color(0.86, 0.89, 0.93), "tip": Color(0.55, 0.58, 0.64),
			"beak": Color(1.0, 0.45, 0.2), "cap": Color(0.1, 0.1, 0.13)},
	"albatross": {"length": 70.0, "span": 3.6, "speed": 210.0, "beats": 1.2, "glide": 0.8, "flock": Vector2i(1, 1),
			"body": Color(0.98, 0.98, 0.96), "wing": Color(0.28, 0.29, 0.33), "tip": Color(0.16, 0.16, 0.19),
			"beak": Color(1.0, 0.85, 0.6)},
	"pterosaur": {"length": 100.0, "span": 3.0, "speed": 170.0, "beats": 0.9, "glide": 0.5, "flock": Vector2i(1, 2),
			"body": Color(0.55, 0.36, 0.26), "wing": Color(0.86, 0.55, 0.38), "tip": Color(0.62, 0.36, 0.26),
			"beak": Color(0.95, 0.85, 0.55), "crest": Color(0.9, 0.3, 0.2), "membrane": true},
}
## The bird of each water, and of locations that differ from their water.
const BY_WATER: Dictionary[String, String] = {"temperate": "gull", "tropical": "tern", "polar": "albatross"}
const BY_LOCATION: Dictionary[String, String] = {"jurassic_sea": "pterosaur"}

var kind := "gull"

var _rng := RandomNumberGenerator.new()
var _wait := 0.0
var _birds: Array[Bird] = []


## Picks the bird of the location.
func setup(location_id: String, water: String) -> void:
	kind = BY_LOCATION.get(location_id, BY_WATER.get(water, "gull"))
	_rng.randomize()
	_wait = _rng.randf_range(FIRST_FLIGHT.x, FIRST_FLIGHT.y)


## Sends a flight over the screen now.
func fly_now() -> void:
	var view := _view()
	if not view.has_area():
		return
	var spec: Dictionary = KINDS[kind]
	var from_left := _rng.randf() < 0.5
	var start := Vector2(view.position.x - 200.0 if from_left else view.end.x + 200.0, view.position.y + view.size.y * _rng.randf_range(0.15, 0.85))
	var end := Vector2(view.end.x + 200.0 if from_left else view.position.x - 200.0, view.position.y + view.size.y * _rng.randf_range(0.1, 0.9))
	var direction := start.direction_to(end)
	var flock: Vector2i = spec.flock
	for i in _rng.randi_range(flock.x, flock.y):
		var bird := Bird.new()
		# The others follow a little behind and to the side.
		var offset := -direction * 70.0 * i + direction.orthogonal() * _rng.randf_range(-60.0, 60.0) * signf(i)
		bird.position = start + offset
		bird.velocity = direction * float(spec.speed) * _rng.randf_range(0.9, 1.1)
		bird.end_distance = start.distance_to(end) + 70.0 * i
		bird.phase = _rng.randf() * TAU
		bird.size = _rng.randf_range(0.9, 1.1)
		_birds.append(bird)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_wait = _rng.randf_range(INTERVAL.x, INTERVAL.y)
		fly_now()
	if _birds.is_empty():
		return
	var spec: Dictionary = KINDS[kind]
	for bird in _birds:
		bird.travelled += bird.velocity.length() * delta
		bird.position += bird.velocity * delta
		bird.time += delta
		bird.phase += delta * float(spec.beats) * TAU * (0.0 if _gliding(bird, spec) else 1.0)
	_birds = _birds.filter(func(bird: Bird) -> bool: return bird.travelled < bird.end_distance)
	queue_redraw()


## The screen in this node's coordinates.
func _view() -> Rect2:
	return get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()


## Birds glide now and then with their wings spread, in stretches of a few seconds.
func _gliding(bird: Bird, spec: Dictionary) -> bool:
	return sin(bird.time * 0.9 + bird.phase * 0.1) * 0.5 + 0.5 < float(spec.glide)


func _draw() -> void:
	var spec: Dictionary = KINDS[kind]
	for bird in _birds:
		# Seen from above, a wing raised or lowered looks shorter.
		var beat := 1.0 if _gliding(bird, spec) else 0.55 + 0.45 * absf(cos(bird.phase))
		draw_set_transform(bird.position, bird.velocity.angle(), Vector2.ONE * bird.size)
		if spec.get("membrane", false):
			_draw_pterosaur(spec, beat)
		else:
			_draw_bird(spec, beat)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## A bird facing +x: wings bent at the wrist, dark tips, fan tail, round head and beak.
func _draw_bird(spec: Dictionary, beat: float) -> void:
	var length: float = spec.length
	var half_span := length * float(spec.span) * 0.5 * beat
	for side: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2(0.12 * length, 0.08 * length * side), Vector2(0.2 * length, half_span * 0.45 * side),
			Vector2(-0.05 * length, half_span * side), Vector2(-0.12 * length, half_span * 0.55 * side),
			Vector2(-0.14 * length, 0.08 * length * side),
		])
		_fill(wing, spec.wing)
		var tip := PackedVector2Array([wing[1].lerp(wing[2], 0.55), wing[2], wing[3].lerp(wing[2], 0.45)])
		_fill(tip, spec.tip)
	var tail := PackedVector2Array([Vector2(-0.3, 0.07) * length, Vector2(-0.55, 0.14) * length,
			Vector2(-0.48, 0.0) * length, Vector2(-0.55, -0.14) * length, Vector2(-0.3, -0.07) * length])
	_fill(tail, spec.body)
	_fill(_oval(Vector2(-0.02 * length, 0.0), Vector2(0.33, 0.12) * length), spec.body)
	var head := Vector2(0.34 * length, 0.0)
	_fill(PackedVector2Array([head + Vector2(0.06, 0.035) * length, head + Vector2(0.2, 0.0) * length,
			head + Vector2(0.06, -0.035) * length]), spec.beak)
	_fill(_oval(head, Vector2(0.09, 0.08) * length), spec.get("cap", spec.body))


## A pterosaur facing +x: long membrane wings reaching back to the legs, a long beak and a crest.
func _draw_pterosaur(spec: Dictionary, beat: float) -> void:
	var length: float = spec.length
	var half_span := length * float(spec.span) * 0.5 * beat
	for side: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2(0.1 * length, 0.07 * length * side), Vector2(0.16 * length, half_span * 0.5 * side),
			Vector2(0.0, half_span * side), Vector2(-0.2 * length, half_span * 0.75 * side),
			Vector2(-0.34 * length, half_span * 0.4 * side), Vector2(-0.3 * length, 0.1 * length * side),
		])
		_fill(wing, spec.wing)
		# The arm along the leading edge, out to the long finger.
		draw_polyline(PackedVector2Array([wing[0], wing[1], wing[2]]), spec.tip, 5.0, true)
	# Legs trailing behind, then the body.
	for side: float in [-1.0, 1.0]:
		draw_line(Vector2(-0.25 * length, 0.05 * length * side), Vector2(-0.42 * length, 0.08 * length * side), OUTLINE, 4.0, true)
	_fill(_oval(Vector2(-0.06 * length, 0.0), Vector2(0.28, 0.1) * length), spec.body)
	var head := Vector2(0.26 * length, 0.0)
	_fill(PackedVector2Array([head + Vector2(0.0, 0.035) * length, head + Vector2(0.38, 0.0) * length,
			head + Vector2(0.0, -0.035) * length]), spec.beak)
	_fill(PackedVector2Array([head + Vector2(0.02, 0.03) * length, head + Vector2(-0.22, 0.0) * length,
			head + Vector2(0.02, -0.03) * length]), spec.crest)
	_fill(_oval(head, Vector2(0.07, 0.055) * length), spec.body)


func _fill(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE, OUTLINE_WIDTH, true)


static func _oval(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 14:
		var angle := TAU * i / 14.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


class Bird extends RefCounted:
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var travelled := 0.0
	var end_distance := 0.0
	var phase := 0.0
	var time := 0.0
	var size := 1.0
