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
const FULL_COLOR := Color(1.0, 0.6, 0.4)
## From this share of its space on, the tank counts as overfilled: water spills and fish jump.
const OVERFILLED_SHARE := 0.95
const WATER_COLOR := Color(0.55, 0.82, 1.0)
## Fish jumping out of an overfilled tank, and how long one jump cycle takes (jump, then splash,
## then a pause).
const JUMPERS := 3
const JUMP_PERIOD := 2.6
const JUMP_AIR_SHARE := 0.32
const SPILL_DROPS := 8

var tank: TankState
## Returns the FishArt for a species id.
var art_for: Callable

## Set while drones sit on the ground because there is no room left for their catch.
var drones_resting := false

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
	if tank.fish.size() != _counted_fish:
		_counted_fish = tank.fish.size()
		_used = Aquarium.used_space(tank)
	var capacity := Aquarium.capacity(tank)
	var overfilled := drones_resting or _used >= capacity * OVERFILLED_SHARE
	draw_colored_polygon(Iso.ellipse(Vector2(10.0, 6.0), rect.size.x * 0.42, 20), SHADOW)
	if overfilled:
		_draw_puddle(rect)
	draw_texture_rect(_texture(), rect, false)
	_draw_fish(rect)
	if overfilled:
		_draw_spill(rect)
		_draw_jumpers(rect)

	var text := "%s / %s L" % [NumberFormat.compact(_used), NumberFormat.compact(capacity)]
	IsoDraw.label(self, Vector2(0.0, rect.position.y - 22.0), text, 26, FULL_COLOR if overfilled else LABEL_COLOR)
	if drones_resting:
		IsoDraw.label(self, Vector2(0.0, rect.position.y - 58.0), tr("Full: drones resting"), 26, FULL_COLOR)


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


## Water the tank spilled, spreading on the ground around it.
func _draw_puddle(rect: Rect2) -> void:
	var radius := rect.size.x * (0.5 + 0.03 * sin(_time * 1.7))
	draw_colored_polygon(Iso.ellipse(Vector2(8.0, 10.0), radius, 28), Color(WATER_COLOR, 0.6))
	draw_polyline(Iso.ellipse(Vector2(8.0, 10.0), radius * 0.8, 28), Color(1.0, 1.0, 1.0, 0.25), 2.0)


## Water running over both sides of the rim and dripping down the glass.
func _draw_spill(rect: Rect2) -> void:
	var surface := rect.position.y + rect.size.y * WATER_TOP
	var floor_y := 8.0
	var spill_x: Array[float] = [rect.position.x + rect.size.x * WATER_X, rect.position.x + rect.size.x * (WATER_X + WATER_WIDTH)]
	for x in spill_x:
		var flow := 0.4 + 0.15 * sin(_time * 5.0 + x)
		draw_line(Vector2(x, surface), Vector2(x, floor_y), Color(WATER_COLOR, flow + 0.2), 8.0, true)
	for i in SPILL_DROPS:
		var fall := fmod(_time * (0.8 + 0.11 * i) + i * 0.37, 1.0)
		var x := spill_x[i % 2] + (i / 2 - 1.5) * 7.0
		var y := lerpf(surface, floor_y, fall * fall)
		draw_line(Vector2(x, y - 9.0 * fall), Vector2(x, y), Color(WATER_COLOR, 0.95), 5.0, true)
		draw_circle(Vector2(x, y), 5.0, Color(1.0, 1.0, 1.0, 0.85))


## A few fish leap out of the water in an arc and splash back in.
func _draw_jumpers(rect: Rect2) -> void:
	if tank.fish.is_empty():
		return
	var surface := rect.position.y + rect.size.y * WATER_TOP
	var left := rect.position.x + rect.size.x * WATER_X
	var swim_width := rect.size.x * WATER_WIDTH
	var height := rect.size.y * 0.55
	var reach := swim_width * 0.6
	var max_length := clampf(rect.size.x * 0.3, 48.0, 150.0)
	for j in mini(JUMPERS, tank.fish.size()):
		var clock := _time + j * 0.9
		var cycle := int(clock / JUMP_PERIOD)
		var t := fmod(clock, JUMP_PERIOD) / JUMP_PERIOD
		var direction := 1.0 if (cycle + j) % 2 == 0 else -1.0
		var start_x := left + swim_width * (0.5 + 0.5 * direction * -0.5 + 0.12 * (j - 1))
		var end_x := start_x + direction * reach
		if t < JUMP_AIR_SHARE:
			var u := t / JUMP_AIR_SHARE
			var at := Vector2(lerpf(start_x, end_x, u), surface - 4.0 * height * u * (1.0 - u))
			var velocity := Vector2(direction * reach, -4.0 * height * (1.0 - 2.0 * u))
			var fish := tank.fish[(cycle * 5 + j * 3) % tank.fish.size()]
			var art: FishArt = art_for.call(fish.species_id)
			var length := clampf(CatchRules.body_length(art.species) * 1.0, 56.0, max_length) * (0.65 + 0.35 * fish.growth)
			var tilt := velocity.angle() if direction > 0.0 else velocity.angle() - PI
			var view := Transform2D(tilt, at) * Transform2D(Vector2(direction, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
			art.draw(self, view, length, _time * 14.0 + j, 1.0)
			_draw_ring(Vector2(start_x, surface), u * 0.5)
		elif t < JUMP_AIR_SHARE + 0.18:
			_draw_ring(Vector2(end_x, surface), (t - JUMP_AIR_SHARE) / 0.18)


## A splash ring on the water surface; `progress` runs 0 to 1 as it grows and fades.
func _draw_ring(center: Vector2, progress: float) -> void:
	var radius := lerpf(10.0, 60.0, progress)
	draw_polyline(Iso.ellipse(center, radius, 16), Color(1.0, 1.0, 1.0, 0.9 * (1.0 - progress)), 4.0, true)
	for k in 3:
		var angle := -PI * (0.2 + 0.3 * k)
		var spray := center + Vector2(cos(angle), sin(angle)) * radius * 0.9 + Vector2(0.0, 14.0 * progress * progress)
		draw_circle(spray, 5.0, Color(WATER_COLOR, 1.0 - progress))
