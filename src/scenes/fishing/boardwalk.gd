class_name Boardwalk
extends Node2D
## A wooden boardwalk on the beach: planks across the walk between two side beams, on the
## isometric grid. Marks the free path from the water up to the shops. Drawn once, in code.

const PLANK := Color(0.76, 0.57, 0.36)
const PLANK_LIGHT := Color(0.84, 0.66, 0.44)
const BEAM := Color(0.5, 0.34, 0.2)
const SHADOW := Color(0.0, 0.0, 0.0, 0.15)
## Ground depth of a plank and the gap between planks.
const PLANK_DEPTH := 34.0
const GAP := 8.0
const BEAM_WIDTH := 16.0

## Ground rectangle covered by the walk.
var area := Rect2()


func setup(ground_area: Rect2) -> void:
	area = ground_area
	queue_redraw()


func _draw() -> void:
	_fill(area.grow(6.0), SHADOW, Vector2(4.0, 8.0))
	var y := area.position.y
	var i := 0
	while y < area.end.y:
		var depth := minf(PLANK_DEPTH, area.end.y - y)
		_fill(Rect2(area.position.x, y, area.size.x, depth), PLANK if i % 2 == 0 else PLANK_LIGHT)
		y += PLANK_DEPTH + GAP
		i += 1
	_fill(Rect2(area.position.x - BEAM_WIDTH, area.position.y, BEAM_WIDTH, area.size.y), BEAM)
	_fill(Rect2(area.end.x, area.position.y, BEAM_WIDTH, area.size.y), BEAM)


## Fills a ground rectangle, optionally shifted on screen.
func _fill(rect: Rect2, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var corners := PackedVector2Array()
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		corners.append(Iso.to_screen(corner) + offset)
	draw_colored_polygon(corners, color)
