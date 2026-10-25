class_name WorldMap
extends OverlayPanel
## The places to fish. Each card shows a picture of the place and whether the player is there,
## can travel there, can unlock it (goal reached, fee due) or still needs to reach its goal.

signal travel_chosen(def: LocationDef)

const HERE_COLOR := Color(0.55, 1.0, 0.65)
const LOCKED_COLOR := Color(1.0, 0.6, 0.5)
const PICTURE_DIR := "res://assets/sprites/props/location_"
const PICTURE_WIDTH := 250.0
## Places not open yet are shown dimmed.
const LOCKED_TINT := Color(0.4, 0.4, 0.48)


func _refresh() -> void:
	set_title(tr("World map"))
	for child in content.get_children():
		child.queue_free()
	for def in DataRegistry.locations:
		content.add_child(_make_card(def))


func _make_card(def: LocationDef) -> PanelContainer:
	var state := GameState.state
	var card := PanelContainer.new()
	var style := card_style(def.deep_color.darkened(0.35))
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	card.add_child(row)
	var picture_path := PICTURE_DIR + def.id + ".png"
	if ResourceLoader.exists(picture_path):
		var picture := TextureRect.new()
		picture.texture = load(picture_path)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.custom_minimum_size = Vector2(PICTURE_WIDTH, PICTURE_WIDTH * 1.25)
		if not Travel.is_unlocked(state, def):
			picture.modulate = LOCKED_TINT
		row.add_child(picture)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)

	column.add_child(make_label(tr(def.name), 52, HORIZONTAL_ALIGNMENT_LEFT))
	var species := _species_count(def)
	var found := _species_found(def)
	var facts := make_label(tr("%s · %d/%d species found") % [_water_name(def.env), found, species], 30, HORIZONTAL_ALIGNMENT_LEFT)
	facts.add_theme_color_override("font_color", MUTED)
	column.add_child(facts)
	column.add_child(make_label(tr(def.description), 32, HORIZONTAL_ALIGNMENT_LEFT))

	if def == Travel.current(state):
		var here := make_label(tr("You are here"), 38, HORIZONTAL_ALIGNMENT_LEFT)
		here.add_theme_color_override("font_color", HERE_COLOR)
		column.add_child(here)
	elif Travel.is_unlocked(state, def):
		column.add_child(make_button(tr("Travel"), travel_chosen.emit.bind(def)))
	elif Travel.can_unlock(state, def):
		var button := make_button(tr("Travel  %s coins") % NumberFormat.compact(def.travel_cost), travel_chosen.emit.bind(def))
		button.disabled = state.money < def.travel_cost
		column.add_child(button)
	else:
		var goal := Travel.unlock_goal(def)
		var locked := make_label(tr("Locked: reach the goal \"%s\" (%s)") % [tr(goal.name), tr(goal.description)], 32, HORIZONTAL_ALIGNMENT_LEFT)
		locked.add_theme_color_override("font_color", LOCKED_COLOR)
		column.add_child(locked)
	return card


func _water_name(env: String) -> String:
	return tr("Tropical water") if env == "tropical" else tr("Temperate water")


func _species_count(def: LocationDef) -> int:
	var ids: Dictionary[String, bool] = {}
	for zone in DataRegistry.zones_in(def.id):
		for id in zone.spawns:
			ids[id] = true
	return ids.size()


func _species_found(def: LocationDef) -> int:
	var ids: Dictionary[String, bool] = {}
	for zone in DataRegistry.zones_in(def.id):
		for id in zone.spawns:
			if GameState.state.species_caught.has(id):
				ids[id] = true
	return ids.size()
