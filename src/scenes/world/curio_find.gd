class_name CurioFind
extends Node2D
## A rare find in the water (Curiosities): a message in a bottle bobbing in the shallows, or a
## curiosity on the seabed, faded into the water with depth like the other seabed props (it shares
## their material). A glint flashes over it now and then so a sharp eye can spot it. pick_up()
## lifts it out: it rises and fades.

const BOTTLE_WIDTH := 70.0
const ITEM_WIDTH := 58.0
## Share of the sprite height below the find's ground point, as SeabedDecor.PROP_BASE.
const BASE := 0.12
## Seconds between glints, how long one lasts, its size and colour.
const GLINT_INTERVAL_S := 2.2
const GLINT_S := 0.45
const GLINT_SIZE := 13.0
const GLINT_COLOR := Color(1.0, 0.97, 0.8)

var find_id := ""
## The find's position on the ground.
var ground := Vector2.ZERO

var _texture: Texture2D
var _size := Vector2.ZERO
var _bottle := false
var _alpha := 1.0
var _time := 0.0
var _lifting := false


func setup(id: String, ground_position: Vector2, seabed_material: Material) -> void:
	find_id = id
	ground = ground_position
	position = Iso.to_screen(ground)
	_bottle = Curiosities.is_bottle(id)
	_texture = Curiosities.texture(id)
	_size = _texture.get_size() * ((BOTTLE_WIDTH if _bottle else ITEM_WIDTH) / _texture.get_width())
	# The bottle floats, so the water does not tint it; things on the seabed take its tint.
	if not _bottle:
		material = seabed_material


## Where the glint flashes, relative to the find's ground point.
func glint_point() -> Vector2:
	return Vector2(-_size.x * 0.15, -_size.y * 0.55)


func pick_up() -> void:
	_lifting = true
	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector2(0.0, -50.0), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_alpha", 0.0, 0.8)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2(-_size.x * 0.5, -_size.y * (1.0 - BASE)), _size)
	if _bottle:
		# Bobbing and rocking on the water, with a ring of foam around it.
		var bob := sin(_time * 2.2) * 3.0
		draw_colored_polygon(Iso.ellipse(Vector2.ZERO, _size.x * 0.45, 16), Color(0.0, 0.1, 0.2, 0.18 * _alpha))
		draw_set_transform(Vector2(0.0, bob), sin(_time * 1.6) * 0.08, Vector2.ONE)
		draw_texture_rect(_texture, rect, false, Color(1.0, 1.0, 1.0, _alpha))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		# The shader reads the depth from the colour, as for SeabedDecor's props.
		draw_texture_rect(_texture, rect, false, Color(SeaDepth.depth(ground.y), SeaDepth.abyss(ground.y), 0.0, _alpha))
	if not _lifting:
		_draw_glint()


## A four-pointed star that swells and shrinks once every GLINT_INTERVAL_S.
func _draw_glint() -> void:
	var t := fmod(_time, GLINT_INTERVAL_S) / GLINT_S
	if t >= 1.0:
		return
	var size := sin(t * PI) * GLINT_SIZE
	var at := glint_point()
	var points := PackedVector2Array()
	for i in 8:
		var radius := size if i % 2 == 0 else size * 0.22
		points.append(at + Vector2.from_angle(i * PI / 4.0) * radius)
	draw_colored_polygon(points, GLINT_COLOR)
