class_name ZoneBuoys
extends Node2D
## Lines of floating buoys marking where the deeper zones begin. Drawn in code, in the comic
## look of the painted sprites: dark outline, a shaded crescent, a glossy highlight and a ring
## of foam where the ball meets the water.
## Each buoy is its own node, drawn once and only moved as it bobs (redrawing every ball every
## frame cost most of the frame); only the ropes and the foam rings are drawn anew each frame.
## The first line lies in shallow water, where the wader wades: it stays on the floor. Further out
## the wader swims under water, so the lines from the second one on float above it, on the
## surface layer (Layers.SURFACE).

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
## Lines from this index on are drawn on the surface layer, above the wader.
const SURFACE_FROM := 1
## The last lines lie in the open sea's swell (src/shaders/swell.gdshader): they ride it, rising
## and falling slowly and much further, and rocking side to side.
const ROUGH_LINES := 3

## Ground y of each buoy line and whether the zone behind it is open.
var _lines: Array[Vector2] = []
var _width := 0.0
var _time := 0.0
## Per line: where each buoy meets the calm water, and the buoy nodes standing there.
var _rests: Array[PackedVector2Array] = []
var _buoys: Array[Array] = []
## Draws the ropes, foam and buoys of the lines from SURFACE_FROM on, above the wader.
var _surface: Node2D


func _ready() -> void:
	_surface = Node2D.new()
	Layers.put(_surface, Layers.SURFACE)
	_surface.draw.connect(_draw_lines.bind(_surface, SURFACE_FROM, -1))
	add_child(_surface)


## `lines`: x = ground y of the line, y = 1 if the zone beyond is open, else 0.
func setup(lines: Array[Vector2], width: float) -> void:
	_lines = lines
	_width = width
	for parent: Node in [self, _surface]:
		for child in parent.get_children():
			if child != _surface:
				child.queue_free()
	_rests.clear()
	_buoys.clear()
	for line_index in _lines.size():
		var line := _lines[line_index]
		var open := line.y > 0.5
		var rests := PackedVector2Array()
		var x := 0.0
		while x <= _width:
			rests.append(Iso.to_screen(Vector2(x, line.x)))
			x += SPACING
		var buoys: Array[Buoy] = []
		for i in rests.size():
			var red := i % 2 == 0
			var buoy := Buoy.new()
			buoy.color = GREEN if open else (RED if red else WHITE)
			buoy.shade = GREEN_SHADE if open else (RED_SHADE if red else WHITE_SHADE)
			buoy.position = rests[i]
			(_surface if line_index >= SURFACE_FROM else self).add_child(buoy)
			buoys.append(buoy)
		_rests.append(rests)
		_buoys.append(buoys)
	queue_redraw()
	_surface.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	for line in _buoys.size():
		var rests := _rests[line]
		var buoys := _buoys[line]
		for i in buoys.size():
			(buoys[i] as Node2D).position = rests[i] + _bob(line, i)
	queue_redraw()
	_surface.queue_redraw()


func _draw() -> void:
	_draw_lines(self, 0, SURFACE_FROM)


## The ropes and the foam rings on screen of the lines from `first` to before `end` (-1: all
## the rest), on `canvas`; the balls are the Buoy children, drawn over them.
func _draw_lines(canvas: CanvasItem, first: int, end: int) -> void:
	var view := get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	view = view.grow(SPACING)
	for line in range(first, _rests.size() if end < 0 else mini(end, _rests.size())):
		var rests := _rests[line]
		for i in rests.size() - 1:
			if view.has_point(rests[i]) or view.has_point(rests[i + 1]):
				_draw_rope(canvas, rests[i] + _bob(line, i), rests[i + 1] + _bob(line, i + 1))
		for i in rests.size():
			if not view.has_point(rests[i]):
				continue
			var ripple := fmod(_time * 0.6 + i * 0.37, 1.0)
			_draw_ellipse_ring(canvas, rests[i] + _bob(line, i), Vector2(RADIUS * (1.3 + ripple), RADIUS * (0.45 + ripple * 0.35)),
					Color(FOAM, FOAM.a * (1.0 - ripple)), 2.5)


## Each buoy bobs on its own beat; in the swell of the last lines, the swell's crests run along
## the line.
func _bob(line: int, index: int) -> Vector2:
	if line >= _rests.size() - ROUGH_LINES:
		var roll := _time * 1.2 + index * 0.45 + line * 1.3
		return Vector2(cos(roll) * 3.0, sin(roll) * 8.0)
	return Vector2(0.0, sin(_time * 2.0 + index * 1.7) * 2.0)


func _draw_rope(canvas: CanvasItem, from: Vector2, to: Vector2) -> void:
	var points := PackedVector2Array()
	for step in 9:
		var t := step / 8.0
		points.append(from.lerp(to, t) + Vector2(0.0, 4.0 * t * (1.0 - t) * SAG))
	canvas.draw_polyline(points, IsoDraw.OUTLINE, 5.0, true)
	canvas.draw_polyline(points, ROPE, 2.5, true)


static func _ellipse_points(center: Vector2, radii: Vector2, rotation: float = 0.0, count: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in count:
		var angle := TAU * step / count
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y).rotated(rotation))
	return points


static func _draw_ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, rotation: float = 0.0) -> void:
	canvas.draw_colored_polygon(_ellipse_points(center, radii, rotation), color)


static func _draw_ellipse_ring(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var points := _ellipse_points(center, radii)
	points.append(points[0])
	canvas.draw_polyline(points, color, width, true)


## One ball, drawn once around its origin: where the ball meets the water.
class Buoy:
	extends Node2D

	var color: Color
	var shade: Color

	func _draw() -> void:
		ZoneBuoys._draw_ellipse(self, Vector2(3.0, 3.0), Vector2(RADIUS * 1.4, RADIUS * 0.5), WATER_SHADOW)
		# The ball floats with only its bottom under water.
		var center := Vector2(0.0, -RADIUS * 0.75)
		draw_circle(center, RADIUS + 3.0, IsoDraw.OUTLINE)
		draw_circle(center, RADIUS, shade)
		draw_circle(center - Vector2.ONE * RADIUS * 0.18, RADIUS * 0.78, color)
		_draw_band(center, WHITE_SHADE if color == WHITE else WHITE)
		ZoneBuoys._draw_ellipse(self, center + Vector2(-0.36, -0.55) * RADIUS, Vector2(0.3, 0.16) * RADIUS,
				Color(1.0, 1.0, 1.0, 0.85), -0.6)
		draw_circle(center + Vector2(0.14, -0.72) * RADIUS, RADIUS * 0.1, Color(1.0, 1.0, 1.0, 0.85))
		# Little splashes of foam at both sides of the waterline.
		for side: float in [-1.0, 1.0]:
			var splash := PackedVector2Array()
			for step in 5:
				var angle := PI * (0.15 + 0.3 * step / 4.0)
				splash.append(Vector2(side * (RADIUS * 0.6 + cos(angle) * RADIUS * 0.7), sin(angle) * RADIUS * 0.35 - 1.0))
			draw_polyline(splash, WHITE, 3.0, true)

	## A stripe around the ball's middle, bent like a ring seen from slightly above.
	func _draw_band(center: Vector2, band_color: Color) -> void:
		var points := PackedVector2Array()
		for edge: Vector2 in [Vector2(0.05, 1.0), Vector2(0.32, -1.0)]:
			for step in 9:
				var along := edge.y * (-1.0 + 2.0 * step / 8.0)
				var y := (edge.x + 0.27 * (1.0 - along * along)) * RADIUS
				var half := sqrt(maxf(RADIUS * RADIUS - y * y, 0.0))
				points.append(center + Vector2(along * half, y))
		draw_colored_polygon(points, band_color)
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, IsoDraw.OUTLINE, 2.0, true)
