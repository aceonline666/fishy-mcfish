extends GutTest


func test_add_money_tracks_lifetime_earnings() -> void:
	var state := PlayerState.new()
	state.add_money(50.0)
	assert_true(state.try_spend(20.0))
	state.add_money(5.0)
	assert_eq(state.money, 35.0)
	assert_eq(state.total_earned, 55.0)


func test_cannot_overspend_or_spend_negative() -> void:
	var state := PlayerState.new()
	state.add_money(10.0)
	assert_false(state.try_spend(10.01))
	assert_false(state.try_spend(-5.0))
	assert_eq(state.money, 10.0)


func test_survives_json_round_trip() -> void:
	var state := PlayerState.new()
	state.add_money(123.5)
	state.increment_stat("fish_caught", 3)
	state.increment_stat("fish_caught")

	var json := JSON.stringify(state.to_dict())
	var restored := PlayerState.from_dict(JSON.parse_string(json))

	assert_eq(restored.money, 123.5)
	assert_eq(restored.total_earned, 123.5)
	assert_eq(restored.stats.get("fish_caught"), 4)
	assert_typeof(restored.stats["fish_caught"], TYPE_INT)


func test_record_catch_reports_new_species_once() -> void:
	var state := PlayerState.new()
	assert_true(state.record_catch("european_sprat"))
	assert_false(state.record_catch("european_sprat"))
	assert_true(state.record_catch("atlantic_herring"))
	assert_eq(state.species_caught["european_sprat"], 2)
	assert_eq(state.stats["fish_caught"], 3)


func test_record_best_keeps_the_maximum() -> void:
	var state := PlayerState.new()
	state.record_best("best_combo", 3)
	state.record_best("best_combo", 2)
	assert_eq(state.stats["best_combo"], 3)


func test_species_caught_survives_json_round_trip() -> void:
	var state := PlayerState.new()
	state.record_catch("lumpsucker")
	var restored := PlayerState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(restored.species_caught.get("lumpsucker"), 1)
	assert_typeof(restored.species_caught["lumpsucker"], TYPE_INT)


func test_tank_fish_survive_json_round_trip() -> void:
	var state := PlayerState.new()
	state.tank_fish.append("european_sprat")
	state.tank_fish.append("atlantic_mackerel")
	var restored := PlayerState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(restored.tank_fish, ["european_sprat", "atlantic_mackerel"] as Array[String])


func test_from_empty_dict_is_a_new_game() -> void:
	var state := PlayerState.from_dict({})
	assert_eq(state.money, 0.0)
	assert_true(state.stats.is_empty())
