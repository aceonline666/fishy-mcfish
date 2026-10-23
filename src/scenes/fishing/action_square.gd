class_name ActionSquare
extends Node2D
## A square on the ground that does something while the wader stands on it: store or sell the
## catch, collect the visitors' coins, or pay towards a purchase. Drawn in code.

enum Kind { STORE, MARKET, CASH, BUY }

## Square colours by Kind.
const COLORS: Array[Color] = [
	Color(0.55, 0.85, 1.0), Color(1.0, 0.62, 0.3), Color(1.0, 0.84, 0.25), Color(0.55, 1.0, 0.6),
]
const CALLING_COLOR := Color(1.0, 0.85, 0.2)

var id := ""
var kind := Kind.STORE
var title := ""
## Total price of a BUY square.
var price := 0.0
## Coins already paid into a BUY square.
var paid := 0.0
## Coins lying on a CASH square.
var amount := 0.0
## Half the side length, in ground units.
var half_size := 90.0
var ground_center := Vector2.ZERO
## True while the wader stands on the square.
var active := false
## Pulses to draw attention.
var calling := false

var _time := 0.0


func setup(square_id: String, square_kind: Kind, square_title: String, center: Vector2, half: float = 90.0) -> void:
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

	match kind:
		Kind.BUY:
			IsoDraw.label(self, Vector2(0.0, -12.0), title, 26)
			IsoDraw.coin(self, Vector2(-34.0, 20.0), 9.0)
			IsoDraw.label(self, Vector2(10.0, 20.0), NumberFormat.compact(maxf(price - paid, 0.0)), 28, CALLING_COLOR)
		Kind.CASH:
			_draw_coin_pile()
			IsoDraw.label(self, Vector2(0.0, 30.0), title, 26)
		_:
			IsoDraw.label(self, Vector2.ZERO, title, 30)


## A pile that grows with the amount of coins waiting.
func _draw_coin_pile() -> void:
	if amount < 1.0:
		return
	var coins := clampi(int(log(amount + 1.0) / log(2.0)) * 2, 1, 18)
	for i in coins:
		var column := i % 3
		var row := i / 3
		IsoDraw.coin(self, Vector2((column - 1) * 18.0, -4.0 - row * 6.0 + absf(column - 1) * 4.0), 11.0)
	IsoDraw.label(self, Vector2(0.0, -30.0 - (coins / 3) * 6.0), NumberFormat.compact(amount), 28, CALLING_COLOR)
