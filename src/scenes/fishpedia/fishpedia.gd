class_name Fishpedia
extends OverlayPanel
## The collection book: a card for every species. Caught species come first, in the order they
## were found, with their sprite and how many were caught; undiscovered ones stay a question
## mark and only tell where to look. Tapping a card
## opens its details with real facts. Above them, the curiosities: the rare finds (Curiosities),
## where the letters from the bottles can be read again.

const RARITY_COLORS: Array[Color] = [
	Color(0.8, 0.84, 0.88), Color(0.5, 0.9, 0.5), Color(0.45, 0.7, 1.0), Color(0.8, 0.55, 1.0), Color(1.0, 0.7, 0.25),
]

## Returns the FishArt for a species id.
var art_for: Callable

var _grid: GridContainer
var _curio_title: Label
var _curio_grid: GridContainer
var _species_title: Label
var _detail: PanelContainer
var _detail_picture: FishPicture
var _detail_unknown: Label
var _detail_texture: TextureRect
var _detail_name: Label
var _detail_scientific: Label
var _detail_rarity: Label
var _detail_facts: Label
var _detail_fun_fact: Label


func _build() -> void:
	_curio_title = make_label("", 44)
	content.add_child(_curio_title)
	_curio_grid = GridContainer.new()
	_curio_grid.columns = 3
	_curio_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_curio_grid.add_theme_constant_override("h_separation", 16)
	_curio_grid.add_theme_constant_override("v_separation", 16)
	content.add_child(_curio_grid)
	_species_title = make_label("", 44)
	content.add_child(_species_title)
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
	for child in _curio_grid.get_children():
		child.queue_free()
	var caught := GameState.state.species_caught
	var species_list := DataRegistry.species.values()
	set_title(tr("Fishpedia  %d / %d") % [caught.size(), species_list.size()])
	_species_title.text = tr("Species")
	var finds := Curiosities.all_ids()
	var found := GameState.state.curiosities
	_curio_title.text = tr("Curiosities  %d / %d") % [finds.filter(func(id: String) -> bool: return found.has(id)).size(), finds.size()]
	for find_id in finds:
		_curio_grid.add_child(_make_curio_card(find_id, found.has(find_id)))
	for id in GameState.state.species_order:
		if DataRegistry.species.has(id):
			_grid.add_child(_make_card(DataRegistry.species[id], true))
	for def: SpeciesDef in species_list:
		if not caught.has(def.id):
			_grid.add_child(_make_card(def, false))


## Opens the Fishpedia at a rare find's page (right after it was picked up).
func open_curiosity(find_id: String) -> void:
	open()
	_show_curio_detail(find_id)


func _make_curio_card(find_id: String, known: bool) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0.0, 250.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state_name: String in ["normal", "hover", "pressed", "focus"]:
		card.add_theme_stylebox_override(state_name, card_style(CARD_HOVER if state_name == "hover" else CARD_COLOR))
	connect_tap(card, _show_curio_detail.bind(find_id))
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 12.0
	column.offset_right = -12.0
	column.offset_top = 12.0
	column.offset_bottom = -12.0
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	column.add_child(_curio_picture(find_id, known, 120.0))
	column.add_child(make_label(tr(Curiosities.find_name(find_id)) if known else "???", 26))
	var place := make_label(tr(_location_name(find_id)), 22)
	place.add_theme_color_override("font_color", MUTED)
	column.add_child(place)
	return card


## The find's sprite; a dark silhouette until it is found.
func _curio_picture(find_id: String, known: bool, height: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = Curiosities.texture(find_id)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(0.0, height)
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.modulate = Color.WHITE if known else Color(0.0, 0.0, 0.0, 0.55)
	return picture


func _location_name(find_id: String) -> String:
	var location_id := Curiosities.location_of(find_id)
	for location in DataRegistry.locations:
		if location.id == location_id:
			return location.name
	return ""


## A find's page: its picture and name, and the letter in the bottle or what the item is.
func _show_curio_detail(find_id: String) -> void:
	var known := GameState.state.curiosities.has(find_id)
	_detail_picture.hide()
	_detail_unknown.hide()
	_detail_texture.texture = Curiosities.texture(find_id)
	_detail_texture.modulate = Color.WHITE if known else Color(0.0, 0.0, 0.0, 0.55)
	_detail_texture.show()
	_detail_name.text = tr(Curiosities.find_name(find_id)) if known else tr("Not discovered yet")
	_detail_scientific.text = tr(_location_name(find_id))
	_detail_rarity.text = ""
	if known:
		_detail_facts.text = ""
		_detail_fun_fact.text = tr(Curiosities.text(find_id))
	elif Curiosities.is_bottle(find_id):
		_detail_facts.text = tr("Something drifts into the shallows here once they are charted.")
		_detail_fun_fact.text = ""
	else:
		_detail_facts.text = tr("Something lies on the seabed of the second zone here, once it is charted.")
		_detail_fun_fact.text = ""
	_detail.show()


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

	if known:
		var picture := FishPicture.new()
		picture.art = art_for.call(def.id)
		picture.custom_minimum_size = Vector2(0.0, 160.0)
		picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(picture)
	else:
		var mark := _question_mark(110)
		mark.custom_minimum_size = Vector2(0.0, 160.0)
		mark.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(mark)
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
	_detail_unknown = _question_mark(200)
	_detail_unknown.custom_minimum_size = Vector2(0.0, 300.0)
	_detail_unknown.hide()
	column.add_child(_detail_unknown)
	_detail_texture = TextureRect.new()
	_detail_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_texture.custom_minimum_size = Vector2(0.0, 220.0)
	_detail_texture.hide()
	column.add_child(_detail_texture)
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
	_detail_texture.hide()
	_detail_picture.visible = known
	_detail_unknown.visible = not known
	_detail_picture.art = art_for.call(def.id)
	_detail_picture.known = known
	_detail_name.text = tr(def.common_name) if known else tr("Not discovered yet")
	_detail_scientific.text = def.scientific_name if known else ""
	_detail_rarity.text = _rarity_name(def.rarity) if known else ""
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


## Lists the locations and zones where the species lives, e.g.
## "Found in: North Sea: Sandbanks, Wreck".
func _where_found(def: SpeciesDef) -> String:
	var places: Array[String] = []
	for location in DataRegistry.locations:
		var zones: Array[String] = []
		for zone in DataRegistry.zones:
			if zone.location == location.id and zone.spawns.has(def.id):
				zones.append(tr(zone.name))
		if not zones.is_empty():
			places.append("%s: %s" % [tr(location.name), ", ".join(zones)])
	return tr("Found in: %s") % "; ".join(places) if not places.is_empty() else tr("Not found here")


## A big question mark standing in for a species not caught yet.
func _question_mark(font_size: int) -> Label:
	var mark := make_label("?", font_size)
	mark.theme_type_variation = &"TitleLabel"
	mark.add_theme_color_override("font_color", MUTED)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mark


func _rarity_name(rarity: SpeciesDef.Rarity) -> String:
	return [tr("Common"), tr("Uncommon"), tr("Rare"), tr("Epic"), tr("Legendary")][rarity]
