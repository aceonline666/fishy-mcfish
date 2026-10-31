class_name OverlayPanel
extends Control
## Base for full-screen panels (Fishpedia, Goals, map): an opaque backdrop, a header with a
## title and a Close button, and a scrollable `content` column. Subclasses fill `content` in
## _build() and refresh it in _refresh(), which runs every time the panel opens. When the language
## changes, the panel is built again in the new language.

## Deep water: sunlit at the top, dark below.
const BACKDROP := preload("res://assets/ui/frames/backdrop.svg")
const CARD_COLOR := Color(0.08, 0.2, 0.33)
const CARD_HOVER := Color(0.11, 0.27, 0.42)
const CARD_TEXTURE := preload("res://assets/ui/frames/card.svg")
## The grey of the card picture's face (#cccccc): tinting by color / CARD_GREY shows the color.
const CARD_GREY := 0.8
const MUTED := Color(0.65, 0.75, 0.85)
## A press that moves further than this (pixels) before release is a drag, not a tap.
const TAP_DISTANCE := 24.0

var content: VBoxContainer

var _title: Label
var _rebuild_pending := false
## Where the last button press started.
var _press_at := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()
	_build_all()


func _notification(what: int) -> void:
	# Children cannot change while notifications go around, so rebuild at the end of the frame.
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _rebuild_pending:
		_rebuild_pending = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_pending = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build_all()
	if visible:
		_refresh()
		_pass_drags(content)


func _build_all() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := SafeAreaContainer.new()
	margin.edge_padding = 32
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.theme_type_variation = &"TitleLabel"
	_title.add_theme_font_size_override("font_size", 64)
	header.add_child(_title)
	header.add_child(make_button(tr("Close"), hide))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)
	_build()


func open() -> void:
	_refresh()
	_pass_drags(content)
	show()


func set_title(text: String) -> void:
	_title.text = text


## Cards, pictures and bars would keep a touch to themselves, so a drag starting on them would
## not scroll the list; they pass it on instead (buttons do so through connect_tap()).
func _pass_drags(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not child is BaseButton and child.mouse_filter == Control.MOUSE_FILTER_STOP:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_pass_drags(child)


## Override: create the panel's controls once.
func _build() -> void:
	pass


## Override: update the controls with the current state.
func _refresh() -> void:
	pass


func make_label(text: String, font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label


func make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 40)
	button.custom_minimum_size = Vector2(220.0, 100.0)
	connect_tap(button, action)
	return button


## Makes `button` scroll-friendly: the touch passes on to the scroll container, so the list can
## be dragged starting on the button, and `action` only runs for a tap, not after a drag.
func connect_tap(button: BaseButton, action: Callable) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.button_down.connect(func() -> void: _press_at = get_global_mouse_position())
	button.pressed.connect(func() -> void:
		if get_global_mouse_position().distance_to(_press_at) <= TAP_DISTANCE:
			action.call())


## A comic card in `color`: the grey card picture tinted, so its rim and shade come along.
func card_style(color: Color = CARD_COLOR) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = CARD_TEXTURE
	style.set_texture_margin_all(32.0)
	style.texture_margin_bottom = 40.0
	style.modulate_color = Color(color.r / CARD_GREY, color.g / CARD_GREY, color.b / CARD_GREY, color.a)
	style.set_content_margin_all(22.0)
	style.content_margin_bottom = 28.0
	return style
