class_name GearShopNode
extends Node2D
## The gear shop on the beach, where the upgrades are bought (UpgradeStore): a big building with
## its door at the west end of its front, towards the boardwalk, and a sign on the roof.
## Painted sprite assets/sprites/props/gear_shop.png (cut and straightened from
## art_source/"Bunt bemaltes Fischereigeschäft am Meer.png" by tools/extract_gear_shop.py); the
## sign's text is drawn in code so it is translated. The building covers cells of the layout grid
## (Grid) and is drawn as big as fits them. It is painted less deep than long, so it stands on the
## footprint's front (south and east) edges and the rest of the depth is hidden behind it. The node
## sits at the middle of its footprint.

const TEXTURE: Texture2D = preload("res://assets/sprites/props/gear_shop.png")
## The front corners of the building's footprint in the sprite (pixels): west, south, east.
const LEFT := Vector2(12.0, 816.0)
const BOTTOM := Vector2(778.0, 1196.0)
const RIGHT := Vector2(1179.0, 993.0)
## The middle of the sign board in the sprite, the slant of the board and the room for the text
## between the fish painted at its ends (pixels).
const SIGN := Vector2(558.0, 177.0)
const SIGN_ANGLE := deg_to_rad(8.7)
const SIGN_TEXT_WIDTH := 390.0
const SIGN_TEXT_SIZE := 72
const SIGN_TEXT_COLOR := Color(0.25, 0.14, 0.05)

var _scale := 1.0
## Where the sprite's top left corner is drawn, relative to the node.
var _origin := Vector2.ZERO


## `area` is the ground the building covers: whole cells of the layout grid.
func setup(area: Rect2) -> void:
	position = Iso.to_screen(area.get_center())
	_scale = Grid.fit_scale(LEFT, BOTTOM, RIGHT, Vector2i((area.size / Grid.UNIT).round()))
	_origin = Iso.to_screen(area.end - area.get_center()) - BOTTOM * _scale
	queue_redraw()


## Where the sprite is drawn, relative to the node.
func sprite_bounds() -> Rect2:
	return Rect2(_origin, TEXTURE.get_size() * _scale)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
	draw_texture(TEXTURE, Vector2.ZERO)
	# Painted letters: no outline, shrunk until they fit between the fish.
	var font := IsoDraw.title_font()
	var text := tr("Fishing gear")
	var size := SIGN_TEXT_SIZE
	while size > 24 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > SIGN_TEXT_WIDTH:
		size -= 4
	draw_set_transform(_origin + SIGN * _scale, SIGN_ANGLE, Vector2.ONE * _scale)
	var baseline := Vector2(-SIGN_TEXT_WIDTH * 0.5, (font.get_ascent(size) - font.get_descent(size)) * 0.5)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, SIGN_TEXT_WIDTH, size, SIGN_TEXT_COLOR)
	draw_set_transform(Vector2.ZERO)
