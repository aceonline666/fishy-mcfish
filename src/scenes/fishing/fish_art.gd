class_name FishArt
extends RefCounted
## Side-on sprite of one species, drawn from two images so the tail can beat: <id>_body and
## <id>_tail. Painted PNGs (assets/sprites/fish_painted, cut from a painted sprite sheet by
## tools/extract_painted.py) are used where they exist, otherwise the SVGs in
## assets/sprites/fish. Species without either get a coloured placeholder shape.
##
## Layout (in canvas units): the body canvas is 240 wide with the tail root at x=20 and the
## snout at x=220; the tail canvas is 70 wide with the tail root at x=62. Both are centred
## vertically on the body axis and face right.

const PAINTED_DIR := "res://assets/sprites/fish_painted/"
const SPRITE_DIR := "res://assets/sprites/fish/"
## Share of the total length taken by the body; the rest is tail fin.
const BODY_SHARE := 0.8
const BODY_CANVAS_WIDTH := 240.0
const BODY_ROOT_X := 20.0
const BODY_SPAN := 200.0
const TAIL_CANVAS_WIDTH := 70.0
const TAIL_ROOT_X := 62.0
const OUTLINE_COLOR := Color(0.07, 0.09, 0.15)

var species: SpeciesDef
var body: Texture2D
var tail: Texture2D


static func for_species(def: SpeciesDef) -> FishArt:
	var art := FishArt.new()
	art.species = def
	for source: PackedStringArray in [PackedStringArray([PAINTED_DIR, ".png"]), PackedStringArray([SPRITE_DIR, ".svg"])]:
		var body_path := source[0] + def.id + "_body" + source[1]
		var tail_path := source[0] + def.id + "_tail" + source[1]
		if ResourceLoader.exists(body_path) and ResourceLoader.exists(tail_path):
			art.body = load(body_path)
			art.tail = load(tail_path)
			break
	return art


func has_sprite() -> bool:
	return body != null


## Draws the fish centred on the origin of `view` (fish space: head towards +x, back towards -y)
## with the given total length. `tail_beat` scales the tail length (1 = at rest); `tint`
## multiplies the colours (black gives a silhouette).
func draw(canvas: CanvasItem, view: Transform2D, length: float, tail_beat: float = 1.0, tint: Color = Color.WHITE) -> void:
	if not has_sprite():
		_draw_placeholder(canvas, view, length, tint)
		return
	var units := length * BODY_SHARE / BODY_SPAN
	var root := Transform2D(0.0, Vector2(length * (0.5 - BODY_SHARE), 0.0))

	var tail_size := tail.get_size() * (TAIL_CANVAS_WIDTH / tail.get_width()) * units
	var beat := Transform2D(Vector2(tail_beat, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	canvas.draw_set_transform_matrix(view * root * beat)
	canvas.draw_texture_rect(tail, Rect2(Vector2(-TAIL_ROOT_X * units, -tail_size.y * 0.5), tail_size), false, tint)

	var body_size := body.get_size() * (BODY_CANVAS_WIDTH / body.get_width()) * units
	canvas.draw_set_transform_matrix(view * root)
	canvas.draw_texture_rect(body, Rect2(Vector2(-BODY_ROOT_X * units, -body_size.y * 0.5), body_size), false, tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


## A plain oval with a tail in the species colour, for species without sprites yet.
func _draw_placeholder(canvas: CanvasItem, view: Transform2D, length: float, tint: Color) -> void:
	var height := length * species.body_aspect
	var oval := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		oval.append(Vector2(cos(angle) * length * 0.4 + length * 0.1, sin(angle) * height * 0.5))
	var fin := PackedVector2Array([
		Vector2(-length * 0.25, 0.0), Vector2(-length * 0.5, -height * 0.45), Vector2(-length * 0.5, height * 0.45),
	])
	for shape: PackedVector2Array in [fin, oval]:
		var points := view * shape
		canvas.draw_colored_polygon(points, species.placeholder_color * tint)
		points.append(points[0])
		canvas.draw_polyline(points, OUTLINE_COLOR, 2.5, true)
