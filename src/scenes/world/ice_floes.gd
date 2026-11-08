class_name IceFloes
extends Node2D
## Ice floes drifting on the surface of a zone (the Antarctic pack ice), drawn in code in the
## comic look of the painted sprites: a dark outline, a white top with a snowy highlight, a
## blue-white edge showing their thickness, the paler ice under the water around them and a ring
## of foam at the waterline. They lie on the surface layer (Layers.SURFACE), above the fish and
## the swimming wader; the wader shows through them see-through (Wader.surface_hides()). They bob,
## drift a little around their place and turn slowly, but stay where they are.

const OUTLINE := Color(0.07, 0.09, 0.15)
const TOP := Color(0.8, 0.91, 0.98)
const SNOW := Color(1.0, 1.0, 1.0)
const EDGE := Color(0.62, 0.8, 0.92)
const SUBMERGED := Color(0.75, 0.93, 1.0, 0.3)
const FOAM := Color(1.0, 1.0, 1.0, 0.6)
## Ground radius of a floe, smallest and largest.
const RADIUS := Vector2(70.0, 150.0)
## Floes keep this far apart (share of their radii) and this far inside the area's edges.
const SPACING := 1.25
const MARGIN := 60.0
## Screen height of the edge above the water.
const THICKNESS := 12.0
## How far a floe drifts around its place (ground units) and how far it turns (radians).
const DRIFT := Vector2(35.0, 18.0)
const TURN := 0.1
const CORNERS := 11

var _floes: Array[Floe] = []
var _time := 0.0


## Scatters `count` floes over the ground rectangle `area`.
func setup(area: Rect2, count: int, seed_value: int = 5) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_floes.clear()
	for i in count:
		var floe := Floe.new()
		floe.radius = rng.randf_range(RADIUS.x, RADIUS.y)
		for attempt in 30:
			var inner := area.grow(-MARGIN - floe.radius)
			floe.center = inner.position + Vector2(rng.randf(), rng.randf()) * inner.size
			if not _crowded(floe):
				break
		floe.phase = rng.randf() * TAU
		for corner in CORNERS:
			var angle := TAU * (corner + rng.randf_range(-0.3, 0.3)) / CORNERS
			floe.outline.append(Vector2.from_angle(angle) * floe.radius * rng.randf_range(0.72, 1.0))
		_floes.append(floe)
	_place()


## True when the screen rectangle `rect` (in this node's parent's coordinates) overlaps a floe.
func hides(rect: Rect2) -> bool:
	var box := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	for floe in _floes:
		if floe.bounds.intersects(rect) and not Geometry2D.intersect_polygons(box, floe.top).is_empty():
			return true
	return false


func _crowded(floe: Floe) -> bool:
	for other in _floes:
		if floe.center.distance_to(other.center) < (floe.radius + other.radius) * SPACING:
			return true
	return false


func _process(delta: float) -> void:
	if _floes.is_empty():
		return
	_time += delta
	_place()
	queue_redraw()


## Moves the floes to where they have drifted at this time: their top outline on screen.
func _place() -> void:
	for floe in _floes:
		var drift := Vector2(sin(_time * 0.07 + floe.phase) * DRIFT.x, cos(_time * 0.05 + floe.phase * 1.3) * DRIFT.y)
		var turn := sin(_time * 0.04 + floe.phase) * TURN
		var bob := sin(_time * 0.9 + floe.phase) * 1.5
		floe.top = PackedVector2Array()
		for point in floe.outline:
			floe.top.append(Iso.to_screen(floe.center + drift + point.rotated(turn)) + Vector2(0.0, bob - THICKNESS))
		floe.bounds = Rect2(floe.top[0], Vector2.ZERO)
		for point in floe.top:
			floe.bounds = floe.bounds.expand(point)
		floe.bounds = floe.bounds.grow_individual(0.0, 0.0, 0.0, THICKNESS)
	_floes.sort_custom(func(a: Floe, b: Floe) -> bool: return a.bounds.end.y < b.bounds.end.y)


func _draw() -> void:
	var view := get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	for floe in _floes:
		if not view.grow(40.0).intersects(floe.bounds):
			continue
		var center := Vector2.ZERO
		for point in floe.top:
			center += point
		center /= floe.top.size()
		var waterline := _moved(floe.top, Vector2(0.0, THICKNESS))
		# The ice under the water reaches a little further out, paler.
		draw_colored_polygon(_scaled(waterline, center + Vector2(0.0, THICKNESS), 1.12), SUBMERGED)
		_draw_ring(_scaled(waterline, center + Vector2(0.0, THICKNESS), 1.04), FOAM, 3.0)
		# The edge: the outline at the waterline, joined to the top at its widest points.
		draw_colored_polygon(waterline, EDGE)
		_draw_ring(waterline, OUTLINE, 2.5)
		var left := 0
		var right := 0
		for i in floe.top.size():
			if floe.top[i].x < floe.top[left].x:
				left = i
			if floe.top[i].x > floe.top[right].x:
				right = i
		for i: int in [left, right]:
			draw_line(floe.top[i], waterline[i], OUTLINE, 2.5, true)
		draw_colored_polygon(floe.top, TOP)
		# Snow on the far side of the top, catching the light.
		draw_colored_polygon(_moved(_scaled(floe.top, center, 0.7), Vector2(-4.0, -3.0)), SNOW)
		_draw_ring(floe.top, OUTLINE, 2.5)


func _draw_ring(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


static func _moved(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		out.append(point + by)
	return out


static func _scaled(points: PackedVector2Array, around: Vector2, factor: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		out.append(around + (point - around) * factor)
	return out


class Floe extends RefCounted:
	## Ground position and size, the outline around the centre (ground), the swaying phase.
	var center := Vector2.ZERO
	var radius := 100.0
	var outline := PackedVector2Array()
	var phase := 0.0
	## Where it is now: the top's outline on screen and the screen rectangle it covers.
	var top := PackedVector2Array()
	var bounds := Rect2()
