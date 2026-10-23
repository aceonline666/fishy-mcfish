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


func test_aquarium_survives_json_round_trip() -> void:
	var state := PlayerState.new_game()
	state.tanks[0].level = 2
	state.tanks[0].fish.append(TankFish.new("european_sprat", 0.25))
	state.tanks.append(TankState.new(1, 1))
	state.backpack_level = 3
	state.cash_pile = 42.5
	state.pending_income = 1.5
	state.build_progress["build_tank"] = 20.0

	var restored := PlayerState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))

	assert_eq(restored.tanks.size(), 2)
	assert_eq(restored.tanks[0].level, 2)
	assert_eq(restored.tanks[0].fish[0].species_id, "european_sprat")
	assert_eq(restored.tanks[0].fish[0].growth, 0.25)
	assert_eq(restored.tanks[1].slot, 1)
	assert_eq(restored.backpack_level, 3)
	assert_eq(restored.cash_pile, 42.5)
	assert_eq(restored.pending_income, 1.5)
	assert_eq(restored.build_progress["build_tank"], 20.0)


func test_prototype_tank_list_moves_into_the_first_tank() -> void:
	var state := PlayerState.from_dict({"tank_fish": ["european_sprat", "atlantic_herring"]})
	assert_eq(state.tanks.size(), 1)
	assert_eq(state.tanks[0].fish.size(), 2)
	assert_eq(state.tanks[0].fish[1].species_id, "atlantic_herring")


func test_from_empty_dict_is_a_new_game() -> void:
	var state := PlayerState.from_dict({})
	assert_eq(state.money, 0.0)
	assert_true(state.stats.is_empty())
	assert_eq(state.tanks.size(), 1)
	assert_eq(state.backpack_level, 1)
