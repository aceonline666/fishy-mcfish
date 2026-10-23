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
	assert_false(_book._detail_picture.known)

	GameState.record_catch("conger_eel")
	_book._show_detail(DataRegistry.species["conger_eel"])
	assert_eq(_book._detail_name.text, "European conger")
	assert_string_contains(_book._detail_fun_fact.text, "three metres")
