class_name Fishpedia
extends OverlayPanel
## The collection book: a card for every species. Caught species show their sprite and how
## many were caught; undiscovered ones show a silhouette and where to look. Tapping a card
## opens its details with real facts.

const RARITY_COLORS: Array[Color] = [
	Color(0.8, 0.84, 0.88), Color(0.5, 0.9, 0.5), Color(0.45, 0.7, 1.0), Color(0.8, 0.55, 1.0), Color(1.0, 0.7, 0.25),
]

## Returns the FishArt for a species id.
var art_for: Callable

var _grid: GridContainer
var _detail: PanelContainer
var _detail_picture: FishPicture
var _detail_name: Label
var _detail_scientific: Label
var _detail_rarity: Label
var _detail_facts: Label
var _detail_fun_fact: Label


func _build() -> void:
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 20)
	content.add_child(_grid)
	_build_detail()


func _refresh() -> void:
	_detail.hide()
	for child in _grid.get_children():
		child.queue_free()
	var caught := GameState.state.species_caught
	var species_list := DataRegistry.species.values()
	set_title(tr("Fishpedia  %d / %d") % [caught.size(), species_list.size()])
	for def: SpeciesDef in species_list:
		_grid.add_child(_make_card(def, caught.has(def.id)))


func _make_card(def: SpeciesDef, known: bool) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0.0, 300.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state_name: String in ["normal", "hover", "pressed", "focus"]:
		card.add_theme_stylebox_override(state_name, card_style(CARD_HOVER if state_name == "hover" else CARD_COLOR))
	connect_tap(card, _show_detail.bind(def))

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 16.0
	column.offset_right = -16.0
	column.offset_top = 12.0
	column.offset_bottom = -12.0
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)

	var picture := FishPicture.new()
	picture.art = art_for.call(def.id)
	picture.known = known
	picture.custom_minimum_size = Vector2(0.0, 160.0)
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)
	column.add_child(make_label(tr(def.common_name) if known else "???", 32))
	var subtitle := make_label("", 26)
	if known:
		subtitle.text = tr("%s · caught %d") % [_rarity_name(def.rarity), GameState.state.species_caught[def.id]]
		subtitle.add_theme_color_override("font_color", RARITY_COLORS[def.rarity])
	else:
		subtitle.text = _where_found(def)
		subtitle.add_theme_color_override("font_color", MUTED)
	column.add_child(subtitle)
	return card


func _build_detail() -> void:
	_detail = PanelContainer.new()
	_detail.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail.offset_left = 40.0
	_detail.offset_right = -40.0
	_detail.offset_top = 220.0
	_detail.offset_bottom = -220.0
	_detail.add_theme_stylebox_override("panel", card_style())
	add_child(_detail)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_detail.add_child(column)

	_detail_picture = FishPicture.new()
	_detail_picture.custom_minimum_size = Vector2(0.0, 300.0)
	_detail_picture.fill = 0.9
	column.add_child(_detail_picture)
	_detail_name = make_label("", 56)
	column.add_child(_detail_name)
	_detail_scientific = make_label("", 34)
	_detail_scientific.add_theme_color_override("font_color", MUTED)
	column.add_child(_detail_scientific)
	_detail_rarity = make_label("", 34)
	column.add_child(_detail_rarity)
	_detail_facts = make_label("", 32)
	column.add_child(_detail_facts)
	_detail_fun_fact = make_label("", 34)
	_detail_fun_fact.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_detail_fun_fact)
	column.add_child(make_button(tr("Back"), _detail.hide))


func _show_detail(def: SpeciesDef) -> void:
	var known := GameState.state.species_caught.has(def.id)
	_detail_picture.art = art_for.call(def.id)
	_detail_picture.known = known
	_detail_name.text = tr(def.common_name) if known else tr("Not discovered yet")
	_detail_scientific.text = def.scientific_name if known else ""
	_detail_rarity.text = _rarity_name(def.rarity)
	_detail_rarity.add_theme_color_override("font_color", RARITY_COLORS[def.rarity])
	if known:
		_detail_facts.text = tr("Up to %d cm · needs a tank of %d L or more\nTakes %s L · worth %s to %s coins\n%s") % [
			int(def.length_cm), int(def.min_tank_l), NumberFormat.compact(def.space_l),
			NumberFormat.compact(Economy.sale_price(def, 0.0)), NumberFormat.compact(Economy.sale_price(def, 1.0)),
			_where_found(def)]
		_detail_fun_fact.text = tr(def.fun_fact)
	else:
		_detail_facts.text = _where_found(def)
		_detail_fun_fact.text = tr("Catch one to learn more.")
	_detail.show()


## Lists the zones where the species lives, e.g. "Found in: Sandbanks, Wreck".
func _where_found(def: SpeciesDef) -> String:
	var zones: Array[String] = []
	for zone in DataRegistry.zones:
		if zone.spawns.has(def.id):
			zones.append(tr(zone.name))
	return tr("Found in: %s") % ", ".join(zones) if not zones.is_empty() else tr("Not found here")


func _rarity_name(rarity: SpeciesDef.Rarity) -> String:
	return [tr("Common"), tr("Uncommon"), tr("Rare"), tr("Epic"), tr("Legendary")][rarity]
