extends GutTest
## The secret treasure chest (Treasure) and the secret goals.

var _original_state: PlayerState
var _original_clock: Callable


func before_each() -> void:
	_original_state = GameState.state
	_original_clock = GameState.clock_hour
	GameState.clock_hour = func() -> int: return 12
	var state := PlayerState.new_game()
	state.tutorial_step = Tutorial.Step.DONE
	GameState.replace_state(state)


func after_each() -> void:
	GameState.clock_hour = _original_clock
	GameState.replace_state(_original_state)


func _def(id: String) -> AchievementDef:
	for def in DataRegistry.achievements:
		if def.id == id:
			return def
	return null


func _zone(id: String) -> ZoneDef:
	for zone in DataRegistry.zones:
		if zone.id == id:
			return zone
	return null


func test_the_chest_waits_after_the_tutorial_and_comes_back_after_the_cooldown() -> void:
	var state := GameState.state
	assert_true(Treasure.is_ready(state, "north_sea", 1000))
	state.tutorial_step = Tutorial.Step.SELL
	assert_false(Treasure.is_ready(state, "north_sea", 1000), "not during the tutorial")
	state.tutorial_step = Tutorial.Step.DONE
	Treasure.record_find(state, "north_sea", 1000)
	assert_false(Treasure.is_ready(state, "north_sea", 1000 + Treasure.COOLDOWN_S - 1))
	assert_true(Treasure.is_ready(state, "north_sea", 1000 + Treasure.COOLDOWN_S))
	assert_true(Treasure.is_ready(state, "coral_reef", 1000), "each location has its own chest")


func test_the_chest_lies_no_deeper_than_the_fourth_zone() -> void:
	assert_eq(Treasure.zone("north_sea", 1).id, "pier_shallows")
	assert_eq(Treasure.zone("north_sea", 3).id, "wreck")
	assert_eq(Treasure.zone("north_sea", 4).id, "open_sea")
	assert_eq(Treasure.zone("north_sea", 6).id, "open_sea", "not in the dark deep zones")


func test_the_chest_keeps_its_spot_until_it_is_found() -> void:
	var state := GameState.state
	var zone := _zone("pier_shallows")
	var area := PlayArea.new(Rect2(0.0, zone.depth_start, 2160.0, zone.depth_end - zone.depth_start))
	var first := Treasure.spot(state, "north_sea", zone, area)
	assert_eq(Treasure.spot(state, "north_sea", zone, area), first)
	assert_true(area.rect.grow(-Treasure.EDGE_MARGIN).has_point(first))
	Treasure.record_find(state, "north_sea", 1000)
	assert_ne(Treasure.spot(state, "north_sea", zone, area), first, "found chests turn up elsewhere")


func test_every_location_further_on_has_a_bigger_fixed_treasure() -> void:
	assert_eq(Treasure.reward("north_sea"), 10000.0)
	GameState.here().seller_count = 3
	assert_eq(Treasure.reward("north_sea"), 10000.0, "sellers do not change it")
	var previous := 0.0
	for location in DataRegistry.locations:
		assert_gt(Treasure.reward(location.id), previous, location.id)
		previous = Treasure.reward(location.id)
	assert_eq(previous, 5000000.0, "the last location's chest")


func test_finding_the_chest_pays_and_reaches_the_secret_goal() -> void:
	var reward := Treasure.reward("north_sea")
	assert_eq(GameState.find_treasure(), reward)
	assert_has(GameState.state.achievements, "first_chest")
	assert_eq(GameState.state.money, reward + _def("first_chest").reward)
	assert_eq(GameState.state.chest_found_at.keys(), ["north_sea"])


func test_chests_at_every_location_count_once_each() -> void:
	var state := GameState.state
	Treasure.record_find(state, "north_sea", 1000)
	Treasure.record_find(state, "north_sea", 1000 + Treasure.COOLDOWN_S)
	Treasure.record_find(state, "coral_reef", 1000)
	assert_eq(Achievements.progress(state, _def("chest_locations")), 2.0)
	assert_eq(Achievements.progress(state, _def("chests_25")), 3.0)


func test_catches_after_midnight_count_for_the_night_owl() -> void:
	GameState.record_catch("european_sprat")
	assert_false(Achievements.is_reached(GameState.state, _def("night_owl")))
	GameState.clock_hour = func() -> int: return 2
	GameState.record_catch("european_sprat")
	assert_true(Achievements.is_reached(GameState.state, _def("night_owl")))


func test_found_chests_are_saved() -> void:
	Treasure.record_find(GameState.state, "japan", 1234)
	var restored := PlayerState.from_dict(JSON.parse_string(JSON.stringify(GameState.state.to_dict())))
	assert_eq(restored.chest_found_at.get("japan"), 1234)
	assert_typeof(restored.chest_found_at["japan"], TYPE_INT)


func test_secret_goals_stay_secret_until_reached() -> void:
	assert_true(_def("first_chest").hidden)
	assert_false(_def("first_catch").hidden)
	var panel := GoalsPanel.new()
	add_child_autofree(panel)
	panel.open()
	await wait_process_frames(1)
	var texts := _label_texts(panel.content)
	assert_does_not_have(texts, "Treasure hunter")
	assert_has(texts, "???")
	GameState.find_treasure()
	panel.open()
	await wait_process_frames(1)
	assert_has(_label_texts(panel.content), "Treasure hunter")


func _label_texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	for child in node.get_children():
		if child is Label:
			texts.append((child as Label).text)
		texts.append_array(_label_texts(child))
	return texts
