class_name ActionSquare
extends Node2D
## A pad on the ground that does something while the wader stands on it: store the catch, sell
## fish at a shop, or pay towards a purchase. A raised slab on the isometric grid with rounded
## corners, longer along its row than deep. Drawn in code.

enum Kind { STORE, SELL, BUY }

## Pad colours by Kind.
const COLORS: Array[Color] = [Color(0.55, 0.85, 1.0), Color(1.0, 0.62, 0.3), Color(0.55, 1.0, 0.6)]
const CALLING_COLOR := Color(1.0, 0.85, 0.2)
const SUBTITLE_COLOR := Color(0.92, 0.96, 1.0)
const SHADOW := Color(0.0, 0.0, 0.0, 0.18)
## Screen height of the slab's edge.
const THICKNESS := 10.0
## Corner radius in ground units.
const CORNER_RADIUS := 50.0
const DEFAULT_HALF := Vector2(180.0, 110.0)

var id := ""
var kind := Kind.STORE
var title := ""
## Small second line, e.g. the zones whose fish a shop sells.
var subtitle := ""
## Total price of a BUY pad.
var price := 0.0
## Coins already paid into a BUY pad.
var paid := 0.0
## Half the length (along the row) and depth, in ground units.
var half_extents := DEFAULT_HALF
var ground_center := Vector2.ZERO
## True while the wader stands on the pad.
var active := false
## Pulses to draw attention.
var calling := false

var _time := 0.0


func setup(square_id: String, square_kind: Kind, square_title: String, center: Vector2, half: Vector2 = DEFAULT_HALF) -> void:
	id = square_id
	kind = square_kind
	title = square_title
	half_extents = half
	ground_center = center
	position = Iso.to_screen(center)


func contains(ground: Vector2) -> bool:
	var offset := (ground - ground_center).abs()
	return offset.x <= half_extents.x and offset.y <= half_extents.y


func _process(delta: float) -> void:
	_time += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	var color := COLORS[kind]
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	var half := half_extents * (1.0 + 0.04 * pulse if calling else 1.0)
	var lift := Vector2(0.0, -THICKNESS * (0.4 if active else 1.0))
	var top := IsoDraw.rounded_footprint(lift, half, CORNER_RADIUS)

	draw_colored_polygon(IsoDraw.rounded_footprint(Vector2(4.0, 8.0), half, CORNER_RADIUS), SHADOW)
	IsoDraw.fill_outlined(self, IsoDraw.rounded_footprint(Vector2.ZERO, half, CORNER_RADIUS), color.darkened(0.45), 5.0)
	draw_colored_polygon(top, Color(color, 0.55 if active else 0.38))
	if kind == Kind.BUY and price > 0.0 and paid > 0.0:
		# The paid share fills the pad along its row.
		var share := clampf(paid / price, 0.0, 1.0)
		var start := -half.x - 1.0
		var end := start + (2.0 * half.x + 2.0) * share
		var clip := PackedVector2Array()
		for corner: Vector2 in [Vector2(start, -half.y - 1.0), Vector2(end, -half.y - 1.0), Vector2(end, half.y + 1.0), Vector2(start, half.y + 1.0)]:
			clip.append(lift + Iso.to_screen(corner))
		for part in Geometry2D.intersect_polygons(top, clip):
			draw_colored_polygon(part, Color(color, 0.85))
	var border := top.duplicate()
	border.append(top[0])
	draw_polyline(border, IsoDraw.OUTLINE, 10.0, true)
	draw_polyline(border, CALLING_COLOR if calling else color.lightened(0.45), 5.0, true)
	var rim := IsoDraw.rounded_footprint(lift, half - Vector2(22.0, 22.0), CORNER_RADIUS * 0.6)
	rim.append(rim[0])
	draw_polyline(rim, Color(1.0, 1.0, 1.0, 0.35), 2.0, true)
	_draw_text(lift)


## Title, the optional subtitle and, on BUY pads, the price still to pay.
func _draw_text(at: Vector2) -> void:
	var lines := 1 + (1 if not subtitle.is_empty() else 0) + (1 if kind == Kind.BUY else 0)
	var y := at.y - (lines - 1) * 17.0
	IsoDraw.label(self, Vector2(at.x, y), title, 34 if kind == Kind.BUY else 38)
	if not subtitle.is_empty():
		y += 32.0
		IsoDraw.label(self, Vector2(at.x, y), subtitle, 24, SUBTITLE_COLOR)
	if kind == Kind.BUY:
		y += 34.0
		IsoDraw.coin(self, Vector2(at.x - 46.0, y), 12.0)
		IsoDraw.label(self, Vector2(at.x + 10.0, y), NumberFormat.compact(maxf(price - paid, 0.0)), 34, CALLING_COLOR)
