class_name SwimmingFish
extends Node2D
## A fish in the fishing scene. Steers itself (wander, schooling, fleeing the net) and draws
## placeholder art in code: an undulating top-down body, tail, fins and eyes. Sprites come in M6.

enum State { SWIMMING, CAUGHT }

const OUTLINE_COLOR := Color(0.07, 0.09, 0.15)
const OUTLINE_WIDTH := 4.0
const SHADOW_COLOR := Color(0.0, 0.06, 0.14, 0.22)
## Shadow offset in screen space; light comes from the top left.
const SHADOW_OFFSET := Vector2(10.0, 18.0)
const SPARKLE_COLOR := Color(1.0, 0.95, 0.55, 0.9)
const SPINE_SEGMENTS := 10
## Share of the total length taken by the body; the rest is tail fin.
const BODY_SHARE := 0.8

const TURN_RATE := 2.5
const WANDER_JITTER := 3.0
const WANDER_ANGLE := 0.6
const EDGE_MARGIN := 140.0
const SCHOOL_RADIUS := 260.0
const FLEE_SECONDS := 0.6
const FLEE_SPEED_MULT := 1.9
## A fish in the net is tangled: it wriggles hard but moves slowly, so holding on is doable.
const HELD_SPEED_MULT := 0.5
const HELD_WIGGLE_MULT := 3.0

var species: SpeciesDef
var state := State.SWIMMING
var velocity := Vector2.ZERO
## Seconds the net has been on this fish; it is caught at CatchRules.struggle_seconds().
var hold_time := 0.0
var length_px := 0.0
var width_px := 0.0

var _cruise_speed := 0.0
var _wander := 0.0
var _swim_phase := 0.0
var _flee_timer := 0.0
var _flee_direction := Vector2.ZERO
var _age := 0.0


func setup(def: SpeciesDef, start: Vector2, heading: float) -> void:
	species = def
	position = start
	rotation = heading
	length_px = CatchRules.body_length_px(def)
	width_px = length_px * def.body_aspect
	_cruise_speed = CatchRules.cruise_speed(def)
	velocity = Vector2.from_angle(heading) * _cruise_speed
	_swim_phase = randf() * TAU
	_wander = randf_range(-1.0, 1.0)


func is_held() -> bool:
	return hold_time > 0.0


## Moves the fish one step. `threat_radius` is 0 while the net is not in the water.
## `school` holds all swimming fish; only nearby fish of the same species matter.
func simulate(delta: float, bounds: Rect2, net_position: Vector2, threat_radius: float, school: Array[SwimmingFish]) -> void:
	_age += delta
	_wander = clampf(_wander + randf_range(-1.0, 1.0) * WANDER_JITTER * delta, -1.0, 1.0)
	var steer := Vector2.from_angle(rotation).rotated(_wander * WANDER_ANGLE)
	if not bounds.grow(-EDGE_MARGIN).has_point(position):
		steer += position.direction_to(bounds.get_center()) * 2.0
	if species.length_cm < CatchRules.SCHOOLING_BELOW_CM:
		steer += _schooling(school)

	var speed := _cruise_speed
	var away_from_net := net_position.direction_to(position)
	if is_held():
		steer += away_from_net * 3.0
		speed *= HELD_SPEED_MULT
	else:
		if threat_radius > 0.0 and position.distance_to(net_position) < threat_radius:
			_flee_timer = FLEE_SECONDS
			_flee_direction = away_from_net
		if _flee_timer > 0.0:
			_flee_timer -= delta
			steer += _flee_direction * 2.5
			speed *= FLEE_SPEED_MULT

	velocity = velocity.lerp(steer.normalized() * speed, clampf(TURN_RATE * delta, 0.0, 1.0))
	position += velocity * delta
	if velocity.length_squared() > 1.0:
		rotation = velocity.angle()
	var wiggle := HELD_WIGGLE_MULT if is_held() else 1.0
	_swim_phase += delta * (5.0 + velocity.length() / 35.0) * wiggle
	queue_redraw()


## Shrinks the fish into the net, then frees it.
func play_caught(target: Vector2) -> void:
	state = State.CAUGHT
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", target, 0.18).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ONE * 0.35, 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18).set_delay(0.08)
	tween.chain().tween_callback(queue_free)


func _schooling(school: Array[SwimmingFish]) -> Vector2:
	var center := Vector2.ZERO
	var heading := Vector2.ZERO
	var separation := Vector2.ZERO
	var count := 0
	var personal_space := length_px * 1.2
	for other in school:
		if other == self or other.species != species:
			continue
		var offset := other.position - position
		var distance := offset.length()
		if distance > SCHOOL_RADIUS or distance < 0.001:
			continue
		count += 1
		center += other.position
		heading += other.velocity
		if distance < personal_space:
			separation -= offset / distance * (1.0 - distance / personal_space)
	if count == 0:
		return Vector2.ZERO
	center /= count
	return position.direction_to(center) * 0.4 + heading.normalized() * 0.6 + separation * 1.5


#region Drawing

func _draw() -> void:
	var spine := _spine()
	var body := _body_polygon(spine)
	var tail := _tail_polygon(spine)
	var color := species.placeholder_color

	draw_set_transform(SHADOW_OFFSET.rotated(-rotation))
	draw_colored_polygon(tail, SHADOW_COLOR)
	draw_colored_polygon(body, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO)

	for fin in _fin_polygons(spine):
		_fill_outlined(fin, color.darkened(0.15))
	_fill_outlined(tail, color.darkened(0.1))
	_fill_outlined(body, color)
	# Darker stripe along the back, as seen from above.
	draw_polyline(spine.slice(1, SPINE_SEGMENTS - 1), color.darkened(0.3), maxf(width_px * 0.22, 3.0), true)
	_draw_eyes(spine)
	if species.rarity >= SpeciesDef.Rarity.UNCOMMON:
		_draw_sparkles()


func _fill_outlined(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE_COLOR, OUTLINE_WIDTH, true)


## Points along the body axis from snout (index 0) to tail root, with a travelling sine wave
## that grows towards the tail.
func _spine() -> PackedVector2Array:
	var points := PackedVector2Array()
	var amplitude := length_px * 0.07
	for i in SPINE_SEGMENTS + 1:
		var t := float(i) / SPINE_SEGMENTS
		var x := length_px * 0.5 - t * length_px * BODY_SHARE
		points.append(Vector2(x, sin(_swim_phase - t * 3.0) * amplitude * t * t))
	return points


## Unit vector pointing towards the head at spine point i.
func _spine_direction(spine: PackedVector2Array, i: int) -> Vector2:
	if i == 0:
		return spine[1].direction_to(spine[0])
	return spine[i].direction_to(spine[i - 1])


## Body half-width at t (0 = snout, 1 = tail root): rounded head, widest at about a third.
func _half_width(t: float) -> float:
	var profile := pow(maxf(sin(PI * (0.08 + 0.92 * pow(t, 0.7))), 0.0), 0.8)
	return maxf(width_px * 0.5 * profile, width_px * 0.06)


func _body_polygon(spine: PackedVector2Array) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in spine.size():
		var normal := _spine_direction(spine, i).orthogonal()
		var half_width := _half_width(float(i) / SPINE_SEGMENTS)
		left.append(spine[i] + normal * half_width)
		right.append(spine[i] - normal * half_width)
	right.reverse()
	var polygon := left
	polygon.append_array(right)
	# Rounded snout: arc from the right side of the head, around the front, to the left side.
	var forward := _spine_direction(spine, 0)
	var normal0 := forward.orthogonal()
	var head_half_width := _half_width(0.0)
	var snout := maxf(head_half_width * 0.9, length_px * 0.05)
	for k in range(1, 6):
		var angle := -PI * 0.5 + PI * k / 6.0
		polygon.append(spine[0] + forward * cos(angle) * snout + normal0 * sin(angle) * head_half_width)
	return polygon


func _tail_polygon(spine: PackedVector2Array) -> PackedVector2Array:
	var root := spine[SPINE_SEGMENTS]
	# The tail lags slightly behind the body wave.
	var back := -_spine_direction(spine, SPINE_SEGMENTS).rotated(sin(_swim_phase - 3.6) * 0.35)
	var side := back.orthogonal()
	var tail_length := length_px * (1.0 - BODY_SHARE)
	var spread := maxf(width_px * 0.5, length_px * 0.09)
	return PackedVector2Array([
		root + side * width_px * 0.08,
		root + back * tail_length + side * spread,
		root + back * tail_length * 0.6,
		root + back * tail_length - side * spread,
		root - side * width_px * 0.08,
	])


func _fin_polygons(spine: PackedVector2Array) -> Array[PackedVector2Array]:
	var i := 2
	var forward := _spine_direction(spine, i)
	var normal := forward.orthogonal()
	var half_width := _half_width(float(i) / SPINE_SEGMENTS)
	var fin_length := maxf(width_px * 0.55, length_px * 0.08)
	var flap := sin(_swim_phase * 1.3) * 0.35
	var fins: Array[PackedVector2Array] = []
	for side: float in [1.0, -1.0]:
		var root := spine[i] + normal * half_width * side * 0.9
		var out := (normal * side * 0.6 - forward * 0.8).normalized().rotated(flap * side)
		fins.append(PackedVector2Array([
			root + forward * fin_length * 0.25,
			root + out * fin_length,
			root - forward * fin_length * 0.35,
		]))
	return fins


func _draw_eyes(spine: PackedVector2Array) -> void:
	var forward := _spine_direction(spine, 0)
	var normal := forward.orthogonal()
	var center := spine[0].lerp(spine[1], 0.5)
	var half_width := _half_width(0.05)
	var radius := clampf(width_px * 0.11, 4.0, 14.0)
	for side: float in [1.0, -1.0]:
		var eye := center + normal * half_width * 0.62 * side + forward * radius * 0.3
		draw_circle(eye, radius + 2.0, OUTLINE_COLOR)
		draw_circle(eye, radius, Color.WHITE)
		draw_circle(eye + forward * radius * 0.35, radius * 0.5, OUTLINE_COLOR)


## Twinkling stars orbiting fish that are not common.
func _draw_sparkles() -> void:
	for k in 3:
		var angle := _age * 1.7 + k * TAU / 3.0
		var at := Vector2(cos(angle) * length_px * 0.55, sin(angle) * (width_px * 0.5 + 22.0))
		var size := 9.0 + 5.0 * sin(_age * 6.0 + k * 2.0)
		var star := PackedVector2Array()
		for j in 8:
			star.append(at + Vector2.from_angle(j * PI / 4.0) * (size if j % 2 == 0 else size * 0.35))
		draw_colored_polygon(star, SPARKLE_COLOR)

#endregion
