class_name Fishpedia
extends Control
## The collection book: a card for every species. Caught species show their sprite and how
## many were caught; undiscovered ones show a silhouette and where to look. Tapping a card
## opens its details with real facts. Built in code; covers the screen while open.

const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS: Array[Color] = [
	Color(0.8, 0.84, 0.88), Color(0.5, 0.9, 0.5), Color(0.45, 0.7, 1.0), Color(0.8, 0.55, 1.0), Color(1.0, 0.7, 0.25),
]
const BACKDROP := Color(0.02, 0.07, 0.14, 0.97)
const CARD_COLOR := Color(0.08, 0.2, 0.33)
const CARD_HOVER := Color(0.11, 0.27, 0.42)
const CARD_BORDER := Color(0.07, 0.09, 0.15)
const MUTED := Color(0.65, 0.75, 0.85)

## Returns the FishArt for a species id.
var art_for: Callable

var _title: Label
var _grid: GridContainer
var _detail: PanelContainer
var _detail_picture: FishPicture
var _detail_name: Label
var _detail_scientific: Label
var _detail_rarity: Label
var _detail_facts: Label
var _detail_fun_fact: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()
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
	header.add_child(_make_button("Close", hide))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(_grid)

	_build_detail()


## Shows the book with the latest catches.
func open() -> void:
	_rebuild()
	_detail.hide()
	show()


func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var caught := GameState.state.species_caught
	var species_list := DataRegistry.species.values()
	_title.text = "Fishpedia  %d / %d" % [caught.size(), species_list.size()]
	for def: SpeciesDef in species_list:
		_grid.add_child(_make_card(def, caught.has(def.id)))


func _make_card(def: SpeciesDef, known: bool) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0.0, 300.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state_name: String in ["normal", "hover", "pressed", "focus"]:
		card.add_theme_stylebox_override(state_name, _card_style(CARD_HOVER if state_name == "hover" else CARD_COLOR))
	card.pressed.connect(_show_detail.bind(def))

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16.0
	content.offset_right = -16.0
	content.offset_top = 12.0
	content.offset_bottom = -12.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)

	var picture := FishPicture.new()
	picture.art = art_for.call(def.id)
	picture.known = known
	picture.custom_minimum_size = Vector2(0.0, 160.0)
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(picture)
	content.add_child(_make_label(def.common_name if known else "???", 32))
	var subtitle := _make_label("", 26)
	if known:
		subtitle.text = "%s · caught %d" % [RARITY_NAMES[def.rarity], GameState.state.species_caught[def.id]]
		subtitle.add_theme_color_override("font_color", RARITY_COLORS[def.rarity])
	else:
		subtitle.text = _where_found(def)
		subtitle.add_theme_color_override("font_color", MUTED)
	content.add_child(subtitle)
	return card


func _build_detail() -> void:
	_detail = PanelContainer.new()
	_detail.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail.offset_left = 40.0
	_detail.offset_right = -40.0
	_detail.offset_top = 220.0
	_detail.offset_bottom = -220.0
	_detail.add_theme_stylebox_override("panel", _card_style(CARD_COLOR))
	add_child(_detail)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_detail.add_child(column)

	_detail_picture = FishPicture.new()
	_detail_picture.custom_minimum_size = Vector2(0.0, 300.0)
	_detail_picture.fill = 0.9
	column.add_child(_detail_picture)
	_detail_name = _make_label("", 56)
	column.add_child(_detail_name)
	_detail_scientific = _make_label("", 34)
	_detail_scientific.add_theme_color_override("font_color", MUTED)
	column.add_child(_detail_scientific)
	_detail_rarity = _make_label("", 34)
	column.add_child(_detail_rarity)
	_detail_facts = _make_label("", 32)
	column.add_child(_detail_facts)
	_detail_fun_fact = _make_label("", 34)
	_detail_fun_fact.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_detail_fun_fact)
	column.add_child(_make_button("Back", _detail.hide))


func _show_detail(def: SpeciesDef) -> void:
	var known := GameState.state.species_caught.has(def.id)
	_detail_picture.art = art_for.call(def.id)
	_detail_picture.known = known
	_detail_name.text = def.common_name if known else "Not discovered yet"
	_detail_scientific.text = def.scientific_name if known else ""
	_detail_rarity.text = RARITY_NAMES[def.rarity]
	_detail_rarity.add_theme_color_override("font_color", RARITY_COLORS[def.rarity])
	if known:
		_detail_facts.text = "Up to %d cm · needs a tank of %d L or more\nTakes %s L · worth %s to %s coins\n%s" % [
			int(def.length_cm), int(def.min_tank_l), NumberFormat.compact(def.space_l),
			NumberFormat.compact(Economy.sale_price(def, 0.0)), NumberFormat.compact(Economy.sale_price(def, 1.0)),
			_where_found(def)]
		_detail_fun_fact.text = def.fun_fact
	else:
		_detail_facts.text = _where_found(def)
		_detail_fun_fact.text = "Catch one to learn more."
	_detail.show()


## Lists the zones where the species lives, e.g. "Found in: Sandbanks, Wreck".
func _where_found(def: SpeciesDef) -> String:
	var zones: Array[String] = []
	for zone in DataRegistry.zones:
		if zone.spawns.has(def.id):
			zones.append(zone.name)
	return "Found in: " + ", ".join(zones) if not zones.is_empty() else "Not found here"


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 40)
	button.custom_minimum_size = Vector2(220.0, 100.0)
	button.pressed.connect(action)
	return button


func _card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = CARD_BORDER
	style.set_border_width_all(5)
	style.set_corner_radius_all(28)
	style.set_content_margin_all(20.0)
	return style
