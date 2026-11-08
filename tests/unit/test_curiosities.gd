extends GutTest
## Rare finds: when they turn up, where, and that they are kept.


func _state() -> PlayerState:
	var state := PlayerState.new_game()
	state.tutorial_step = Tutorial.Step.DONE
	return state


func _chart(state: PlayerState, zone: ZoneDef) -> void:
	state.zone_catches[zone.id] = Charting.catches_needed(zone)
	for id in Charting.required_species(zone):
		state.species_caught[id] = 1


func test_every_location_has_a_bottle_with_a_letter() -> void:
	for location in DataRegistry.locations:
		var bottle := "bottle_" + location.id
		assert_true(Curiosities.all_ids().has(bottle), location.id)
		assert_false(Curiosities.text(bottle).is_empty())
		assert_eq(Curiosities.find_name(bottle), "Message in a bottle")
		assert_not_null(Curiosities.texture(bottle))


func test_the_bottle_washes_in_once_the_first_zone_is_charted_then_the_item() -> void:
	var state := _state()
	var zones := DataRegistry.zones_in("north_sea")
	assert_eq(Curiosities.waiting(state, "north_sea"), "", "nothing before charting")
	_chart(state, zones[0])
	assert_eq(Curiosities.waiting(state, "north_sea"), "bottle_north_sea")
	Curiosities.record_find(state, "bottle_north_sea")
	assert_eq(Curiosities.waiting(state, "north_sea"), "", "the bell waits for the second zone")
	_chart(state, zones[1])
	assert_eq(Curiosities.waiting(state, "north_sea"), "ships_bell")
	assert_eq(Curiosities.zone("ships_bell"), zones[1])
	Curiosities.record_find(state, "ships_bell")
	assert_eq(Curiosities.waiting(state, "north_sea"), "", "all found")


func test_nothing_turns_up_during_the_tutorial() -> void:
	var state := PlayerState.new_game()
	_chart(state, DataRegistry.zones_in("north_sea")[0])
	assert_eq(Curiosities.waiting(state, "north_sea"), "")


func test_a_find_keeps_its_spot_inside_its_zone() -> void:
	var area := PlayArea.new(Rect2(0.0, 960.0, 2160.0, 960.0))
	var spot := Curiosities.spot("ships_bell", area)
	assert_eq(Curiosities.spot("ships_bell", area), spot)
	assert_true(area.contains(spot))


func test_finds_are_saved() -> void:
	var state := _state()
	Curiosities.record_find(state, "bottle_north_sea")
	Curiosities.record_find(state, "bottle_north_sea")
	var loaded := PlayerState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(loaded.curiosities, ["bottle_north_sea"] as Array[String])
