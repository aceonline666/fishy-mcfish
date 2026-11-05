class_name TutorialGuide
extends Control
## Shows the tutorial (Tutorial): a card at the top of the play area with what to do next, and a
## golden arrow showing where to walk. While that place is in view the arrow bobs over it, pointing
## down; while it is not, the arrow waits at the edge of the view, pointing towards it. Covers its
## parent and lets every touch through.

const GOLD := Color(1.0, 0.85, 0.2)
const CARD_COLOR := Color(0.1, 0.24, 0.4)
const CARD_WIDTH := 900.0
const ARROW_LENGTH := 110.0
const ARROW_WIDTH := 84.0
const ARROW_OUTLINE := 8.0
## How far the arrow bobs (pixels) and how fast (radians per second).
const BOB_PX := 22.0
const BOB_SPEED := 6.0
## The arrow keeps this far inside the view's edges.
const EDGE_MARGIN := 40.0
const POP_IN_S := 0.35

## Top of the card.
var top_offset := 280.0
## Where the arrow may be (this control's coordinates): the play area between the HUD bars.
var view_rect := Rect2()

var _card: PanelContainer
var _title: Label
var _body: Label
var _card_wanted := false
var _card_allowed := true
var _target := Vector2.ZERO
var _has_target := false
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build_card()


func _process(delta: float) -> void:
	_time += delta
	_place_card()
	if _has_target:
		queue_redraw()


## Shows the card with `title` and `body`; pops it in again whenever the text changes.
func show_message(title: String, body: String) -> void:
	if _card_wanted and _title.text == title and _body.text == body:
		return
	_card_wanted = true
	_title.text = title
	_body.text = body
	_update_card_visibility()
	_place_card()
	_card.scale = Vector2.ONE * 0.6
	_card.modulate.a = 0.0
	var tween := _card.create_tween()
	tween.tween_property(_card, "scale", Vector2.ONE, POP_IN_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_card, "modulate:a", 1.0, POP_IN_S * 0.5)
	Sfx.play(&"ding", 1.2, -8.0)


func hide_message() -> void:
	_card_wanted = false
	_update_card_visibility()


## The card steps aside while something else (a goal's banner) is shown in its place.
func allow_card(allowed: bool) -> void:
	if allowed != _card_allowed:
		_card_allowed = allowed
		_update_card_visibility()


func message_title() -> String:
	return _title.text if _card_wanted else ""


## Points the arrow at `at` (this control's coordinates): the place to walk to.
func point_at(at: Vector2) -> void:
	_target = at
	_has_target = true


func clear_arrow() -> void:
	if _has_target:
		_has_target = false
		queue_redraw()


func has_arrow() -> bool:
	return _has_target


## Where the arrow's tip is and the direction it points in, for the current target.
func arrow_tip() -> Array[Vector2]:
	var area := _arrow_area()
	var bob := (0.5 + 0.5 * sin(_time * BOB_SPEED)) * BOB_PX
	# Pointing down, the arrow only needs room above the place.
	var hover := Rect2(area.position.x - ARROW_LENGTH, area.position.y, area.size.x + ARROW_LENGTH * 2.0, area.size.y + ARROW_LENGTH)
	if hover.has_point(_target):
		return [_target + Vector2(0.0, -bob), Vector2.DOWN]
	var center := area.get_center()
	var direction := center.direction_to(_target)
	# Where the line from the view's centre to the target leaves the view.
	var reach := INF
	if absf(direction.x) > 0.001:
		reach = minf(reach, (area.size.x * 0.5) / absf(direction.x))
	if absf(direction.y) > 0.001:
		reach = minf(reach, (area.size.y * 0.5) / absf(direction.y))
	return [center + direction * (reach - bob), direction]


func _draw() -> void:
	if not _has_target:
		return
	var tip := arrow_tip()
	var points := _arrow_shape(tip[0], tip[1])
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Juice.OUTLINE_COLOR, ARROW_OUTLINE * 2.0, true)
	draw_colored_polygon(points, GOLD)


## An arrow with its tip at `tip`, pointing in `direction`.
func _arrow_shape(tip: Vector2, direction: Vector2) -> PackedVector2Array:
	var head := ARROW_LENGTH * 0.55
	var half := ARROW_WIDTH * 0.5
	var shaft := ARROW_WIDTH * 0.2
	var local := PackedVector2Array([
		Vector2.ZERO, Vector2(-head, -half), Vector2(-head, -shaft), Vector2(-ARROW_LENGTH, -shaft),
		Vector2(-ARROW_LENGTH, shaft), Vector2(-head, shaft), Vector2(-head, half),
	])
	return Transform2D(direction.angle(), tip) * local


## The view minus a margin, below the card while it shows. The arrow's tail stays inside it too.
func _arrow_area() -> Rect2:
	var area := view_rect if view_rect.has_area() else Rect2(Vector2.ZERO, size)
	if _card.visible:
		var below_card := _card.position.y + _card.size.y
		var cut := clampf(below_card - area.position.y, 0.0, area.size.y * 0.5)
		area = Rect2(area.position.x, area.position.y + cut, area.size.x, area.size.y - cut)
	return area.grow(-EDGE_MARGIN - ARROW_LENGTH)


func _update_card_visibility() -> void:
	_card.visible = _card_wanted and _card_allowed


func _place_card() -> void:
	var width := minf(CARD_WIDTH, size.x - 32.0) if size.x > 0.0 else CARD_WIDTH
	_card.custom_minimum_size.x = width
	# The wrapped text only knows its height once the card has its width.
	_card.reset_size()
	_card.pivot_offset = _card.size * 0.5
	_card.position = Vector2((size.x - _card.size.x) * 0.5, top_offset)


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.custom_minimum_size.x = CARD_WIDTH
	var style := StyleBoxTexture.new()
	style.texture = OverlayPanel.CARD_TEXTURE
	style.set_texture_margin_all(32.0)
	style.texture_margin_bottom = 40.0
	style.set_content_margin_all(36.0)
	style.content_margin_bottom = 42.0
	var grey := OverlayPanel.CARD_GREY
	style.modulate_color = Color(CARD_COLOR.r / grey, CARD_COLOR.g / grey, CARD_COLOR.b / grey)
	_card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	_card.add_child(column)
	_title = _label(48, GOLD)
	_title.theme_type_variation = &"TitleLabel"
	column.add_child(_title)
	_body = _label(34, Color.WHITE)
	column.add_child(_body)
	_card.hide()
	add_child(_card)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Juice.OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", maxi(font_size / 5, 6))
	return label
