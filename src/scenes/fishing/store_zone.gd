class_name StoreZone
extends Node2D
## The "Store fish" square in the shallows, next to an aquarium tank on the beach. Walking onto
## the square unloads the backpack into the tank. Drawn in code until real art arrives.

## Half the side length of the square, in ground units.
const HALF_SIZE := 110.0
## Where the tank stands relative to the square, in ground units (towards the beach).
const TANK_OFFSET := Vector2(10.0, -260.0)
const TANK_HALF := Vector2(62.0, 42.0)
const TANK_HEIGHT := 74.0
const STAND_HEIGHT := 16.0

const OUTLINE := Color(0.07, 0.09, 0.15)
const SQUARE_FILL := Color(1.0, 1.0, 1.0, 0.24)
const SQUARE_ACTIVE_FILL := Color(0.55, 1.0, 0.7, 0.35)
const BRACKET := Color(1.0, 1.0, 1.0, 0.95)
const BRACKET_CALLING := Color(1.0, 0.85, 0.2)
const LABEL := Color(1.0, 1.0, 1.0)
const WOOD := Color(0.66, 0.44, 0.24)
const WOOD_DARK := Color(0.5, 0.32, 0.17)
const GLASS_SIDE := Color(0.38, 0.75, 0.9, 0.85)
const GLASS_FRONT := Color(0.3, 0.66, 0.85, 0.85)
const WATER_TOP := Color(0.62, 0.9, 1.0, 0.95)
const TANK_FISH := Color(1.0, 0.6, 0.25)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)

var ground_center := Vector2.ZERO
## True while the wader stands on the square.
var active := false
## Pulses the square when the backpack is full.
var calling := false

var _time := 0.0


func place(center: Vector2) -> void:
	ground_center = center
	position = Iso.to_screen(center)
	queue_redraw()


func contains(ground: Vector2) -> bool:
	var offset := (ground - ground_center).abs()
	return offset.x <= HALF_SIZE and offset.y <= HALF_SIZE


## Where stored fish fly to: just above the tank's water surface.
func tank_screen_position() -> Vector2:
	return position + Iso.to_screen(TANK_OFFSET) + Vector2(0.0, -STAND_HEIGHT - TANK_HEIGHT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_tank(Iso.to_screen(TANK_OFFSET))
	_draw_square()


func _draw_square() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 6.0) if (calling or active) else 0.0
	var grow := 1.0 + 0.06 * pulse if calling else 1.0
	var h := HALF_SIZE * grow
	var corners := PackedVector2Array([
		Iso.to_screen(Vector2(-h, -h)), Iso.to_screen(Vector2(h, -h)),
		Iso.to_screen(Vector2(h, h)), Iso.to_screen(Vector2(-h, h)),
	])
	draw_colored_polygon(corners, SQUARE_ACTIVE_FILL if active else SQUARE_FILL)
	# Corner brackets, like a drop zone.
	var color := BRACKET_CALLING if calling else BRACKET
	for i in 4:
		var corner := corners[i]
		for neighbour: Vector2 in [corners[(i + 1) % 4], corners[(i + 3) % 4]]:
			var end := corner.lerp(neighbour, 0.28)
			draw_line(corner, end, OUTLINE, 11.0, true)
			draw_line(corner, end, color, 6.0, true)
	var font := ThemeDB.fallback_font
	var width := 260.0
	var at := Vector2(-width * 0.5, 12.0)
	draw_string_outline(font, at, "Store fish", HORIZONTAL_ALIGNMENT_CENTER, width, 34, 10, OUTLINE)
	draw_string(font, at, "Store fish", HORIZONTAL_ALIGNMENT_CENTER, width, 34, LABEL)


## A glass aquarium on a wooden stand, standing on the sand.
func _draw_tank(base: Vector2) -> void:
	draw_colored_polygon(Iso.ellipse(base + Vector2(8.0, 6.0), TANK_HALF.x * 1.5, 20), SHADOW)
	_draw_box(base, TANK_HALF + Vector2(6.0, 6.0), STAND_HEIGHT, WOOD_DARK, WOOD_DARK, WOOD)
	var tank_base := base + Vector2(0.0, -STAND_HEIGHT)
	_draw_box(tank_base, TANK_HALF, TANK_HEIGHT, GLASS_SIDE, GLASS_FRONT, WATER_TOP)
	# Two little fish behind the glass.
	for k in 2:
		var swim := sin(_time * 1.3 + k * 2.0) * 14.0
		var at := tank_base + Vector2(-10.0 + k * 30.0 + swim, -26.0 - k * 18.0)
		var dir := 1.0 if cos(_time * 1.3 + k * 2.0) > 0.0 else -1.0
		draw_colored_polygon(Iso.ellipse(at, 9.0, 10), TANK_FISH)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-8.0 * dir, 0.0), at + Vector2(-15.0 * dir, -5.0), at + Vector2(-15.0 * dir, 5.0)]), TANK_FISH)
	# Glass highlights.
	var corner := tank_base + Iso.to_screen(Vector2(TANK_HALF.x, TANK_HALF.y))
	draw_line(corner + Vector2(-18.0, -12.0), corner + Vector2(-18.0, -TANK_HEIGHT + 10.0), Color(1.0, 1.0, 1.0, 0.5), 4.0)


## An isometric box on the ground: the two faces towards the camera and the top.
func _draw_box(base: Vector2, half: Vector2, height: float, right_color: Color, front_color: Color, top_color: Color) -> void:
	var up := Vector2(0.0, -height)
	var back := base + Iso.to_screen(Vector2(-half.x, -half.y))
	var right := base + Iso.to_screen(Vector2(half.x, -half.y))
	var front := base + Iso.to_screen(Vector2(half.x, half.y))
	var left := base + Iso.to_screen(Vector2(-half.x, half.y))
	_fill_outlined(PackedVector2Array([right, front, front + up, right + up]), right_color)
	_fill_outlined(PackedVector2Array([left, front, front + up, left + up]), front_color)
	_fill_outlined(PackedVector2Array([back + up, right + up, front + up, left + up]), top_color)


func _fill_outlined(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE, 4.0, true)
