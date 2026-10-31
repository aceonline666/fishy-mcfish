class_name SalesPipe
extends Node2D
## The pipe from the tank to the shop: the grown fish lie in it in the order they will be sold,
## the next one at the shop end, each with its price above it. Fish slide along when one is sold
## and come in at the tank end when they grow up, each in a fish glass. PLACEHOLDER sprites
## (assets/sprites/props/pipe_segment.svg, fish_bowl.svg) until the final art exists. The node
## sits at the middle of the pipe, on the ground.

## Ground distance between two fish in the pipe.
const SLOT := 120.0
## Screen height of the pipe above the ground.
const LIFT := 46.0
const PIPE_WIDTH := 30.0
const PIPE_TEXTURE: Texture2D = preload("res://assets/sprites/props/pipe_segment.svg")
const BOWL_TEXTURE: Texture2D = preload("res://assets/sprites/props/fish_bowl.svg")
const BOWL_WIDTH := 78.0
const FISH_LENGTH := 46.0
## How fast fish slide to their place, in slots per second.
const SLIDE_SPEED := 4.0
const PIPE_EDGE := Color(0.07, 0.09, 0.15)
const PRICE_COLOR := Color(1.0, 0.86, 0.3)
const MORE_COLOR := Color(1.0, 1.0, 1.0)

var tank: TankState
## Returns the FishArt for a species id.
var art_for: Callable

## Ground ends of the pipe, relative to the node: the tank end and the shop end.
var _from := Vector2.ZERO
var _to := Vector2.ZERO
## Where each shown fish is drawn, in slots counted from the shop end.
var _places: Dictionary[TankFish, float] = {}
var _time := 0.0


func setup(tank_state: TankState, tank_end: Vector2, shop_end: Vector2, art_lookup: Callable) -> void:
	tank = tank_state
	art_for = art_lookup
	var middle := (tank_end + shop_end) * 0.5
	position = Iso.to_screen(middle)
	_from = tank_end - middle
	_to = shop_end - middle


## How many fish fit into the pipe.
func slots() -> int:
	return maxi(int(_from.distance_to(_to) / SLOT), 1)


## The grown fish in the order they will be sold (Selling.best_fish: the most valuable first).
func queue() -> Array[TankFish]:
	var grown: Array[TankFish] = []
	for fish in tank.fish:
		if fish.growth >= 1.0:
			grown.append(fish)
	grown.sort_custom(func(a: TankFish, b: TankFish) -> bool: return _price(a) > _price(b))
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


func _draw() -> void:
	var lift := Vector2(0.0, -LIFT)
	var from := Iso.to_screen(_from)
	var to := Iso.to_screen(_to)
	# Legs down to the ground at both ends and in the middle, then the pipe pieces along the line.
	for t: float in [0.0, 0.5, 1.0]:
		var foot := from.lerp(to, t)
		draw_line(foot, foot + lift, PIPE_EDGE, 6.0, true)
	var length := from.distance_to(to)
	var piece := PIPE_TEXTURE.get_size() * (PIPE_WIDTH / PIPE_TEXTURE.get_height())
	draw_set_transform(from + lift, (to - from).angle())
	var x := 0.0
	while x < length:
		var width := minf(piece.x, length - x)
		draw_texture_rect_region(PIPE_TEXTURE, Rect2(x, -piece.y * 0.5, width, piece.y),
				Rect2(Vector2.ZERO, Vector2(PIPE_TEXTURE.get_width() * width / piece.x, PIPE_TEXTURE.get_height())))
		x += piece.x
	draw_set_transform(Vector2.ZERO)

	# Each grown fish in a glass on the pipe, the next to be sold at the shop end.
	var direction := 1.0 if to.x >= from.x else -1.0
	var bowl := BOWL_TEXTURE.get_size() * (BOWL_WIDTH / BOWL_TEXTURE.get_width())
	var shown := queue()
	for i in range(mini(shown.size(), slots()) - 1, -1, -1):
		var fish := shown[i]
		if not _places.has(fish):
			continue
		var at := to.lerp(from, _places[fish] / float(slots())) + lift
		draw_texture_rect(BOWL_TEXTURE, Rect2(at - Vector2(bowl.x * 0.5, bowl.y - 6.0), bowl), false)
		var art: FishArt = art_for.call(fish.species_id)
		var swim := Vector2(sin(_time * 1.5 + i) * bowl.x * 0.12, -bowl.y * 0.42)
		var view := Transform2D(Vector2(direction if cos(_time * 1.5 + i) > 0.0 else -direction, 0.0), Vector2(0.0, 1.0), at + swim)
		art.draw(self, view, FISH_LENGTH, _time * 6.0 + i, 0.5)
		IsoDraw.label(self, at + Vector2(0.0, -bowl.y - 16.0), NumberFormat.compact(_price(fish)), 28, PRICE_COLOR)
	if shown.size() > slots():
		IsoDraw.label(self, from + lift + Vector2(0.0, -bowl.y - 16.0), "+%d" % (shown.size() - slots()), 28, MORE_COLOR)
