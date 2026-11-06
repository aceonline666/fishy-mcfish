class_name SalesBelt
extends Node2D
## The conveyor belt from the tank up the beach to the booths: the grown fish ride on it in the
## order they will be sold, the next one at the booths' end, each with its price above it. Fish
## slide along when one is sold and come on at the tank end when they grow up, each in a fish
## glass. The belt covers cells of the layout grid (Grid) and runs north, up the beach. It is a
## painting (art_source/buildings/sales_belt_sprite_prompt.md) cut by tools/cut_belt.py into the tank end,
## a section that repeats and the booth end, so it is drawn at any length; the glasses are still a
## PLACEHOLDER (assets/sprites/props/fish_bowl.svg). The node sits at the middle of the belt, on
## the ground.

## Ground distance between two fish on the belt.
const SLOT := 120.0
## Share of the cells' width the belt takes.
const WIDTH_SHARE := 0.6
## The painted pieces and their top-left corners in the (narrowed) painting, as
## tools/cut_belt.py prints them.
const TANK_PIECE := preload("res://assets/sprites/props/sales_belt_tank.png")
const SECTION_PIECE := preload("res://assets/sprites/props/sales_belt_section.png")
const BOOTH_PIECE := preload("res://assets/sprites/props/sales_belt_booth.png")
const TANK_PIECE_AT := Vector2(75.0, 516.0)
const SECTION_PIECE_AT := Vector2(435.0, 441.0)
const BOOTH_PIECE_AT := Vector2(690.0, 120.0)
## The painting's measures, as in tools/cut_belt.py: the middle of the belt's top at the tank end,
## the belt's half width and where the cuts are, in pixels across along the run; the booth end of
## the belt's top; how far below the top's middle the ground is.
const PAINTED_TANK_END := Vector2(110.0, 768.0)
const PAINTED_HALF_WIDTH := 65.0
const SECTION_FROM := 390.0
const SECTION_TO := 535.0
const END_FROM := 645.0
const PAINTED_BOOTH_END := 936.0
const PAINTED_HEIGHT := 167.0
## The belt's top, cut out of the pieces and drawn under them, scrolling while the fish slide:
## straightened (x along the run, y across), one section long so it repeats. It covers the run
## from SURFACE_FROM to SURFACE_END_GAP short of the booth end, SURFACE_HALF_WIDTH to each side.
const SURFACE := preload("res://assets/sprites/props/sales_belt_surface.png")
const SURFACE_FROM := 6.0
const SURFACE_END_GAP := 8.0
const SURFACE_HALF_WIDTH := 64.0
const BOWL_TEXTURE: Texture2D = preload("res://assets/sprites/props/fish_bowl.svg")
const BOWL_WIDTH := 78.0
const FISH_LENGTH := 46.0
## How fast fish slide to their place, in slots per second.
const SLIDE_SPEED := 4.0
const PRICE_COLOR := Color(1.0, 0.86, 0.3)
const MORE_COLOR := Color(1.0, 1.0, 1.0)

var tank: TankState
## Returns the FishArt for a species id.
var art_for: Callable

## Half the belt's ground size, east-west by north-south.
var _half := Vector2.ZERO
## Screen pixels per painted pixel, and the screen height of the belt's top above the ground.
var _scale := 1.0
var _lift := 0.0
## Where each shown fish is drawn, in slots counted from the booths' end.
var _places: Dictionary[TankFish, float] = {}
var _time := 0.0
## How far the belt's top has run, in painted pixels along it.
var _run := 0.0


## `area` is the ground the belt covers: whole cells, running north from the tank's end.
func setup(tank_state: TankState, area: Rect2, art_lookup: Callable) -> void:
	tank = tank_state
	art_for = art_lookup
	position = Iso.to_screen(area.get_center())
	_half = Vector2(area.size.x * WIDTH_SHARE, area.size.y) * 0.5
	# The belt's width across on screen, over its painted width.
	_scale = Iso.to_screen(Vector2(_half.x * 2.0, 0.0)).x / (PAINTED_HALF_WIDTH * 2.0)
	_lift = PAINTED_HEIGHT * _scale
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


## How many fish fit on the belt.
func slots() -> int:
	return maxi(int(_half.y * 2.0 / SLOT), 1)


## The grown fish in the order they will be sold (Selling.next_to_sell: the first grown first).
func queue() -> Array[TankFish]:
	var grown: Array[TankFish] = []
	for fish in tank.fish:
		if fish.growth >= 1.0:
			grown.append(fish)
	return grown


func _price(fish: TankFish) -> float:
	return Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)


func _process(delta: float) -> void:
	_time += delta
	var shown := queue()
	var count := mini(shown.size(), slots())
	var places: Dictionary[TankFish, float] = {}
	var moved := 0.0
	for i in count:
		# New fish come in at the tank end; the others slide towards their place.
		var place: float = _places.get(shown[i], float(slots()))
		places[shown[i]] = move_toward(place, float(i), SLIDE_SPEED * delta)
		moved = maxf(moved, place - places[shown[i]])
	_places = places
	# The belt carries them: it runs as far as they slide towards the booths.
	var slot_length := Iso.to_screen(Vector2(0.0, -_half.y * 2.0 / slots())).x / _scale
	_run = fmod(_run + moved * slot_length, SURFACE.get_width())
	queue_redraw()


## Screen position on the belt's top, `along` ground units north of its tank end.
func _on_top(along: float) -> Vector2:
	return Iso.to_screen(Vector2(0.0, _half.y - along)) + Vector2(0.0, -_lift)


## Draws the painted belt: the booth end at the belt's north end, sections from there down to the
## tank end, then the tank end on top (the nearer piece covers the overlap). A belt shorter than
## its two ends draws them overlapping.
func _draw_belt() -> void:
	draw_set_transform(_on_top(0.0), 0.0, Vector2.ONE * _scale)
	# The belt's length in painted pixels across, and where the booth end goes.
	var length := Iso.to_screen(Vector2(0.0, -_half.y * 2.0)).x / _scale
	var booth_shift := length - PAINTED_BOOTH_END
	_draw_surface(length - SURFACE_END_GAP)
	_draw_piece(BOOTH_PIECE, BOOTH_PIECE_AT, booth_shift)
	var from := END_FROM + booth_shift
	while from > SECTION_FROM:
		from -= SECTION_TO - SECTION_FROM
		_draw_piece(SECTION_PIECE, SECTION_PIECE_AT, from - SECTION_FROM)
	_draw_piece(TANK_PIECE, TANK_PIECE_AT, 0.0)
	draw_set_transform(Vector2.ZERO)


## The belt's top from SURFACE_FROM to `to` (painted pixels along the run), its pattern moved
## `_run` towards the booths.
func _draw_surface(to: float) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var size := SURFACE.get_size()
	for corner: Vector2 in [Vector2(SURFACE_FROM, -1.0), Vector2(to, -1.0), Vector2(to, 1.0), Vector2(SURFACE_FROM, 1.0)]:
		var along := corner.x
		var across := corner.y * SURFACE_HALF_WIDTH
		points.append(Vector2(along + across, (across - along) * 0.5))
		uvs.append(Vector2((along - SECTION_FROM - _run) / size.x, (across + SURFACE_HALF_WIDTH) / (size.y - 1.0)))
	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, SURFACE)


## A piece at its place in the painting, moved `shift` painted pixels across along the run.
func _draw_piece(piece: Texture2D, at: Vector2, shift: float) -> void:
	draw_texture(piece, at - PAINTED_TANK_END + Vector2(shift, -shift * 0.5))


func _draw() -> void:
	_draw_belt()

	# Each grown fish in a glass on the belt, the next to be sold at the booths' end.
	var bowl := BOWL_TEXTURE.get_size() * (BOWL_WIDTH / BOWL_TEXTURE.get_width())
	var length := _half.y * 2.0
	var shown := queue()
	for i in range(mini(shown.size(), slots()) - 1, -1, -1):
		var fish := shown[i]
		if not _places.has(fish):
			continue
		var at := _on_top(length - (_places[fish] + 0.5) * length / slots())
		draw_texture_rect(BOWL_TEXTURE, Rect2(at - Vector2(bowl.x * 0.5, bowl.y - 6.0), bowl), false)
		var art: FishArt = art_for.call(fish.species_id)
		var swim := Vector2(sin(_time * 1.5 + i) * bowl.x * 0.12, -bowl.y * 0.42)
		var view := Transform2D(Vector2(1.0 if cos(_time * 1.5 + i) > 0.0 else -1.0, 0.0), Vector2(0.0, 1.0), at + swim)
		art.draw(self, view, FISH_LENGTH, _time * 6.0 + i, 0.5)
		IsoDraw.label(self, at + Vector2(0.0, -bowl.y - 16.0), NumberFormat.compact(_price(fish)), 28, PRICE_COLOR)
	if shown.size() > slots():
		IsoDraw.label(self, _on_top(0.0) + Vector2(0.0, -bowl.y - 16.0), "+%d" % (shown.size() - slots()), 28, MORE_COLOR)
