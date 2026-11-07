class_name TreasureChest
extends Node2D
## The secret treasure chest on the seabed (Treasure): the painted chest, faded into the water
## with depth like the other seabed props (it shares their material), and a glint that flashes
## over its coins now and then so a sharp eye can spot it. open() empties it: it rises and fades.

const TEXTURE: Texture2D = preload("res://assets/sprites/seabed/treasure_chest.png")
const WIDTH := 110.0
## Share of the sprite height below the chest's ground point, as SeabedDecor.PROP_BASE.
const BASE := 0.12
## Where the glint flashes, relative to the chest's ground point (screen units).
const GLINT_OFFSET := Vector2(-6.0, -52.0)
## Seconds between glints, and how long one lasts.
const GLINT_INTERVAL_S := 2.6
const GLINT_S := 0.45
const GLINT_SIZE := 15.0
const GLINT_COLOR := Color(1.0, 0.97, 0.75)

## The chest's position on the ground.
var ground := Vector2.ZERO
## True from open() on; it frees itself when faded out.
var opening := false

var _size := Vector2.ZERO
var _alpha := 1.0
var _glint: Node2D
var _time := 0.0


func setup(ground_position: Vector2, seabed_material: Material) -> void:
	ground = ground_position
	position = Iso.to_screen(ground)
	material = seabed_material
	_size = TEXTURE.get_size() * (WIDTH / TEXTURE.get_width())
	_glint = Node2D.new()
	_glint.position = GLINT_OFFSET
	_glint.draw.connect(_draw_glint)
	add_child(_glint)


func open() -> void:
	opening = true
	_glint.hide()
	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector2(0.0, -40.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(_set_alpha, 1.0, 0.0, 0.9)
	tween.tween_callback(queue_free)


func _set_alpha(value: float) -> void:
	_alpha = value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _glint.visible:
		_glint.queue_redraw()


func _draw() -> void:
	# The shader reads the depth from the colour, as for SeabedDecor's props.
	var tint := Color(SeaDepth.depth(ground.y), SeaDepth.abyss(ground.y), 0.0, _alpha)
	draw_texture_rect(TEXTURE, Rect2(Vector2(-_size.x * 0.5, -_size.y * (1.0 - BASE)), _size), false, tint)


## A four-pointed star that swells and shrinks once every GLINT_INTERVAL_S.
func _draw_glint() -> void:
	var t := fmod(_time, GLINT_INTERVAL_S) / GLINT_S
	if t >= 1.0:
		return
	var reach := GLINT_SIZE * sin(t * PI)
	var waist := reach * 0.18
	var star := PackedVector2Array()
	for i in 8:
		var angle := i * TAU / 8.0 + t * 0.6
		star.append(Vector2.from_angle(angle) * (reach if i % 2 == 0 else waist))
	_glint.draw_colored_polygon(star, GLINT_COLOR)
	_glint.draw_circle(Vector2.ZERO, waist * 1.4, Color.WHITE)
