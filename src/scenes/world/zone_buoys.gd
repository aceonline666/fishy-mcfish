class_name ZoneBuoys
extends Node2D
## Lines of floating buoys marking where the deeper zones begin. Drawn in code, in the comic
## look of the painted sprites: dark outline, a shaded crescent, a glossy highlight and a ring
## of foam where the ball meets the water.

const SPACING := 130.0
const RADIUS := 16.0
## How far the rope sags between two buoys.
const SAG := 9.0
const ROPE := Color(0.96, 0.9, 0.72)
const RED := Color(0.93, 0.24, 0.2)
const RED_SHADE := Color(0.62, 0.1, 0.14)
const WHITE := Color(0.99, 0.97, 0.93)
const WHITE_SHADE := Color(0.7, 0.74, 0.82)
const GREEN := Color(0.4, 0.86, 0.42)
const GREEN_SHADE := Color(0.13, 0.53, 0.3)
const FOAM := Color(1.0, 1.0, 1.0, 0.75)
const WATER_SHADOW := Color(0.02, 0.12, 0.2, 0.25)

## Ground y of each buoy line and whether the zone behind it is open.
var _lines: Array[Vector2] = []
var _width := 0.0
var _time := 0.0


## `lines`: x = ground y of the line, y = 1 if the zone beyond is open, else 0.
func setup(lines: Array[Vector2], width: float) -> void:
	_lines = lines
	_width = width
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for line in _lines:
		var open := line.y > 0.5
		var points := PackedVector2Array()
		var x := 0.0
		while x <= _width:
			points.append(Iso.to_screen(Vector2(x, line.x)))
			x += SPACING
		for i in points.size() - 1:
			_draw_rope(points[i] + _bob(i), points[i + 1] + _bob(i + 1))
		for i in points.size():
			var red := i % 2 == 0
			var color := GREEN if open else (RED if red else WHITE)
			var shade := GREEN_SHADE if open else (RED_SHADE if red else WHITE_SHADE)
			_draw_buoy(points[i] + _bob(i), i, color, shade)


## Each buoy bobs on its own beat.
func _bob(index: int) -> Vector2:
	return Vector2(0.0, sin(_time * 2.0 + index * 1.7) * 2.0)


func _draw_rope(from: Vector2, to: Vector2) -> void:
	var points := PackedVector2Array()
	for step in 9:
		var t := step / 8.0
		points.append(from.lerp(to, t) + Vector2(0.0, 4.0 * t * (1.0 - t) * SAG))
	draw_polyline(points, IsoDraw.OUTLINE, 5.0, true)
	draw_polyline(points, ROPE, 2.5, true)


## `at` is where the ball meets the water.
func _draw_buoy(at: Vector2, index: int, color: Color, shade: Color) -> void:
	var ripple := fmod(_time * 0.6 + index * 0.37, 1.0)
	_draw_ellipse_ring(at, Vector2(RADIUS * (1.3 + ripple), RADIUS * (0.45 + ripple * 0.35)),
			Color(FOAM, FOAM.a * (1.0 - ripple)), 2.5)
	_draw_ellipse(at + Vector2(3.0, 3.0), Vector2(RADIUS * 1.4, RADIUS * 0.5), WATER_SHADOW)
	# The ball floats with only its bottom under water.
	var center := at + Vector2(0.0, -RADIUS * 0.75)
	draw_circle(center, RADIUS + 3.0, IsoDraw.OUTLINE)
	draw_circle(center, RADIUS, shade)
	draw_circle(center - Vector2.ONE * RADIUS * 0.18, RADIUS * 0.78, color)
	_draw_band(center, WHITE_SHADE if color == WHITE else WHITE)
	_draw_ellipse(center + Vector2(-0.36, -0.55) * RADIUS, Vector2(0.3, 0.16) * RADIUS, Color(1.0, 1.0, 1.0, 0.85), -0.6)
	draw_circle(center + Vector2(0.14, -0.72) * RADIUS, RADIUS * 0.1, Color(1.0, 1.0, 1.0, 0.85))
	# Little splashes of foam at both sides of the waterline.
	for side: float in [-1.0, 1.0]:
		var splash := PackedVector2Array()
		for step in 5:
			var angle := PI * (0.15 + 0.3 * step / 4.0)
			splash.append(at + Vector2(side * (RADIUS * 0.6 + cos(angle) * RADIUS * 0.7), sin(angle) * RADIUS * 0.35 - 1.0))
		draw_polyline(splash, WHITE, 3.0, true)


## A stripe around the ball's middle, bent like a ring seen from slightly above.
func _draw_band(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for edge: Vector2 in [Vector2(0.05, 1.0), Vector2(0.32, -1.0)]:
		for step in 9:
			var along := edge.y * (-1.0 + 2.0 * step / 8.0)
			var y := (edge.x + 0.27 * (1.0 - along * along)) * RADIUS
			var half := sqrt(maxf(RADIUS * RADIUS - y * y, 0.0))
			points.append(center + Vector2(along * half, y))
	draw_colored_polygon(points, color)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, IsoDraw.OUTLINE, 2.0, true)


func _ellipse_points(center: Vector2, radii: Vector2, rotation: float = 0.0, count: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in count:
		var angle := TAU * step / count
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y).rotated(rotation))
	return points


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color, rotation: float = 0.0) -> void:
	draw_colored_polygon(_ellipse_points(center, radii, rotation), color)


func _draw_ellipse_ring(center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var points := _ellipse_points(center, radii)
	points.append(points[0])
	draw_polyline(points, color, width, true)
