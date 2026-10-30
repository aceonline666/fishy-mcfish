class_name SeabedDecor
extends Node2D
## Things on the seabed, so the isometric ground reads clearly; sits below the fish and the wader.
## In temperate water: painted props (assets/sprites/seabed, tools/extract_seabed.py): rocks,
## swaying kelp, mussels, starfish, anemones and a little sunken junk. In tropical water, drawn in
## code: branching corals, anemones, brain corals and shells.

const OUTLINE := Color(0.07, 0.09, 0.15, 0.8)
const ROCK_COLOR := Color(0.47, 0.52, 0.55)
const ROCK_LIGHT := Color(0.66, 0.72, 0.74)
const SHELL_COLOR := Color(0.98, 0.88, 0.8)
const WEED_COLORS: Array[Color] = [Color(0.25, 0.55, 0.3), Color(0.35, 0.65, 0.32), Color(0.2, 0.45, 0.35)]
## Underwater things take on the water colour.
const WATER_TINT := Color(0.15, 0.45, 0.6)
const ROCKS := 10
const WEEDS := 14
const SHELLS := 12
const PROPS_DIR := "res://assets/sprites/seabed/"
## Painted props: sprite, screen width and how many are scattered. Swaying ones are listed in SWAY.
const PROPS: Array[Array] = [
	["stones", 70.0, 4], ["rock", 90.0, 3], ["boulder", 120.0, 2],
	["kelp_small", 60.0, 4], ["kelp", 75.0, 4], ["kelp_tall", 90.0, 3], ["sea_lettuce", 90.0, 3],
	["mussels", 90.0, 2], ["starfish", 70.0, 2], ["anemones", 100.0, 2],
	["anchor", 110.0, 1], ["barrels", 110.0, 1], ["crate", 100.0, 1], ["lobster_pot", 110.0, 1], ["rowboat", 200.0, 1],
]
const SWAY: Array[String] = ["kelp_small", "kelp", "kelp_tall", "sea_lettuce"]
const WRECK_WIDTH := 460.0
## Props keep at least this far apart (ground units).
const PROP_SPACING := 150.0
## Share of the sprite height below the prop's ground point (the sand patch it stands on).
const PROP_BASE := 0.12
## Props take on the water colour, and darken with the sea between these depths (ground y, as
## in the water shader).
const PROP_TINT := Color(0.8, 0.92, 1.0)
const ABYSS_START := 1500.0
const ABYSS_END := 3300.0
const ABYSS_COLOR := Color(0.05, 0.1, 0.18)
const CORAL_COLORS: Array[Color] = [Color(1.0, 0.45, 0.55), Color(1.0, 0.62, 0.3), Color(0.72, 0.5, 1.0), Color(1.0, 0.85, 0.4)]
const BRAIN_CORAL := Color(0.88, 0.72, 0.55)
const ANEMONE := Color(0.95, 0.6, 0.85)

## Set before generate(): corals instead of seaweed.
var tropical := false

var _rocks: Array[Rock] = []
var _weeds: Array[Weed] = []
var _shells := PackedVector2Array()
## Painted props, nearest last.
var _props: Array[Prop] = []
var _time := 0.0


func generate(area: PlayArea, seed_value: int = 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_rocks.clear()
	_weeds.clear()
	_shells.clear()
	_props.clear()
	if not tropical:
		_scatter_props(area, rng)
		queue_redraw()
		return
	for i in ROCKS:
		var rock := Rock.new()
		rock.at = Iso.to_screen(area.random_point(rng, 60.0))
		rock.radius = rng.randf_range(22.0, 48.0)
		var bumps := PackedFloat32Array()
		for j in 10:
			bumps.append(rng.randf_range(0.8, 1.15))
		rock.bumps = bumps
		_rocks.append(rock)
	for i in WEEDS:
		var weed := Weed.new()
		weed.at = Iso.to_screen(area.random_point(rng, 60.0))
		weed.height = rng.randf_range(40.0, 80.0)
		weed.phase = rng.randf() * TAU
		weed.color = WEED_COLORS[rng.randi() % WEED_COLORS.size()]
		if tropical:
			weed.kind = Weed.Kind.ANEMONE if i % 3 == 0 else Weed.Kind.CORAL
			weed.color = ANEMONE if weed.kind == Weed.Kind.ANEMONE else CORAL_COLORS[rng.randi() % CORAL_COLORS.size()]
		_weeds.append(weed)
	for i in SHELLS:
		_shells.append(Iso.to_screen(area.random_point(rng, 40.0)))
	queue_redraw()


## Places a sunken ship on the seabed at a ground position.
func add_wreck(ground: Vector2) -> void:
	_props.append(_make_prop("wreck", ground, WRECK_WIDTH, 0.0))
	_sort_props()
	queue_redraw()


func _scatter_props(area: PlayArea, rng: RandomNumberGenerator) -> void:
	var taken := PackedVector2Array()
	for entry: Array in PROPS:
		for i in int(entry[2]):
			var ground := area.random_point(rng, 80.0)
			for attempt in 20:
				if not _crowded(ground, taken):
					break
				ground = area.random_point(rng, 80.0)
			taken.append(ground)
			_props.append(_make_prop(entry[0], ground, float(entry[1]) * rng.randf_range(0.85, 1.15), rng.randf() * TAU))
	_sort_props()


func _crowded(ground: Vector2, taken: PackedVector2Array) -> bool:
	for other in taken:
		if ground.distance_to(other) < PROP_SPACING:
			return true
	return false


func _make_prop(prop_name: String, ground: Vector2, width: float, phase: float) -> Prop:
	var prop := Prop.new()
	prop.texture = load(PROPS_DIR + prop_name + ".png")
	prop.at = Iso.to_screen(ground)
	prop.size = prop.texture.get_size() * (width / prop.texture.get_width())
	prop.sways = SWAY.has(prop_name)
	prop.phase = phase
	prop.tint = PROP_TINT.lerp(ABYSS_COLOR, smoothstep(ABYSS_START, ABYSS_END, ground.y) * 0.85)
	return prop


func _sort_props() -> void:
	_props.sort_custom(func(a: Prop, b: Prop) -> bool: return a.at.y < b.at.y)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for prop in _props:
		# Swaying props lean from their base.
		var lean := sin(_time * 1.3 + prop.phase) * 0.12 if prop.sways else 0.0
		draw_set_transform_matrix(Transform2D(Vector2(1.0, 0.0), Vector2(lean, 1.0), prop.at))
		draw_texture_rect(prop.texture, Rect2(Vector2(-prop.size.x * 0.5, -prop.size.y * (1.0 - PROP_BASE)), prop.size), false, prop.tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	for shell in _shells:
		draw_colored_polygon(Iso.ellipse(shell, 7.0, 10), SHELL_COLOR.lerp(WATER_TINT, 0.3))
	for rock in _rocks:
		_draw_rock(rock)
	for weed in _weeds:
		_draw_weed(weed)


func _draw_rock(rock: Rock) -> void:
	draw_colored_polygon(Iso.ellipse(rock.at + Vector2(6.0, 8.0), rock.radius * 1.1, 16), Color(0.0, 0.05, 0.12, 0.2))
	# A squat lumpy dome: wider than tall, sitting on the seabed.
	var outline := PackedVector2Array()
	for j in rock.bumps.size():
		var angle := TAU * j / rock.bumps.size()
		var r := rock.radius * rock.bumps[j]
		outline.append(rock.at + Vector2(cos(angle) * r, sin(angle) * r * 0.65 - rock.radius * 0.25))
	var base_color := BRAIN_CORAL if tropical else ROCK_COLOR
	draw_colored_polygon(outline, base_color.lerp(WATER_TINT, 0.35))
	draw_colored_polygon(Iso.ellipse(rock.at + Vector2(-rock.radius * 0.25, -rock.radius * 0.45), rock.radius * 0.45, 12),
			base_color.lightened(0.25).lerp(WATER_TINT, 0.3))
	if tropical:
		# Brain coral grooves.
		for k in 3:
			var y := rock.at.y - rock.radius * (0.55 - k * 0.25)
			var groove := PackedVector2Array()
			for s in 7:
				var x := rock.at.x + (s - 3) * rock.radius * 0.22
				groove.append(Vector2(x, y + sin(s * 1.7 + k) * 3.0))
			draw_polyline(groove, base_color.darkened(0.3).lerp(WATER_TINT, 0.3), 2.5, true)
	outline.append(outline[0])
	draw_polyline(outline, OUTLINE, 3.0, true)


func _draw_weed(weed: Weed) -> void:
	match weed.kind:
		Weed.Kind.CORAL:
			_draw_coral(weed)
			return
		Weed.Kind.ANEMONE:
			_draw_anemone(weed)
			return
	for blade in 3:
		var lean := (blade - 1) * 10.0
		var points := PackedVector2Array()
		for k in 6:
			var t := k / 5.0
			var sway := sin(_time * 1.6 + weed.phase + blade + t * 2.0) * 9.0 * t
			points.append(weed.at + Vector2(lean * t + sway, -weed.height * t * (0.8 + blade * 0.1)))
		var color := weed.color.lerp(WATER_TINT, 0.25)
		draw_polyline(points, OUTLINE, 9.0, true)
		draw_polyline(points, color, 5.0, true)


## Branching coral: a short trunk that forks into knobbly branches.
func _draw_coral(coral: Weed) -> void:
	var color := coral.color.lerp(WATER_TINT, 0.2)
	var h := coral.height
	var sway := sin(_time * 0.8 + coral.phase) * 2.0
	var trunk_top := coral.at + Vector2(sway * 0.5, -h * 0.35)
	var tips: Array[Vector2] = [
		trunk_top + Vector2(-h * 0.35 + sway, -h * 0.45), trunk_top + Vector2(sway, -h * 0.7),
		trunk_top + Vector2(h * 0.38 + sway, -h * 0.5), trunk_top + Vector2(-h * 0.15 + sway, -h * 0.25),
	]
	for width: float in [15.0, 10.0]:
		var fill := IsoDraw.OUTLINE if width > 12.0 else color
		draw_line(coral.at, trunk_top, fill, width, true)
		for tip in tips:
			draw_line(trunk_top, tip, fill, width - 2.0, true)
			draw_circle(tip, (width - 2.0) * 0.55, fill)


## Sea anemone: a ring of swaying tentacles with pale tips.
func _draw_anemone(anemone: Weed) -> void:
	var color := anemone.color.lerp(WATER_TINT, 0.15)
	draw_colored_polygon(Iso.ellipse(anemone.at, 22.0, 14), Color(0.0, 0.05, 0.12, 0.2))
	for k in 9:
		var spread := (k - 4) * 6.0
		var points := PackedVector2Array()
		for s in 5:
			var t := s / 4.0
			var sway := sin(_time * 2.0 + anemone.phase + k * 0.7 + t * 2.0) * 6.0 * t
			points.append(anemone.at + Vector2(spread * (0.4 + t) + sway, -anemone.height * 0.55 * t))
		draw_polyline(points, IsoDraw.OUTLINE, 8.0, true)
		draw_polyline(points, color, 5.0, true)
		draw_circle(points[-1], 3.5, Color(1.0, 0.9, 0.95))


class Prop extends RefCounted:
	var texture: Texture2D
	var at := Vector2.ZERO
	var size := Vector2.ZERO
	var sways := false
	var phase := 0.0
	var tint := Color.WHITE


class Rock extends RefCounted:
	var at := Vector2.ZERO
	var radius := 30.0
	var bumps := PackedFloat32Array()


class Weed extends RefCounted:
	enum Kind { SEAWEED, CORAL, ANEMONE }

	var kind := Kind.SEAWEED
	var at := Vector2.ZERO
	var height := 60.0
	var phase := 0.0
	var color := Color.GREEN
