class_name ActionSquare
extends Node2D
## A pad on the ground that does something while the wader stands on it: store the catch, sell
## fish at a shop, pay towards a purchase, or go through a door. A raised slab on the isometric grid with rounded
## corners, longer along its row than deep. Drawn in code.

enum Kind { STORE, SELL, BUY, DOOR }

## Pad colours by Kind.
const COLORS: Array[Color] = [Color(0.55, 0.85, 1.0), Color(1.0, 0.62, 0.3), Color(0.55, 1.0, 0.6), Color(1.0, 0.85, 0.35)]
const CALLING_COLOR := Color(1.0, 0.85, 0.2)
const SUBTITLE_COLOR := Color(0.92, 0.96, 1.0)
const DISABLED_COLOR := Color(0.62, 0.64, 0.68)
const SHADOW := Color(0.0, 0.0, 0.0, 0.22)
## Screen height of the slab's edge.
const THICKNESS := 16.0
## Corner radius in ground units.
const CORNER_RADIUS := 50.0
const DEFAULT_HALF := Vector2(180.0, 110.0)
const ICON_HEIGHT := 125.0
const ICON_MAX_WIDTH := 140.0
## Screen x of the icon's centre and of the text next to it.
const ICON_X := -118.0
const TEXT_X_WITH_ICON := 52.0

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
## Greyed out: there is nothing to do here yet (the subtitle says why).
var disabled := false
## Picture of what the pad buys, standing on its left end; null for none.
var icon: Texture2D

var _time := 0.0
## What the last drawing showed; the pad is only redrawn when this changes or while it pulses.
var _drawn := []


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
	if not visible:
		return
	var shown := [kind, title, subtitle, price, paid, active, calling, icon, disabled]
	if calling or shown != _drawn:
		_drawn = shown
		queue_redraw()


func _draw() -> void:
	var color := COLORS[kind] if not disabled else COLORS[kind].lerp(DISABLED_COLOR, 0.8)
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	var half := half_extents * (1.0 + 0.04 * pulse if calling else 1.0)
	var lift := Vector2(0.0, -THICKNESS * (0.35 if active else 1.0))
	var top := IsoDraw.rounded_footprint(lift, half, CORNER_RADIUS)

	draw_colored_polygon(IsoDraw.rounded_footprint(Vector2(6.0, 12.0), half, CORNER_RADIUS), SHADOW)
	# The slab's edge: everything between its bottom and its top outline.
	var bottom := IsoDraw.rounded_footprint(Vector2.ZERO, half, CORNER_RADIUS)
	IsoDraw.fill_outlined(self, Geometry2D.convex_hull(bottom + top), color.darkened(0.5), 6.0)
	# A BUY pad is dull until paid for; the paid share lights up along its row.
	var face := color.darkened(0.3) if kind == Kind.BUY else color
	if active:
		face = face.lightened(0.15)
	IsoDraw.fill_vertical_gradient(self, top, face.lightened(0.3), face.darkened(0.1))
	if kind == Kind.BUY and price > 0.0 and paid > 0.0:
		var share := clampf(paid / price, 0.0, 1.0)
		var start := -half.x - 1.0
		var end := start + (2.0 * half.x + 2.0) * share
		var clip := PackedVector2Array()
		for corner: Vector2 in [Vector2(start, -half.y - 1.0), Vector2(end, -half.y - 1.0), Vector2(end, half.y + 1.0), Vector2(start, half.y + 1.0)]:
			clip.append(lift + Iso.to_screen(corner))
		for part in Geometry2D.intersect_polygons(top, clip):
			IsoDraw.fill_vertical_gradient(self, part, color.lightened(0.45), color.lightened(0.05))
	var border := top.duplicate()
	border.append(top[0])
	draw_polyline(border, IsoDraw.OUTLINE, 6.0, true)
	if calling:
		draw_polyline(border, CALLING_COLOR, 3.5, true)
	var rim := IsoDraw.rounded_footprint(lift, half - Vector2(16.0, 16.0), CORNER_RADIUS * 0.7)
	rim.append(rim[0])
	draw_polyline(rim, Color(1.0, 1.0, 1.0, 0.4), 3.0, true)
	_draw_gloss(lift, half)
	if icon != null:
		var size := icon.get_size() * minf(ICON_HEIGHT / icon.get_height(), ICON_MAX_WIDTH / icon.get_width())
		draw_texture_rect(icon, Rect2(lift + Vector2(ICON_X - size.x * 0.5, 34.0 - size.y), size), false)
	_draw_text(lift + Vector2(TEXT_X_WITH_ICON if icon != null else 0.0, 0.0))


## A white shine along the back left edge, as on the buttons.
func _draw_gloss(lift: Vector2, half: Vector2) -> void:
	var inset := IsoDraw.rounded_footprint(lift, half - Vector2(34.0, 34.0), CORNER_RADIUS * 0.5, 12)
	var upper_left := func(point: Vector2) -> bool:
		return point.x < lift.x - 12.0 and point.y < lift.y - 6.0
	# Start outside the shine, so its points come in one run.
	var first := 0
	while first < inset.size() and upper_left.call(inset[first]):
		first += 1
	var shine := PackedVector2Array()
	for step in inset.size():
		var point := inset[(first + step) % inset.size()]
		if upper_left.call(point):
			shine.append(point)
		elif not shine.is_empty():
			break
	if shine.size() >= 2:
		draw_polyline(shine, Color(1.0, 1.0, 1.0, 0.6), 7.0, true)


## Title, the optional subtitle and, on BUY pads, the price still to pay.
func _draw_text(at: Vector2) -> void:
	var lines := 1 + (1 if not subtitle.is_empty() else 0) + (1 if kind == Kind.BUY else 0)
	var y := at.y - (lines - 1) * 17.0
	IsoDraw.label(self, Vector2(at.x, y), title, 34 if kind == Kind.BUY else 40, Color.WHITE, true)
	if not subtitle.is_empty():
		y += 32.0
		IsoDraw.label(self, Vector2(at.x, y), subtitle, 24, SUBTITLE_COLOR)
	if kind == Kind.BUY:
		y += 34.0
		IsoDraw.coin(self, Vector2(at.x - 46.0, y), 12.0)
		IsoDraw.label(self, Vector2(at.x + 10.0, y), NumberFormat.compact(maxf(price - paid, 0.0)), 36, CALLING_COLOR, true)
