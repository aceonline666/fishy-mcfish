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


func test_from_empty_dict_is_a_new_game() -> void:
	var state := PlayerState.from_dict({})
	assert_eq(state.money, 0.0)
	assert_true(state.stats.is_empty())
