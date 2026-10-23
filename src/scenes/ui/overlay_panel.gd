class_name OverlayPanel
extends Control
## Base for full-screen panels (Fishpedia, Goals, map): an opaque backdrop, a header with a
## title and a Close button, and a scrollable `content` column. Subclasses fill `content` in
## _build() and refresh it in _refresh(), which runs every time the panel opens. When the language
## changes, the panel is built again in the new language.

const BACKDROP := Color(0.02, 0.07, 0.14, 0.97)
const CARD_COLOR := Color(0.08, 0.2, 0.33)
const CARD_HOVER := Color(0.11, 0.27, 0.42)
const CARD_BORDER := Color(0.07, 0.09, 0.15)
const MUTED := Color(0.65, 0.75, 0.85)

var content: VBoxContainer

var _title: Label
var _rebuild_pending := false


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


func _build_all() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
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
	_title.add_theme_font_size_override("font_size", 60)
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
	show()


func set_title(text: String) -> void:
	_title.text = text


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
	button.pressed.connect(action)
	return button


func card_style(color: Color = CARD_COLOR) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = CARD_BORDER
	style.set_border_width_all(5)
	style.set_corner_radius_all(28)
	style.set_content_margin_all(20.0)
	return style
