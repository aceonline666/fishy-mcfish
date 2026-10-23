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


func test_every_business_survives_json_round_trip() -> void:
	var state := PlayerState.new_game()
	var home := state.here()
	home.tanks[0].level = 2
	home.tanks[0].fish.append(TankFish.new("european_sprat", 0.25))
	home.tanks.append(TankState.new(1, 1))
	home.backpack_level = 3
	home.net_level = 2
	home.shop_count = 2
	home.seller_count = 1
	home.build_progress["build_tank"] = 20.0
	state.site("coral_reef").drone_count = 1

	var restored := PlayerState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))

	var restored_home := restored.here()
	assert_eq(restored_home.tanks.size(), 2)
	assert_eq(restored_home.tanks[0].level, 2)
	assert_eq(restored_home.tanks[0].fish[0].species_id, "european_sprat")
	assert_eq(restored_home.tanks[0].fish[0].growth, 0.25)
	assert_eq(restored_home.tanks[1].slot, 1)
	assert_eq(restored_home.backpack_level, 3)
	assert_eq(restored_home.net_level, 2)
	assert_eq(restored_home.shop_count, 2)
	assert_eq(restored_home.seller_count, 1)
	assert_eq(restored_home.build_progress["build_tank"], 20.0)
	assert_eq(restored.site("coral_reef").drone_count, 1)


func test_saves_from_before_locations_had_their_own_business() -> void:
	var state := PlayerState.from_dict({
		"gear_level": 3, "net_level": 2, "shop_count": 2, "drone_count": 1,
		"tanks": [
			{"slot": 0, "level": 3, "fish": [{"species": "european_sprat", "growth": 1.0}]},
			{"slot": 1, "level": 1, "fish": []},
			{"slot": 4, "level": 2, "fish": [{"species": "blue_tang", "growth": 0.5}]},
		],
		"build_progress": {"build_tropical_tank": 100.0, "upgrade_net": 50.0},
	})
	var home := state.here()
	assert_eq(home.gear_level, 3)
	assert_eq(home.net_level, 2)
	assert_eq(home.shop_count, 2)
	assert_eq(home.drone_count, 1)
	assert_eq(home.tanks.size(), 2, "the temperate tanks stay at home")
	assert_eq(home.build_progress, {"upgrade_net": 50.0} as Dictionary[String, float])
	var reef := state.site("coral_reef")
	assert_eq(reef.tanks.size(), 1, "the tropical tank moves to the reef")
	assert_eq(reef.tanks[0].slot, 0)
	assert_eq(reef.tanks[0].level, 2)
	assert_eq(reef.tanks[0].fish[0].species_id, "blue_tang")
	assert_eq(reef.gear_level, 1)


func test_prototype_tank_list_moves_into_the_first_tank() -> void:
	var state := PlayerState.from_dict({"tank_fish": ["european_sprat", "atlantic_herring"]})
	var tanks := state.here().tanks
	assert_eq(tanks.size(), 1)
	assert_eq(tanks[0].fish.size(), 2)
	assert_eq(tanks[0].fish[1].species_id, "atlantic_herring")


func test_saves_from_the_visitor_days_keep_their_coins() -> void:
	var state := PlayerState.from_dict({"money": 10.0, "cash_pile": 30.0, "pending_income": 2.0, "has_cashier": true})
	assert_eq(state.money, 42.0)
	assert_eq(state.here().seller_count, 1, "the cashier becomes the first seller")


func test_from_empty_dict_is_a_new_game() -> void:
	var state := PlayerState.from_dict({})
	assert_eq(state.money, 0.0)
	assert_true(state.stats.is_empty())
	assert_eq(state.here().tanks.size(), 1)
	assert_eq(state.here().backpack_level, 1)
