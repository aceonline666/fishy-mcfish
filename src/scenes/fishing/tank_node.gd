class_name TankNode
extends Node2D
## The tank on the beach: a painted glass tank that gets bigger with its level
## (assets/sprites/props), with some of its fish swimming inside. The node sits at the centre
## of the base.

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/tank_1.png"), preload("res://assets/sprites/props/tank_2.png"),
	preload("res://assets/sprites/props/tank_3.png"), preload("res://assets/sprites/props/tank_4.png"),
	preload("res://assets/sprites/props/tank_5.png"), preload("res://assets/sprites/props/tank_6.png"),
	preload("res://assets/sprites/props/tank_7.png"),
]
## Screen width of the tank per level.
const WIDTHS: Array[float] = [220.0, 250.0, 290.0, 320.0, 360.0, 410.0, 600.0]
## How far below the node the bottom of the sprite reaches, as a share of its height.
const BASE_DROP := 0.12
## The water inside the glass, as shares of the sprite: x and width, top and bottom of the
## band the fish swim in.
const WATER_X := 0.2
const WATER_WIDTH := 0.55
const WATER_TOP := 0.32
const WATER_BOTTOM := 0.62
## Fish drawn at most; the label shows the space used.
const MAX_DRAWN_FISH := 14
## Fish seen through the glass.
const GLASS_TINT := Color(0.85, 0.95, 1.0, 0.92)
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
	var rect := _sprite_rect()
	return position + Vector2(0.0, rect.position.y + rect.size.y * WATER_TOP)


## Quick wobble when something happens to the tank.
func bounce() -> void:
	scale = Vector2(1.06, 0.94)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _texture() -> Texture2D:
	return TEXTURES[clampi(tank.level, 1, TEXTURES.size()) - 1]


## Where the sprite is drawn, relative to the node.
func _sprite_rect() -> Rect2:
	var texture := _texture()
	var width := WIDTHS[clampi(tank.level, 1, WIDTHS.size()) - 1]
	var size := texture.get_size() * (width / texture.get_width())
	return Rect2(Vector2(-size.x * 0.5, -size.y * (1.0 - BASE_DROP)), size)


func _draw() -> void:
	var rect := _sprite_rect()
	draw_colored_polygon(Iso.ellipse(Vector2(10.0, 6.0), rect.size.x * 0.42, 20), SHADOW)
	draw_texture_rect(_texture(), rect, false)
	_draw_fish(rect)

	if tank.fish.size() != _counted_fish:
		_counted_fish = tank.fish.size()
		_used = Aquarium.used_space(tank)
	var text := "%s / %s L" % [NumberFormat.compact(_used), NumberFormat.compact(Aquarium.capacity(tank))]
	var full := _used >= Aquarium.capacity(tank) - 0.01
	IsoDraw.label(self, Vector2(0.0, rect.position.y - 22.0), text, 26, Color(1.0, 0.6, 0.4) if full else LABEL_COLOR)


## The fish swim back and forth at different depths. Grown fish are drawn bigger.
func _draw_fish(rect: Rect2) -> void:
	var left := rect.position.x + rect.size.x * WATER_X
	var swim_width := rect.size.x * WATER_WIDTH
	var top := rect.position.y + rect.size.y * WATER_TOP
	var depth_range := rect.size.y * (WATER_BOTTOM - WATER_TOP)
	var max_length := clampf(rect.size.x * 0.22, 36.0, 110.0)
	for i in mini(tank.fish.size(), MAX_DRAWN_FISH):
		var fish := tank.fish[i]
		var art: FishArt = art_for.call(fish.species_id)
		var speed := 0.4 + fmod(i * 0.37, 0.5)
		var phase := _time * speed + i * 1.7
		var x := left + (0.5 + 0.5 * sin(phase)) * swim_width
		var direction := 1.0 if cos(phase) > 0.0 else -1.0
		var at := Vector2(x, top + depth_range * fmod(i * 0.29 + 0.1, 1.0))
		var length := clampf(CatchRules.body_length(art.species) * 0.5, 26.0, max_length) * (0.65 + 0.35 * fish.growth)
		var view := Transform2D(Vector2(direction, 0.0), Vector2(0.0, 1.0), at)
		art.draw(self, view, length, _time * 8.0 + i, 0.8, GLASS_TINT)
