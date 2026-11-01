class_name StoreRoom
extends Node2D
## The gear shop's room: a plank floor and the two back walls (north and west), the front walls
## left open so the room can be seen into. Drawn in code as a PLACEHOLDER until the final art
## exists.

const WALL_HEIGHT := 320.0
const PLANK_WIDTH := 100.0
const FLOOR_COLOR := Color(0.78, 0.6, 0.4)
const PLANK_LINE := Color(0.55, 0.38, 0.24, 0.6)
const NORTH_WALL := Color(0.93, 0.87, 0.74)
const WEST_WALL := Color(0.82, 0.75, 0.62)
const SKIRTING := Color(0.45, 0.3, 0.2)

## The floor, in ground units.
var room := Rect2()


func setup(floor_rect: Rect2) -> void:
	room = floor_rect
	queue_redraw()


## The screen rectangle the room covers, walls included.
func screen_bounds() -> Rect2:
	var bounds := Rect2(Iso.to_screen(room.position), Vector2.ZERO)
	for corner: Vector2 in [Vector2(room.end.x, room.position.y), room.end, Vector2(room.position.x, room.end.y)]:
		bounds = bounds.expand(Iso.to_screen(corner))
	return bounds.expand(Iso.to_screen(room.position) - Vector2(0.0, WALL_HEIGHT))


func _draw() -> void:
	var north_west := room.position
	var north_east := Vector2(room.end.x, room.position.y)
	var south_east := room.end
	var south_west := Vector2(room.position.x, room.end.y)
	var up := Vector2(0.0, -WALL_HEIGHT)
	var corners := PackedVector2Array()
	for corner: Vector2 in [north_west, north_east, south_east, south_west]:
		corners.append(Iso.to_screen(corner))
	IsoDraw.fill_outlined(self, corners, FLOOR_COLOR, 6.0)
	# Planks run from the back wall to the front.
	var x := room.position.x + PLANK_WIDTH
	while x < room.end.x:
		draw_line(Iso.to_screen(Vector2(x, room.position.y)), Iso.to_screen(Vector2(x, room.end.y)), PLANK_LINE, 3.0, true)
		x += PLANK_WIDTH
	var nw := Iso.to_screen(north_west)
	var ne := Iso.to_screen(north_east)
	var sw := Iso.to_screen(south_west)
	IsoDraw.fill_outlined(self, PackedVector2Array([nw, ne, ne + up, nw + up]), NORTH_WALL, 6.0)
	IsoDraw.fill_outlined(self, PackedVector2Array([sw, nw, nw + up, sw + up]), WEST_WALL, 6.0)
	draw_line(nw, ne, SKIRTING, 10.0, true)
	draw_line(sw, nw, SKIRTING, 10.0, true)
