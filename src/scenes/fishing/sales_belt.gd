class_name SalesBelt
extends Node2D
## The conveyor belt from the tank up the beach to the booths: the grown fish ride on it in the
## order they will be sold, the next one at the booths' end, each with its price above it. Fish
## slide along when one is sold and come on at the tank end when they grow up, each in a fish
## glass. The belt covers cells of the layout grid (Grid) and runs north, up the beach. Drawn in
## code as a PLACEHOLDER (glass: assets/sprites/props/fish_bowl.svg) until the final art exists.
## The node sits at the middle of the belt, on the ground.

## Ground distance between two fish on the belt.
const SLOT := 120.0
## Screen height of the belt's top above the ground.
const LIFT := 18.0
## Share of the cells' width the belt takes.
const WIDTH_SHARE := 0.6
## Ground distance between the slats, and how fast they run.
const SLAT_SPACING := 40.0
const SLAT_SPEED := 40.0
const BOWL_TEXTURE: Texture2D = preload("res://assets/sprites/props/fish_bowl.svg")
const BOWL_WIDTH := 78.0
const FISH_LENGTH := 46.0
## How fast fish slide to their place, in slots per second.
const SLIDE_SPEED := 4.0
const FRAME_COLOR := Color(0.55, 0.58, 0.62)
const BELT_COLOR := Color(0.2, 0.22, 0.26)
const SLAT_COLOR := Color(0.32, 0.35, 0.4)
const PRICE_COLOR := Color(1.0, 0.86, 0.3)
const MORE_COLOR := Color(1.0, 1.0, 1.0)

var tank: TankState
## Returns the FishArt for a species id.
var art_for: Callable

## Half the belt's ground size, east-west by north-south.
var _half := Vector2.ZERO
## Where each shown fish is drawn, in slots counted from the booths' end.
var _places: Dictionary[TankFish, float] = {}
var _time := 0.0


## `area` is the ground the belt covers: whole cells, running north from the tank's end.
func setup(tank_state: TankState, area: Rect2, art_lookup: Callable) -> void:
	tank = tank_state
	art_for = art_lookup
	position = Iso.to_screen(area.get_center())
	_half = Vector2(area.size.x * WIDTH_SHARE, area.size.y) * 0.5


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
	for i in count:
		# New fish come in at the tank end; the others slide towards their place.
		var place: float = _places.get(shown[i], float(slots()))
		places[shown[i]] = move_toward(place, float(i), SLIDE_SPEED * delta)
	_places = places
	queue_redraw()


## Screen position on the belt's top, `along` ground units north of its tank end.
func _on_top(along: float) -> Vector2:
	return Iso.to_screen(Vector2(0.0, _half.y - along)) + Vector2(0.0, -LIFT)


func _draw() -> void:
	var lift := Vector2(0.0, -LIFT)
	IsoDraw.box_back(self, Vector2.ZERO, _half, LIFT, FRAME_COLOR.darkened(0.3))
	IsoDraw.box_front(self, Vector2.ZERO, _half, LIFT, FRAME_COLOR.darkened(0.2), FRAME_COLOR, BELT_COLOR)
	# Slats across the belt, running north.
	var inner := _half.x - 8.0
	var offset := fmod(_time * SLAT_SPEED, SLAT_SPACING)
	var along := offset + 6.0
	while along < _half.y * 2.0 - 6.0:
		var y := _half.y - along
		draw_line(Iso.to_screen(Vector2(-inner, y)) + lift, Iso.to_screen(Vector2(inner, y)) + lift, SLAT_COLOR, 4.0, true)
		along += SLAT_SPACING

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
