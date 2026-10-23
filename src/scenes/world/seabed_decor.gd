class_name SeabedDecor
extends Node2D
## Rocks, shells and swaying seaweed on the seabed, so the isometric ground reads clearly.
## Placeholder art drawn in code; sits below the fish and the wader.

const OUTLINE := Color(0.07, 0.09, 0.15, 0.8)
const ROCK_COLOR := Color(0.47, 0.52, 0.55)
const ROCK_LIGHT := Color(0.66, 0.72, 0.74)
const SHELL_COLOR := Color(0.98, 0.88, 0.8)
const WEED_COLORS: Array[Color] = [Color(0.25, 0.55, 0.3), Color(0.35, 0.65, 0.32), Color(0.2, 0.45, 0.35)]
## Underwater things take on the water colour.
const WATER_TINT := Color(0.15, 0.45, 0.6)
const ROCKS := 5
const WEEDS := 6
const SHELLS := 7

var _rocks: Array[Rock] = []
var _weeds: Array[Weed] = []
var _shells := PackedVector2Array()
var _time := 0.0


func generate(area: PlayArea, seed_value: int = 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_rocks.clear()
	_weeds.clear()
	_shells.clear()
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
		_weeds.append(weed)
	for i in SHELLS:
		_shells.append(Iso.to_screen(area.random_point(rng, 40.0)))
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
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
	draw_colored_polygon(outline, ROCK_COLOR.lerp(WATER_TINT, 0.35))
	draw_colored_polygon(Iso.ellipse(rock.at + Vector2(-rock.radius * 0.25, -rock.radius * 0.45), rock.radius * 0.45, 12),
			ROCK_LIGHT.lerp(WATER_TINT, 0.3))
	outline.append(outline[0])
	draw_polyline(outline, OUTLINE, 3.0, true)


func _draw_weed(weed: Weed) -> void:
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


class Rock extends RefCounted:
	var at := Vector2.ZERO
	var radius := 30.0
	var bumps := PackedFloat32Array()


class Weed extends RefCounted:
	var at := Vector2.ZERO
	var height := 60.0
	var phase := 0.0
	var color := Color.GREEN
