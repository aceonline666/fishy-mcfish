class_name Booth
extends Node2D
## A sales booth in the line up the beach, facing east: the buyer stands in front of its counter,
## the seller (a cashier) behind it on the west side. Booth 0 is the player's (no seller: the
## player sells from the "Sell fish" pad) until the first seller is hired, who takes it over; the
## others are the further sellers'. A booth stands in one cell of the layout grid (Grid), its
## counter along the cell's east edge and as long as it; the seller stands behind it on the pier.
## The node sits at the middle of that edge.
##
## The booths form one continuous market row: each draws one segment of the painted row
## (assets/sprites/props/booth_row.png, cut by tools/import_booth_row.py from
## art_source/buildings/booth_row_1.png), which meets its neighbours seamlessly; the first booth
## adds the row's south end, the last its north end. One look for every shop level for now.
##
## The cashiers (assets/sprites/cashier/cashier_N.png, cut by tools/import_cashiers.py) take turns
## in three looks, as tall as the wader. They stand on the pier behind their booth (the painted
## row has a closed back wall), on a child node of their own, so the depth sorting puts the wader
## in front of or behind them like any other figure (the booth is y-sorted with its parent).

const SEGMENT: Texture2D = preload("res://assets/sprites/props/booth_row.png")
const SOUTH_END: Texture2D = preload("res://assets/sprites/props/booth_row_south.png")
const NORTH_END: Texture2D = preload("res://assets/sprites/props/booth_row_north.png")
## The foot of the front post each piece attaches at, in its sprite (pixels): the segment and the
## south end at the booth's south join, the north end at its north join.
const SEGMENT_ANCHOR := Vector2(172.0, 701.0)
const SOUTH_END_ANCHOR := Vector2(239.0, 530.0)
const NORTH_END_ANCHOR := Vector2(172.0, 531.0)
## One segment in the sprites (pixels): from its south join to its north join.
const SEGMENT_STEP := Vector2(373.0, -186.0)
const CASHIERS: Array[Texture2D] = [
	preload("res://assets/sprites/cashier/cashier_1.png"),
	preload("res://assets/sprites/cashier/cashier_2.png"),
	preload("res://assets/sprites/cashier/cashier_3.png"),
]
## A cashier strip: frames side by side, each this big, the feet at CASHIER_FEET; the standing
## frame's figure is CASHIER_FIGURE pixels tall.
const CASHIER_FRAMES := 5
const CASHIER_FRAME := Vector2(221.0, 355.0)
const CASHIER_FEET := Vector2(87.0, 354.0)
const CASHIER_FIGURE := 347.0
## Frames: two to breathe while waiting, then taking the coins, handing over the fish, waving.
const IDLE_FRAMES: Array[int] = [0, 1]
const IDLE_FRAME_S := 0.8
const SALE_FRAMES: Array[Array] = [[2, 0.15], [3, 0.4], [4, 0.45]]
## Where the buyer and the seller stand, seen from the booth (ground units): the seller on the
## pier, a cell west of the counter, behind the booth.
const BUYER_OFFSET := Vector2(140.0, 0.0)
const SELLER_OFFSET := Vector2(-300.0, 0.0)

var ground_position := Vector2.ZERO
## True for the player's booth: no seller.
var is_player := false:
	set(value):
		is_player = value
		_figure.visible = not value
## True for the first booth (the row's south end) and the last (its north end).
var is_first := false
var is_last := false:
	set(value):
		is_last = value
		queue_redraw()
## The shop's level (data/shop_levels.csv). All levels look the same for now.
var level := 1
var _cashier: Texture2D = CASHIERS[0]
var _frame := 0
## Seconds into the current animation, and the sale animation's step (-1 while idle).
var _time := 0.0
var _sale_step := -1
## The cashier's own node, on the pier behind the booth.
var _figure := Node2D.new()


func _init() -> void:
	y_sort_enabled = true
	_figure.position = Iso.to_screen(SELLER_OFFSET)
	_figure.draw.connect(_draw_cashier)
	add_child(_figure)


## `index` 0 is the player's booth, n the n-th seller's. The cashier who sells here is the
## (index + 1)-th seller, so the looks follow the "Hire seller" pad's icons.
func setup(foot: Vector2, index: int) -> void:
	ground_position = foot
	position = Iso.to_screen(foot)
	is_player = index == 0
	is_first = index == 0
	_cashier = CASHIERS[index % CASHIERS.size()]
	_time = index * 0.3
	queue_redraw()
	_figure.queue_redraw()


## Ground position where the buyer at this booth stands.
func buyer_spot() -> Vector2:
	return ground_position + BUYER_OFFSET


## A fish was sold here: the cashier takes the coins, hands it over and waves (the row itself
## stays put, so its seams stay closed).
func bounce() -> void:
	_sale_step = 0
	_time = 0.0
	_show(SALE_FRAMES[0][0])


func _process(delta: float) -> void:
	if is_player:
		return
	_time += delta
	if _sale_step >= 0:
		if _time < SALE_FRAMES[_sale_step][1]:
			return
		_time = 0.0
		_sale_step += 1
		if _sale_step < SALE_FRAMES.size():
			_show(SALE_FRAMES[_sale_step][0])
			return
		_sale_step = -1
	_show(IDLE_FRAMES[int(_time / IDLE_FRAME_S) % IDLE_FRAMES.size()])


func _show(frame: int) -> void:
	if frame != _frame:
		_frame = frame
		_figure.queue_redraw()


## Where the sprite is drawn, relative to the node.
func sprite_bounds() -> Rect2:
	var bounds := _piece_rect(SEGMENT, SEGMENT_ANCHOR, _south_join())
	if is_first:
		bounds = bounds.merge(_piece_rect(SOUTH_END, SOUTH_END_ANCHOR, _south_join()))
	if is_last:
		bounds = bounds.merge(_piece_rect(NORTH_END, NORTH_END_ANCHOR, _north_join()))
	return bounds


## Screen pixels per sprite pixel: a segment is as long as a cell.
func _scale() -> float:
	return Iso.to_screen(Vector2(0.0, Grid.UNIT)).length() / SEGMENT_STEP.length()


func _south_join() -> Vector2:
	return Iso.to_screen(Vector2(0.0, Grid.UNIT * 0.5))


func _north_join() -> Vector2:
	return Iso.to_screen(Vector2(0.0, -Grid.UNIT * 0.5))


func _piece_rect(texture: Texture2D, anchor: Vector2, at: Vector2) -> Rect2:
	return Rect2(at - anchor * _scale(), texture.get_size() * _scale())


## Draws the cashier on their node, the feet on its origin, as tall as the wader.
func _draw_cashier() -> void:
	var scale_factor := Wader.FIGURE_HEIGHT / CASHIER_FIGURE
	var source := Rect2(Vector2(_frame * CASHIER_FRAME.x, 0.0), CASHIER_FRAME)
	_figure.draw_texture_rect_region(_cashier, Rect2(-CASHIER_FEET * scale_factor, CASHIER_FRAME * scale_factor), source)


func _draw() -> void:
	if is_last:
		draw_texture_rect(NORTH_END, _piece_rect(NORTH_END, NORTH_END_ANCHOR, _north_join()), false)
	draw_texture_rect(SEGMENT, _piece_rect(SEGMENT, SEGMENT_ANCHOR, _south_join()), false)
	if is_first:
		draw_texture_rect(SOUTH_END, _piece_rect(SOUTH_END, SOUTH_END_ANCHOR, _south_join()), false)
