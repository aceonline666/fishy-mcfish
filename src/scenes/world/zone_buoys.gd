class_name ZoneBuoys
extends Node2D
## Lines of floating buoys marking where the deeper zones begin. Drawn in code.

const SPACING := 110.0
const ROPE := Color(0.95, 0.95, 0.9, 0.6)
const RED := Color(0.92, 0.25, 0.22)
const WHITE := Color(0.98, 0.97, 0.94)
const OPEN_GREEN := Color(0.35, 0.8, 0.45)

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
			points.append(Iso.to_screen(Vector2(x, line.x)) + Vector2(0.0, sin(_time * 2.0 + x * 0.05) * 2.0))
			x += SPACING
		draw_polyline(points, ROPE, 2.0, true)
		for i in points.size():
			var at := points[i] + Vector2(0.0, -6.0)
			draw_circle(at, 10.0, IsoDraw.OUTLINE)
			draw_circle(at, 8.0, OPEN_GREEN if open else (RED if i % 2 == 0 else WHITE))
			draw_circle(at + Vector2(-3.0, -3.0), 2.5, Color(1.0, 1.0, 1.0, 0.7))
