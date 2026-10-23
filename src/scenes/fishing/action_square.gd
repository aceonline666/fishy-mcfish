class_name ActionSquare
extends Node2D
## A square on the ground that does something while the wader stands on it: store the catch,
## sell fish at a shop, or pay towards a purchase. Drawn in code.

enum Kind { STORE, SELL, BUY }

## Square colours by Kind.
const COLORS: Array[Color] = [Color(0.55, 0.85, 1.0), Color(1.0, 0.62, 0.3), Color(0.55, 1.0, 0.6)]
const CALLING_COLOR := Color(1.0, 0.85, 0.2)

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
	var corners := IsoDraw.footprint(Vector2.ZERO, Vector2(h, h))
	draw_colored_polygon(corners, Color(color, 0.45 if active else 0.25))
	if kind == Kind.BUY and price > 0.0 and paid > 0.0:
		var filled := IsoDraw.footprint(Vector2.ZERO, Vector2(h, h) * sqrt(clampf(paid / price, 0.0, 1.0)))
		draw_colored_polygon(filled, Color(color, 0.7))

	var bracket_color := CALLING_COLOR if calling else color.lightened(0.4)
	for i in 4:
		for neighbour: Vector2 in [corners[(i + 1) % 4], corners[(i + 3) % 4]]:
			var end := corners[i].lerp(neighbour, 0.26)
			draw_line(corners[i], end, IsoDraw.OUTLINE, 10.0, true)
			draw_line(corners[i], end, bracket_color, 5.0, true)

	if kind == Kind.BUY:
		IsoDraw.label(self, Vector2(0.0, -14.0), title, 28)
		IsoDraw.coin(self, Vector2(-36.0, 22.0), 10.0)
		IsoDraw.label(self, Vector2(10.0, 22.0), NumberFormat.compact(maxf(price - paid, 0.0)), 30, CALLING_COLOR)
	else:
		IsoDraw.label(self, Vector2.ZERO, title, 32)
