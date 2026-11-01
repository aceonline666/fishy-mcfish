class_name TankNode
extends Node2D
## The tank on the beach: a painted glass tank that gets bigger with its level
## (assets/sprites/props), with some of its fish swimming inside. Its water rises with the space
## the fish take; once the tank is full it runs over the rim into a puddle and fish jump out.
## A bar above it fills while the next young fish grows up.
## The tank covers cells of the layout grid (Grid), as many as its level's footprint in
## data/tanks.csv; its sprite fits them, standing in their south-east corner. The node sits at
## the centre of the footprint.
## The tanks are painted empty, with half-transparent glass (art_source/tank_sprite_prompt.md,
## imported by tools/import_tank_art.py): the water is drawn as a box inside the glass, the fish
## in it, and the front corner posts again on top.

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/tank_1.png"), preload("res://assets/sprites/props/tank_2.png"),
	preload("res://assets/sprites/props/tank_3.png"), preload("res://assets/sprites/props/tank_4.png"),
	preload("res://assets/sprites/props/tank_5.png"), preload("res://assets/sprites/props/tank_6.png"),
	preload("res://assets/sprites/props/tank_7.png"),
]
## The water running over the rim and the puddle it makes: PLACEHOLDER SVGs.
const OVERFLOW_TEXTURE: Texture2D = preload("res://assets/sprites/props/tank_overflow.svg")
const PUDDLE_TEXTURE: Texture2D = preload("res://assets/sprites/props/tank_puddle.svg")
## The corners of each sprite's own footprint (pixels): west, south and east on screen. The
## sprites are painted as they stand, with their long side running north-south from level 4 on.
const BASES: Array[Array] = [
	[Vector2(4.0, 460.0), Vector2(232.0, 570.0), Vector2(440.0, 465.0)],
	[Vector2(2.0, 416.0), Vector2(395.0, 612.0), Vector2(540.0, 540.0)],
	[Vector2(4.0, 503.0), Vector2(232.0, 617.0), Vector2(450.0, 508.0)],
	[Vector2(3.0, 386.0), Vector2(210.0, 493.0), Vector2(540.0, 326.0)],
	[Vector2(2.0, 332.0), Vector2(308.0, 490.0), Vector2(612.0, 334.0)],
	[Vector2(4.0, 370.0), Vector2(259.0, 506.0), Vector2(606.0, 333.0)],
	[Vector2(4.0, 458.0), Vector2(197.0, 551.0), Vector2(684.0, 314.0)],
]
## The glass of each sprite, in sprite pixels: the west, south and east corners of the glass floor
## (at the corner posts), the glass height, half the width of a corner post and how far its top cap
## reaches above the glass.
const GLASS: Array[Dictionary] = [
	{"left": Vector2(30.0, 344.0), "front": Vector2(231.0, 445.0), "right": Vector2(415.0, 353.0),
			"height": 245.0, "post": 16.0, "cap": 24.0},
	{"left": Vector2(25.0, 252.0), "front": Vector2(400.0, 440.0), "right": Vector2(515.0, 382.0),
			"height": 205.0, "post": 14.0, "cap": 21.0},
	{"left": Vector2(30.0, 356.0), "front": Vector2(234.0, 458.0), "right": Vector2(422.0, 364.0),
			"height": 245.0, "post": 20.0, "cap": 30.0},
	{"left": Vector2(20.0, 317.0), "front": Vector2(201.0, 408.0), "right": Vector2(522.0, 247.0),
			"height": 152.0, "post": 12.0, "cap": 6.0},
	{"left": Vector2(20.0, 288.0), "front": Vector2(310.0, 433.0), "right": Vector2(595.0, 290.0),
			"height": 140.0, "post": 15.0, "cap": 6.0},
	{"left": Vector2(14.0, 321.0), "front": Vector2(245.0, 437.0), "right": Vector2(594.0, 262.0),
			"height": 143.0, "post": 10.0, "cap": 6.0},
	{"left": Vector2(22.0, 395.0), "front": Vector2(200.0, 481.0), "right": Vector2(662.0, 288.0),
			"height": 132.0, "post": 14.0, "cap": 8.0},
]
## The water drawn in the glass: its sides and its surface.
const WATER_SIDE_COLOR := Color(0.25, 0.62, 0.92, 0.42)
const WATER_SURFACE_COLOR := Color(0.6, 0.86, 1.0, 0.55)
## Fish drawn at most; the label shows the space used.
const MAX_DRAWN_FISH := 14
## Fish seen through the glass.
const GLASS_TINT := Color(0.85, 0.95, 1.0, 0.92)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)
const LABEL_COLOR := Color(1.0, 1.0, 1.0)
const FULL_COLOR := Color(1.0, 0.6, 0.4)
## How fast the drawn water level follows the fill, in share of the tank per second.
const LEVEL_SPEED := 0.6
## How far the water of a full tank bulges above the rim.
const BULGE := 6.0
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
## The cells the tank covers.
var footprint := Vector2i.ONE
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


## `area` is the ground the tank covers: whole cells of the layout grid.
func setup(tank_state: TankState, area: Rect2, art_lookup: Callable) -> void:
	tank = tank_state
	art_for = art_lookup
	footprint = Vector2i((area.size / Grid.UNIT).round())
	position = Iso.to_screen(area.get_center())


## Where stored fish land: the water surface, relative to the node's parent.
func drop_point() -> Vector2:
	var box := _glass_box(_sprite_rect())
	return position + (box[0] + box[2]) * 0.5 - Vector2(0.0, box[4])


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


func _glass() -> Dictionary:
	return GLASS[clampi(tank.level, 1, GLASS.size()) - 1]


## Where the sprite is drawn, relative to the node.
func sprite_bounds() -> Rect2:
	return _sprite_rect()


func _sprite_rect() -> Rect2:
	var base: Array = BASES[clampi(tank.level, 1, BASES.size()) - 1]
	var scale_factor := Grid.fit_scale(base[0], base[1], base[2], footprint)
	var south_east := Iso.to_screen(Vector2(footprint) * Grid.UNIT * 0.5)
	return Rect2(south_east - base[1] * scale_factor, _texture().get_size() * scale_factor)


## The glass floor's corners (west, south, east, north on screen) relative to the node, and the
## glass height, for a sprite drawn in `rect`.
func _glass_box(rect: Rect2) -> Array:
	var glass := _glass()
	var s := rect.size.x / _texture().get_width()
	var left: Vector2 = rect.position + glass.left * s
	var front: Vector2 = rect.position + glass.front * s
	var right: Vector2 = rect.position + glass.right * s
	return [left, front, right, left + right - front, glass.height * s]


func _draw() -> void:
	var rect := _sprite_rect()
	var full := is_full()
	var water := _water_rect(rect)
	var middle := rect.get_center().x
	draw_colored_polygon(Iso.ellipse(Vector2(middle + 10.0, 6.0), rect.size.x * 0.42, 20), SHADOW)
	if full:
		_draw_puddle(rect)
	draw_texture_rect(_texture(), rect, false)
	_draw_water(_glass_box(rect), water.size.y, full)
	_draw_fish(water)
	_draw_front_posts(rect)
	if full:
		_draw_overflow(water)
		_draw_jumpers(rect, water)

	var text := "%s / %s L" % [NumberFormat.compact(_used), NumberFormat.compact(Aquarium.capacity(tank))]
	IsoDraw.label(self, Vector2(middle, rect.position.y - 22.0), text, 26, FULL_COLOR if full else LABEL_COLOR)
	var top := _draw_growth(Vector2(middle, rect.position.y - 52.0))
	if drones_resting:
		IsoDraw.label(self, Vector2(middle, top), tr("Full: drones resting"), 26, FULL_COLOR)


## Above the tank: how many fish are grown, and a bar filling up while the next young fish grows,
## with the time it still needs, from `at` up. Returns the height above it that is still free.
func _draw_growth(at: Vector2) -> float:
	var y := at.y
	var grown := 0
	for fish in tank.fish:
		if fish.growth >= 1.0:
			grown += 1
	if grown > 0:
		IsoDraw.label(self, Vector2(at.x, y), "★ " + tr("%d grown") % grown, 26, GROWN_COLOR)
		y -= 36.0
	var next := Aquarium.next_to_grow(tank)
	if next == null:
		return y
	var bar := Rect2(Vector2(at.x - GROW_BAR_SIZE.x * 0.5, y - GROW_BAR_SIZE.y * 0.5), GROW_BAR_SIZE)
	draw_rect(bar.grow(3.0), GROW_BAR_BACK)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * next.growth, bar.size.y)), GROW_BAR_FILL)
	var seconds := ceili(Aquarium.seconds_to_grow(tank, next))
	IsoDraw.label(self, Vector2(at.x, y - 28.0), tr("Grown in %s") % ("%d:%02d" % [seconds / 60, seconds % 60]), 24, LABEL_COLOR)
	return y - 64.0


## The water inside the glass, up to the drawn level; a full tank bulges over the rim. The
## rectangle spans the floor between the west and east posts, from the floor's middle up to the
## water level.
func _water_rect(rect: Rect2) -> Rect2:
	var level := clampf(_level, 0.0, 1.0)
	var bulge := BULGE * clampf((level - 0.98) / 0.02, 0.0, 1.0)
	var box := _glass_box(rect)
	var post: float = _glass().post * rect.size.x / _texture().get_width()
	var middle: Vector2 = (box[0] + box[2]) * 0.5
	var depth: float = box[4] * level + bulge
	return Rect2(box[0].x + post, middle.y - depth, box[2].x - box[0].x - 2.0 * post, depth)


## The water in the glass box (_glass_box), `depth` high: its two front sides and its surface,
## which sways a little (more in a full tank), never more than a quarter of the depth so the sides
## keep their shape.
func _draw_water(box: Array, depth: float, full: bool) -> void:
	if depth <= 2.0:
		return
	var wobble := sin(_time * (5.0 if full else 2.0)) * minf(3.0 if full else 1.5, depth * 0.25)
	var up := Vector2(0.0, -depth)
	var tilt := Vector2(0.0, wobble)
	var left: Vector2 = box[0]
	var front: Vector2 = box[1]
	var right: Vector2 = box[2]
	var back: Vector2 = box[3]
	draw_colored_polygon(PackedVector2Array([left, front, front + up + tilt, left + up - tilt]), WATER_SIDE_COLOR)
	draw_colored_polygon(PackedVector2Array([front, right, right + up - tilt, front + up + tilt]), WATER_SIDE_COLOR)
	draw_colored_polygon(PackedVector2Array([left + up - tilt, front + up + tilt, right + up - tilt, back + up + tilt]),
			WATER_SURFACE_COLOR)
	draw_polyline(PackedVector2Array([left + up - tilt, front + up + tilt, right + up - tilt]), Color(1.0, 1.0, 1.0, 0.8), 3.0, true)


## The west, south and east corner posts, drawn again from the sprite over the water and the fish,
## since they stand in front of them.
func _draw_front_posts(rect: Rect2) -> void:
	var texture := _texture()
	var glass := _glass()
	var s := rect.size.x / texture.get_width()
	var post: float = glass.post
	for corner: Vector2 in [glass.left, glass.front, glass.right]:
		var source := Rect2(corner.x - post, corner.y - glass.height - glass.cap, post * 2.0, glass.height + glass.cap + post * 1.5)
		draw_texture_rect_region(texture, Rect2(rect.position + source.position * s, source.size * s), source)


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
	draw_texture_rect(PUDDLE_TEXTURE, Rect2(Vector2(rect.get_center().x + 8.0, 10.0) - size * 0.5, size), false)


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
