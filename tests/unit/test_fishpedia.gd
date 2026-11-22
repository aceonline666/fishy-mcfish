extends GutTest

var _book: Fishpedia
var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state
	GameState.replace_state(PlayerState.new_game())
	_book = Fishpedia.new()
	_book.art_for = func(id: String) -> FishArt: return FishArt.for_species(DataRegistry.species[id])
	add_child_autofree(_book)


func after_each() -> void:
	GameState.replace_state(_original_state)


func test_lists_every_species_and_counts_the_caught_ones() -> void:
	GameState.record_catch("european_sprat")
	GameState.record_catch("atlantic_cod")
	_book.open()
	await wait_process_frames(2)

	assert_true(_book.visible)
	assert_string_contains(_book._title.text, "2 / %d" % DataRegistry.species.size())
	var listed := {}
	for index in DataRegistry.locations.size():
		for card: Button in _grid(index).get_children():
			listed[card] = true
	assert_eq(_book._sections.get_child_count(), DataRegistry.locations.size() * 2, "a title and a grid per location")
	assert_gte(listed.size(), DataRegistry.species.size(), "every species has a card at least once")


func test_has_a_section_per_location_in_location_order() -> void:
	GameState.record_catch("european_sprat")
	_book.open()
	await wait_process_frames(2)

	var north_sea_total := _grid(0).get_child_count()
	assert_eq(_title(0), "North Sea  1 / %d" % north_sea_total)
	assert_string_starts_with(_title(1), "Coral Reef  0 / ")
	var missing: Button = _grid(1).get_child(0)
	assert_eq(_card_name(missing), "???")


func test_species_of_several_locations_show_in_each() -> void:
	GameState.record_catch("ocean_sunfish")
	_book.open()
	await wait_process_frames(2)

	for index in DataRegistry.locations.size():
		var location := DataRegistry.locations[index]
		var names: Array = _grid(index).get_children().map(_card_name)
		var lives_here := ["north_sea", "australia", "japan"].has(location.id)
		assert_eq(names.has("Ocean sunfish"), lives_here, location.id)


func test_details_hide_facts_of_undiscovered_species() -> void:
	_book.open()
	_book._show_detail(DataRegistry.species["conger_eel"])
	assert_eq(_book._detail_name.text, "Not discovered yet")
	assert_false(_book._detail_picture.visible)
	assert_true(_book._detail_unknown.visible)
	assert_eq(_book._detail_rarity.text, "")
	assert_string_contains(_book._detail_facts.text, "North Sea")

	GameState.record_catch("conger_eel")
	_book._show_detail(DataRegistry.species["conger_eel"])
	assert_eq(_book._detail_name.text, "European conger")
	assert_string_contains(_book._detail_fun_fact.text, "three metres")


func test_orders_species_by_first_zone_then_smallest_first() -> void:
	for id: String in ["european_plaice", "atlantic_mackerel", "lumpsucker", "european_sprat"]:
		GameState.record_catch(id)
	_book.open()
	await wait_process_frames(2)

	# Pier shallows: sprat 12 cm, sand eel 20, herring 30, mackerel 40; then sandbanks:
	# lumpsucker 40, plaice 50. Mackerel already lives in the shallows, so it stays there.
	var names: Array = _grid(0).get_children().slice(0, 6).map(_card_name)
	assert_eq(names, ["European sprat", "???", "???", "Atlantic mackerel", "Lumpsucker", "European plaice"])
	var unknown: Button = _grid(0).get_child(1)
	assert_eq(unknown.find_children("*", "FishPicture", true, false).size(), 0, "no silhouette of an unknown species")


func _title(section: int) -> String:
	return (_book._sections.get_child(section * 2) as Label).text


func _grid(section: int) -> GridContainer:
	return _book._sections.get_child(section * 2 + 1)


func _card_name(card: Button) -> String:
	return (card.get_child(0).get_child(1) as Label).text


## A card's picture is wide and low: tall animals (jellyfish, seahorses) must fit by their height.
func test_every_species_fits_inside_its_card_picture() -> void:
	var picture := FishPicture.new()
	picture.size = Vector2(300.0, 160.0)
	autofree(picture)
	for id: String in DataRegistry.species:
		picture.art = FishArt.for_species(DataRegistry.species[id])
		var length := picture.drawn_length()
		assert_true(length <= picture.size.x, "%s is wider than its picture" % id)
		assert_true(picture.art.drawn_height(length) <= picture.size.y + 0.01, "%s is taller than its picture" % id)
