class_name TankNode
extends Node2D
## The tank on the beach: a painted glass tank that gets bigger with its level
## (assets/sprites/props), with some of its fish swimming inside. Its water rises with the space
## the fish take; once the tank is full it runs over the rim into a puddle and fish jump out.
## A bar above it fills while the next young fish grows up.
## The node sits at the centre of the base.

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/tank_1.png"), preload("res://assets/sprites/props/tank_2.png"),
	preload("res://assets/sprites/props/tank_3.png"), preload("res://assets/sprites/props/tank_4.png"),
	preload("res://assets/sprites/props/tank_5.png"), preload("res://assets/sprites/props/tank_6.png"),
	preload("res://assets/sprites/props/tank_7.png"),
]
## The water layers. PLACEHOLDER SVGs until the final tank art: the air layer only hides the
## water painted into the tank sprites above the water level.
const WATER_TEXTURE: Texture2D = preload("res://assets/sprites/props/tank_water.svg")
const SURFACE_TEXTURE: Texture2D = preload("res://assets/sprites/props/tank_water_surface.svg")
const AIR_TEXTURE: Texture2D = preload("res://assets/sprites/props/tank_air.svg")
const OVERFLOW_TEXTURE: Texture2D = preload("res://assets/sprites/props/tank_overflow.svg")
const PUDDLE_TEXTURE: Texture2D = preload("res://assets/sprites/props/tank_puddle.svg")
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
## How fast the drawn water level follows the fill, in share of the tank per second.
const LEVEL_SPEED := 0.6
## How far the water of a full tank bulges above the rim, and how high the wavy surface is.
const BULGE := 6.0
const SURFACE_HEIGHT := 16.0
const OVERFLOW_WIDTH := 30.0
const WATER_COLOR := Color(0.55, 0.82, 1.0)
## Fish jumping out of an overfilled tank, and how long one jump cycle takes (jump, then splash,
## then a pause), and the drops falling off the overflowing rim.
const JUMPERS := 3
const JUMP_PERIOD := 2.6
const JUMP_AIR_SHARE := 0.32
const SPILL_DROPS := 8
const GROW_BAR_SIZE := Vector2(170.0, 14.0)
const GROW_BAR_BACK := Color(0.05, 0.1, 0.2, 0.7)
const GROW_BAR_FILL := Color(0.45, 0.9, 0.4)
const GROWN_COLOR := Color(1.0, 0.85, 0.3)

var tank: TankState
## Returns the FishArt for a species id.
var art_for: Callable

## Set while drones sit on the ground because there is no room left for their catch.
var drones_resting := false
## The least space any fish of this water needs: with less free space the tank is full.
var smallest_fish_l := 1.0

var _time := 0.0
## Used litres, recounted only when the number of fish changes.
var _used := 0.0
var _counted_fish := -1
## The water level drawn, 0 (empty) to 1 (at the rim); it follows the fill smoothly.
var _level := -1.0


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
	var target := 1.0 if is_full() else Aquarium.fill_share(tank)
	_level = target if _level < 0.0 else move_toward(_level, target, LEVEL_SPEED * delta)
	queue_redraw()


## True while nothing fits in any more (or the drones say so): the water runs over.
func is_full() -> bool:
	_recount()
	return drones_resting or Aquarium.capacity(tank) - _used < smallest_fish_l


## Used litres, recounted only when the number of fish changes.
func _recount() -> void:
	if tank.fish.size() != _counted_fish:
		_counted_fish = tank.fish.size()
		_used = Aquarium.used_space(tank)


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
	var full := is_full()
	var water := _water_rect(rect)
	draw_colored_polygon(Iso.ellipse(Vector2(10.0, 6.0), rect.size.x * 0.42, 20), SHADOW)
	if full:
		_draw_puddle(rect)
	draw_texture_rect(_texture(), rect, false)
	_draw_water(rect, water, full)
	_draw_fish(water)
	if full:
		_draw_overflow(water)
		_draw_jumpers(rect, water)

	var text := "%s / %s L" % [NumberFormat.compact(_used), NumberFormat.compact(Aquarium.capacity(tank))]
	IsoDraw.label(self, Vector2(0.0, rect.position.y - 22.0), text, 26, FULL_COLOR if full else LABEL_COLOR)
	var top := _draw_growth(rect.position.y - 52.0)
	if drones_resting:
		IsoDraw.label(self, Vector2(0.0, top), tr("Full: drones resting"), 26, FULL_COLOR)


## Above the tank: how many fish are grown, and a bar filling up while the next young fish grows,
## with the time it still needs. Returns the height above it that is still free.
func _draw_growth(y: float) -> float:
	var grown := 0
	for fish in tank.fish:
		if fish.growth >= 1.0:
			grown += 1
	if grown > 0:
		IsoDraw.label(self, Vector2(0.0, y), "★ " + tr("%d grown") % grown, 26, GROWN_COLOR)
		y -= 36.0
	var next := Aquarium.next_to_grow(tank)
	if next == null:
		return y
	var bar := Rect2(Vector2(-GROW_BAR_SIZE.x * 0.5, y - GROW_BAR_SIZE.y * 0.5), GROW_BAR_SIZE)
	draw_rect(bar.grow(3.0), GROW_BAR_BACK)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * next.growth, bar.size.y)), GROW_BAR_FILL)
	var seconds := ceili(Aquarium.seconds_to_grow(tank, next))
	IsoDraw.label(self, Vector2(0.0, y - 28.0), tr("Grown in %s") % ("%d:%02d" % [seconds / 60, seconds % 60]), 24, LABEL_COLOR)
	return y - 64.0


## The water inside the glass, from the bottom up to the drawn level; a full tank bulges over
## the rim.
func _water_rect(rect: Rect2) -> Rect2:
	var top := rect.position.y + rect.size.y * WATER_TOP
	var bottom := rect.position.y + rect.size.y * WATER_BOTTOM
	var level := clampf(_level, 0.0, 1.0)
	var surface := lerpf(bottom, top, level) - BULGE * clampf((level - 0.98) / 0.02, 0.0, 1.0)
	return Rect2(rect.position.x + rect.size.x * WATER_X, surface, rect.size.x * WATER_WIDTH, bottom - surface)


## Empty glass above the water, the water body and its wavy surface.
func _draw_water(rect: Rect2, water: Rect2, full: bool) -> void:
	var top := rect.position.y + rect.size.y * WATER_TOP
	if water.position.y > top:
		draw_texture_rect(AIR_TEXTURE, Rect2(water.position.x, top, water.size.x, water.position.y - top), false)
	if water.size.y <= 0.5:
		return
	draw_texture_rect(WATER_TEXTURE, water, false)
	var wobble := sin(_time * (5.0 if full else 2.0)) * (3.0 if full else 1.5)
	draw_texture_rect(SURFACE_TEXTURE,
			Rect2(water.position.x, water.position.y - SURFACE_HEIGHT * 0.5 + wobble, water.size.x, SURFACE_HEIGHT), false)


## The fish swim back and forth at different depths of the water. Grown fish are drawn bigger.
func _draw_fish(water: Rect2) -> void:
	if water.size.y <= 0.5:
		return
	var max_length := clampf(water.size.x * 0.4, 36.0, 110.0)
	for i in mini(tank.fish.size(), MAX_DRAWN_FISH):
		var fish := tank.fish[i]
		var art: FishArt = art_for.call(fish.species_id)
		var speed := 0.4 + fmod(i * 0.37, 0.5)
		var phase := _time * speed + i * 1.7
		var x := water.position.x + (0.5 + 0.5 * sin(phase)) * water.size.x
		var direction := 1.0 if cos(phase) > 0.0 else -1.0
		var at := Vector2(x, water.position.y + water.size.y * (0.15 + 0.75 * fmod(i * 0.29 + 0.1, 1.0)))
		var length := clampf(CatchRules.body_length(art.species) * 0.5, 26.0, max_length) * (0.65 + 0.35 * fish.growth)
		var view := Transform2D(Vector2(direction, 0.0), Vector2(0.0, 1.0), at)
		art.draw(self, view, length, _time * 8.0 + i, 0.8, GLASS_TINT)


## Water the tank spilled, spreading on the ground around it.
func _draw_puddle(rect: Rect2) -> void:
	var size := Vector2(rect.size.x, rect.size.x * 0.5) * (1.05 + 0.04 * sin(_time * 1.7))
	draw_texture_rect(PUDDLE_TEXTURE, Rect2(Vector2(8.0, 10.0) - size * 0.5, size), false)


## Water running over both sides of the rim, down the glass, with drops falling off.
func _draw_overflow(water: Rect2) -> void:
	var floor_y := 8.0
	var spill_x: Array[float] = [water.position.x, water.end.x]
	for k in spill_x.size():
		var flow := 0.75 + 0.25 * sin(_time * 6.0 + k * 2.0)
		draw_texture_rect(OVERFLOW_TEXTURE, Rect2(spill_x[k] - OVERFLOW_WIDTH * 0.5, water.position.y,
				OVERFLOW_WIDTH, floor_y - water.position.y), false, Color(1.0, 1.0, 1.0, flow))
	for i in SPILL_DROPS:
		var fall := fmod(_time * (0.8 + 0.11 * i) + i * 0.37, 1.0)
		var x := spill_x[i % 2] + (i / 2 - 1.5) * 9.0
		var y := lerpf(water.position.y, floor_y, fall * fall)
		draw_circle(Vector2(x, y), 5.0, Color(1.0, 1.0, 1.0, 0.85))


## A few fish leap out of the water in an arc and splash back in.
func _draw_jumpers(rect: Rect2, water: Rect2) -> void:
	if tank.fish.is_empty():
		return
	var surface := water.position.y
	var left := water.position.x
	var swim_width := water.size.x
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
