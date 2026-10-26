class_name Boardwalk
extends Node2D
## A wooden boardwalk on the beach, in the colours of the painted pier (assets/sprites/props):
## warm planks across the walk with dark seams, side beams, and posts with a blue rope along both
## sides. Marks the free path from the water up to the shops. Drawn once, in code, on the
## isometric grid.

const PLANK_COLORS: Array[Color] = [Color(0.84, 0.55, 0.26), Color(0.9, 0.63, 0.31), Color(0.76, 0.48, 0.22)]
const SEAM := Color(0.42, 0.24, 0.12)
const BEAM := Color(0.47, 0.29, 0.16)
const POST := Color(0.58, 0.36, 0.19)
const POST_TOP := Color(0.8, 0.55, 0.3)
const ROPE := Color(0.17, 0.35, 0.64)
const OUTLINE := Color(0.15, 0.09, 0.05)
const SHADOW := Color(0.0, 0.0, 0.0, 0.15)
## Ground depth of a plank and the gap between planks.
const PLANK_DEPTH := 30.0
const GAP := 5.0
const BEAM_WIDTH := 18.0
## Posts along the sides: ground spacing, screen height and radius.
const POST_SPACING := 210.0
const POST_HEIGHT := 46.0
const POST_RADIUS := 9.0
## How far the rope sags between two posts (screen pixels).
const ROPE_SAG := 12.0

## Ground rectangle covered by the walk.
var area := Rect2()


func setup(ground_area: Rect2) -> void:
	area = ground_area
	queue_redraw()


func _draw() -> void:
	_fill(area.grow(8.0), SHADOW, Vector2(5.0, 9.0))
	_fill(Rect2(area.position.x - BEAM_WIDTH, area.position.y, area.size.x + BEAM_WIDTH * 2.0, area.size.y), BEAM)
	var y := area.position.y
	var i := 0
	while y < area.end.y:
		var depth := minf(PLANK_DEPTH, area.end.y - y)
		var plank := Rect2(area.position.x, y, area.size.x, depth)
		_fill(plank, PLANK_COLORS[(i * 7) % PLANK_COLORS.size()])
		# A seam along the back edge of every plank, and a nail at each end.
		var seam_from := Iso.to_screen(plank.position)
		var seam_to := Iso.to_screen(Vector2(plank.end.x, plank.position.y))
		draw_line(seam_from, seam_to, SEAM, 2.0, true)
		for x: float in [plank.position.x + 14.0, plank.end.x - 14.0]:
			draw_circle(Iso.to_screen(Vector2(x, y + depth * 0.5)), 1.8, SEAM)
		y += PLANK_DEPTH + GAP
		i += 1
	for side: float in [area.position.x - BEAM_WIDTH * 0.5, area.end.x + BEAM_WIDTH * 0.5]:
		_draw_railing(side)


## Posts down one side of the walk, joined by a sagging rope.
func _draw_railing(x: float) -> void:
	var tops: Array[Vector2] = []
	var y := area.position.y + 20.0
	while y <= area.end.y:
		var foot := Iso.to_screen(Vector2(x, y))
		var top := foot + Vector2(0.0, -POST_HEIGHT)
		draw_line(foot, top, OUTLINE, POST_RADIUS * 2.0 + 3.0)
		draw_line(foot, top, POST, POST_RADIUS * 2.0)
		draw_colored_polygon(Iso.ellipse(top, POST_RADIUS + 1.5, 10), OUTLINE)
		draw_colored_polygon(Iso.ellipse(top, POST_RADIUS, 10), POST_TOP)
		tops.append(top + Vector2(0.0, 8.0))
		y += POST_SPACING
	for k in range(1, tops.size()):
		var rope := PackedVector2Array()
		for step in 9:
			var t := step / 8.0
			rope.append(tops[k - 1].lerp(tops[k], t) + Vector2(0.0, sin(t * PI) * ROPE_SAG))
		draw_polyline(rope, OUTLINE, 5.0, true)
		draw_polyline(rope, ROPE, 3.0, true)


## Fills a ground rectangle, optionally shifted on screen.
func _fill(rect: Rect2, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var corners := PackedVector2Array()
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		corners.append(Iso.to_screen(corner) + offset)
	draw_colored_polygon(corners, color)
