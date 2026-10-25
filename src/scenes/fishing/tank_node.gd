class_name TankNode
extends Node2D
## The tank on the beach, drawn in code as an isometric glass box on a stand, with its fish
## swimming inside. Bigger levels are bigger boxes. The node sits at the centre of the base.

## Ground half-size and screen height of the glass box, per tank level.
const HALF_SIZES: Array[Vector2] = [
	Vector2(62.0, 42.0), Vector2(78.0, 52.0), Vector2(95.0, 62.0), Vector2(112.0, 72.0), Vector2(130.0, 82.0),
	Vector2(150.0, 94.0), Vector2(172.0, 106.0),
]
const HEIGHTS: Array[float] = [70.0, 82.0, 96.0, 110.0, 124.0, 140.0, 158.0]
const STAND_HEIGHT := 16.0
## Fish drawn at most; a full tank shows its count in the label.
const MAX_DRAWN_FISH := 14

const WOOD := Color(0.66, 0.44, 0.24)
const WOOD_DARK := Color(0.5, 0.32, 0.17)
const WATER_BACK := Color(0.22, 0.55, 0.75, 0.95)
const GLASS_RIGHT := Color(0.45, 0.8, 0.95, 0.35)
const GLASS_FRONT := Color(0.38, 0.72, 0.9, 0.35)
const WATER_TOP := Color(0.65, 0.92, 1.0, 0.8)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)
const LABEL_COLOR := Color(1.0, 1.0, 1.0)

var tank: TankState
## Returns the FishArt for a species id.
var art_for: Callable

var _time := 0.0
## Used litres, recounted only when the number of fish changes.
var _used := 0.0
var _counted_fish := -1


func setup(tank_state: TankState, ground_position: Vector2, art_lookup: Callable) -> void:
	tank = tank_state
	art_for = art_lookup
	position = Iso.to_screen(ground_position)


## Where stored fish land: the water surface, relative to the node's parent.
func drop_point() -> Vector2:
	return position + Vector2(0.0, -STAND_HEIGHT - _height())


## Quick wobble when something happens to the tank.
func bounce() -> void:
	scale = Vector2(1.08, 0.92)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _half() -> Vector2:
	return HALF_SIZES[mini(tank.level, HALF_SIZES.size()) - 1]


func _height() -> float:
	return HEIGHTS[mini(tank.level, HEIGHTS.size()) - 1]


func _draw() -> void:
	var half := _half()
	var height := _height()
	draw_colored_polygon(Iso.ellipse(Vector2(8.0, 6.0), (half.x + half.y) * 0.9, 20), SHADOW)
	IsoDraw.box_front(self, Vector2.ZERO, half + Vector2(6.0, 6.0), STAND_HEIGHT, WOOD_DARK, WOOD_DARK, WOOD)
	var base := Vector2(0.0, -STAND_HEIGHT)
	IsoDraw.box_back(self, base, half, height, WATER_BACK)
	_draw_fish(base, half, height)
	IsoDraw.box_front(self, base, half, height, GLASS_RIGHT, GLASS_FRONT, WATER_TOP)
	# A glint on the front glass.
	var front := base + Iso.to_screen(Vector2(half.x, half.y))
	draw_line(front + Vector2(-20.0, -12.0), front + Vector2(-20.0, -height + 12.0), Color(1.0, 1.0, 1.0, 0.45), 4.0)

	if tank.fish.size() != _counted_fish:
		_counted_fish = tank.fish.size()
		_used = Aquarium.used_space(tank)
	var used := _used
	var text := "%s / %s L" % [NumberFormat.compact(used), NumberFormat.compact(Aquarium.capacity(tank))]
	var full := used >= Aquarium.capacity(tank) - 0.01
	IsoDraw.label(self, Vector2(0.0, -STAND_HEIGHT - height - (half.x + half.y) * 0.36 - 18.0), text, 24,
			Color(1.0, 0.6, 0.4) if full else LABEL_COLOR)


## The fish swim back and forth at different depths. Grown fish are drawn bigger.
func _draw_fish(base: Vector2, half: Vector2, height: float) -> void:
	var swim_width := (half.x + half.y) * 0.55
	for i in mini(tank.fish.size(), MAX_DRAWN_FISH):
		var fish := tank.fish[i]
		var art: FishArt = art_for.call(fish.species_id)
		var speed := 0.5 + fmod(i * 0.37, 0.5)
		var phase := _time * speed + i * 1.7
		var x := sin(phase) * swim_width
		var direction := 1.0 if cos(phase) > 0.0 else -1.0
		var depth := 0.25 + fmod(i * 0.29, 0.55)
		var at := base + Vector2(x, -height * depth)
		var length := clampf(CatchRules.body_length(art.species) * 0.55, 30.0, 80.0) * (0.65 + 0.35 * fish.growth)
		var view := Transform2D(Vector2(direction, 0.0), Vector2(0.0, 1.0), at)
		art.draw(self, view, length, 0.8 + 0.2 * sin(_time * 8.0 + i))
