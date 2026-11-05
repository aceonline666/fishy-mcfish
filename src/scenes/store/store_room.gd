class_name StoreRoom
extends Node2D
## The gear shop's room: a plank floor and the two back walls (north and west), the front walls
## left open so the room can be seen into. One painting (art_source/store/room_sprite_prompt.md,
## brought in by tools/import_store_art.py), scaled so its floor covers the room's cells; the
## shelves and the desk are separate sprites standing on it. The doormat painted on the floor is
## the way out.

const TEXTURE: Texture2D = preload("res://assets/sprites/props/store_room.png")
## The floor's left, front (bottom) and right corner in the painting.
const FLOOR_LEFT := Vector2(11.0, 579.0)
const FLOOR_FRONT := Vector2(715.0, 931.0)
const FLOOR_RIGHT := Vector2(1419.0, 579.0)
## The painted doormat, in cells from the room's north-west corner (measured on the painting).
const MAT := Rect2(2.65, 6.22, 1.3, 0.78)

## The floor, in ground units.
var room := Rect2()
## The painting's scale and where its top-left corner goes (screen coordinates).
var _scale := 1.0
var _origin := Vector2.ZERO


func setup(floor_rect: Rect2) -> void:
	room = floor_rect
	var cells := Vector2i((room.size / Grid.UNIT).round())
	_scale = Grid.fit_scale(FLOOR_LEFT, FLOOR_FRONT, FLOOR_RIGHT, cells)
	var floor_center := (FLOOR_LEFT + FLOOR_RIGHT) * 0.5
	_origin = Iso.to_screen(room.get_center()) - floor_center * _scale
	queue_redraw()


## The doormat, in ground units.
func mat() -> Rect2:
	return Rect2(room.position + MAT.position * Grid.UNIT, MAT.size * Grid.UNIT)


## The screen rectangle the room covers, walls included.
func screen_bounds() -> Rect2:
	return Rect2(_origin, TEXTURE.get_size() * _scale)


func _draw() -> void:
	draw_texture_rect(TEXTURE, screen_bounds(), false)
