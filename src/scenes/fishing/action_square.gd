class_name ActionSquare
extends Node2D
## A square on the ground that does something while the wader stands on it: store the catch,
## sell fish at a shop, or pay towards a purchase. Drawn in code.

enum Kind { STORE, SELL, BUY }

## Square colours by Kind.
const COLORS: Array[Color] = [Color(0.55, 0.85, 1.0), Color(1.0, 0.62, 0.3), Color(0.55, 1.0, 0.6)]
const CALLING_COLOR := Color(1.0, 0.85, 0.2)
const SHADOW := Color(0.0, 0.0, 0.0, 0.18)
## Corner radius as a share of the half side length.
const CORNER_RADIUS := 0.35

var id := ""
var kind := Kind.STORE
var title := ""
## Total price of a BUY square.
var price := 0.0
## Coins already paid into a BUY square.
var paid := 0.0
## Half the side length, in ground units.
var half_size := 115.0
var ground_center := Vector2.ZERO
## True while the wader stands on the square.
var active := false
## Pulses to draw attention.
var calling := false

var _time := 0.0


func setup(square_id: String, square_kind: Kind, square_title: String, center: Vector2, half: float = 115.0) -> void:
	id = square_id
	kind = square_kind
	title = square_title
	half_size = half
	ground_center = center
	position = Iso.to_screen(center)


func contains(ground: Vector2) -> bool:
	var offset := (ground - ground_center).abs()
	return offset.x <= half_size and offset.y <= half_size


func _process(delta: float) -> void:
	_time += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	var color := COLORS[kind]
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	var h := half_size * (1.0 + 0.05 * pulse if calling else 1.0)
	var tile := IsoDraw.rounded_footprint(Vector2.ZERO, h, h * CORNER_RADIUS)
	draw_colored_polygon(IsoDraw.rounded_footprint(Vector2(0.0, 7.0), h, h * CORNER_RADIUS), SHADOW)
	draw_colored_polygon(tile, Color(color, 0.5 if active else 0.3))
	if kind == Kind.BUY and price > 0.0 and paid > 0.0:
		var filled_half := h * sqrt(clampf(paid / price, 0.0, 1.0))
		draw_colored_polygon(IsoDraw.rounded_footprint(Vector2.ZERO, filled_half, filled_half * CORNER_RADIUS), Color(color, 0.75))

	var border := tile.duplicate()
	border.append(tile[0])
	draw_polyline(border, IsoDraw.OUTLINE, 12.0, true)
	draw_polyline(border, CALLING_COLOR if calling else color.lightened(0.45), 6.0, true)
	# A thin inner line gives the tile a raised rim.
	var rim := IsoDraw.rounded_footprint(Vector2.ZERO, h - 16.0, (h - 16.0) * CORNER_RADIUS)
	rim.append(rim[0])
	draw_polyline(rim, Color(1.0, 1.0, 1.0, 0.35), 2.5, true)

	if kind == Kind.BUY:
		IsoDraw.label(self, Vector2(0.0, -14.0), title, 28)
		IsoDraw.coin(self, Vector2(-36.0, 22.0), 10.0)
		IsoDraw.label(self, Vector2(10.0, 22.0), NumberFormat.compact(maxf(price - paid, 0.0)), 30, CALLING_COLOR)
	else:
		IsoDraw.label(self, Vector2.ZERO, title, 32)
