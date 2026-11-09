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
	assert_eq(_book._grid.get_child_count(), DataRegistry.species.size())
	assert_string_contains(_book._title.text, "2 / %d" % DataRegistry.species.size())


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


func test_lists_caught_species_first_in_the_order_they_were_found() -> void:
	GameState.record_catch("atlantic_cod")
	GameState.record_catch("european_sprat")
	GameState.record_catch("atlantic_cod")
	_book.open()
	await wait_process_frames(2)

	var first: Button = _book._grid.get_child(0)
	var second: Button = _book._grid.get_child(1)
	var third: Button = _book._grid.get_child(2)
	assert_eq(_card_name(first), "Atlantic cod")
	assert_eq(_card_name(second), "European sprat")
	assert_eq(_card_name(third), "???")
	assert_eq(third.find_children("*", "FishPicture", true, false).size(), 0, "no silhouette of an unknown species")


func _card_name(card: Button) -> String:
	return (card.get_child(0).get_child(1) as Label).text
