extends GutTest
## Tank space, storing, growth and price rules.


func _site_with_tank(level: int = 1, location: String = "north_sea") -> Site:
	var site := Site.create(location)
	site.tank.level = level
	return site


func _fill(tank: TankState, species_id: String, count: int, growth: float = 0.0) -> void:
	for i in count:
		tank.fish.append(TankFish.new(species_id, growth))


func test_store_fills_the_tank_until_it_is_full() -> void:
	var site := _site_with_tank()
	assert_eq(Aquarium.store(site, "european_sprat"), site.tank)
	# Glass tank: 60 L, sprats take 2 L each.
	_fill(site.tank, "european_sprat", 29)
	assert_eq(Aquarium.used_space(site.tank), 60.0)
	assert_null(Aquarium.store(site, "european_sprat"))
	assert_eq(site.tank.fish.size(), 30)


func test_big_species_need_a_big_enough_tank() -> void:
	var site := _site_with_tank(1)
	# Mackerel needs at least 100 L; the glass tank holds 60 L.
	assert_null(Aquarium.store(site, "atlantic_mackerel"))
	site.tank.level = 2
	assert_not_null(Aquarium.store(site, "atlantic_mackerel"))


func test_tanks_hold_the_water_of_their_location() -> void:
	assert_null(Aquarium.store(_site_with_tank(), "ocellaris_clownfish"), "no tropical fish in the North Sea tank")
	var reef := _site_with_tank(1, "coral_reef")
	assert_not_null(Aquarium.store(reef, "ocellaris_clownfish"))
	assert_null(Aquarium.store(reef, "european_sprat"))


func test_fish_grow_to_adult_and_stop_at_every_location() -> void:
	var state := PlayerState.new_game()
	_fill(state.here().tank, "european_sprat", 1)
	_fill(state.site("coral_reef").tank, "ocellaris_clownfish", 1)
	# Sprats grow up in 30 s.
	Aquarium.advance(state, 15.0)
	assert_almost_eq(state.here().tank.fish[0].growth, 0.5, 0.001)
	assert_gt(state.site("coral_reef").tank.fish[0].growth, 0.0)
	Aquarium.advance(state, 1000.0)
	assert_eq(state.here().tank.fish[0].growth, 1.0)


func test_bigger_tanks_grow_fish_faster() -> void:
	var state := PlayerState.new_game()
	var tank := state.here().tank
	_fill(tank, "european_sprat", 1)
	tank.level = 2
	assert_gt(Aquarium.growth_speed(tank), 1.0)
	Aquarium.advance(state, 15.0)
	assert_almost_eq(tank.fish[0].growth, 0.5 * Aquarium.growth_speed(tank), 0.001)
	for level in range(2, DataRegistry.tank_levels.size() + 1):
		assert_gt(DataRegistry.tank_levels[level - 1].speed, DataRegistry.tank_levels[level - 2].speed)


func test_the_next_fish_to_grow_and_its_time() -> void:
	var site := _site_with_tank()
	assert_null(Aquarium.next_to_grow(site.tank))
	_fill(site.tank, "atlantic_herring", 1, 0.9)
	_fill(site.tank, "european_sprat", 1, 0.5)
	_fill(site.tank, "european_sprat", 1, 1.0)
	var next := Aquarium.next_to_grow(site.tank)
	assert_eq(next.species_id, "atlantic_herring", "4.5 s left beats the sprat's 15 s")
	assert_almost_eq(Aquarium.seconds_to_grow(site.tank, next), 4.5, 0.001)


func test_some_caught_fish_are_already_grown() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var grown := 0
	var young := 0
	for i in 1000:
		var growth := Aquarium.catch_growth(rng)
		assert_between(growth, 0.0, 1.0)
		if growth >= 1.0:
			grown += 1
		elif growth < 0.5:
			young += 1
	assert_between(grown, 70, 130, "about one in ten")
	assert_gt(young, 400, "most are young")


func test_fish_do_not_breed() -> void:
	var state := PlayerState.new_game()
	_fill(state.here().tank, "european_sprat", 4)
	Aquarium.advance(state, 100000.0)
	assert_eq(state.here().tank.fish.size(), 4, "the tank only holds what was stored")


func test_the_tank_is_full_when_not_even_the_smallest_fish_fits() -> void:
	var site := _site_with_tank()
	assert_eq(Aquarium.smallest_space("temperate"), 2.0, "the sprat")
	assert_false(Aquarium.is_full(site))
	_fill(site.tank, "atlantic_herring", 11)
	assert_eq(Aquarium.used_space(site.tank), 55.0)
	assert_false(Aquarium.is_full(site), "a sprat still fits")
	_fill(site.tank, "european_sprat", 2)
	assert_true(Aquarium.is_full(site))
	assert_eq(Aquarium.fill_share(site.tank), 59.0 / 60.0)


func test_grown_fish_are_worth_three_times_as_much() -> void:
	var sprat := DataRegistry.species["european_sprat"]
	assert_eq(Economy.sale_price(sprat, 1.0), Economy.sale_price(sprat, 0.0) * Economy.GROWN_VALUE_MULT)


func test_tank_value_and_adults_follow_growth() -> void:
	var site := _site_with_tank()
	_fill(site.tank, "european_sprat", 2)
	site.tank.fish[0].growth = 1.0
	assert_eq(Aquarium.adult_count(site), 1)
	var sprat := DataRegistry.species["european_sprat"]
	assert_eq(Aquarium.tank_value(site), Economy.sale_price(sprat, 1.0) + Economy.sale_price(sprat, 0.0))


func test_bigger_shops_have_booths_for_more_sellers() -> void:
	var site := _site_with_tank()
	assert_eq(Selling.seller_slots(site), 1)
	site.seller_count = 1
	assert_eq(Selling.next_seller_cost(site), -1.0, "the fish stall is full")
	site.shop_level = DataRegistry.shop_levels.size()
	assert_eq(Selling.seller_slots(site), 15, "the seafood palace")
	assert_eq(Selling.next_seller_cost(site), DataRegistry.staff_levels[1].cost)
	site.seller_count = 15
	assert_eq(Selling.next_seller_cost(site), -1.0)


func test_upgrade_prices_run_out_at_the_top_level() -> void:
	var site := _site_with_tank(1)
	assert_eq(Aquarium.tank_upgrade_cost(site), DataRegistry.tank_levels[1].cost)
	site.tank.level = DataRegistry.tank_levels.size()
	assert_eq(Aquarium.tank_upgrade_cost(site), -1.0)
	site.backpack_level = DataRegistry.backpack_levels.size()
	assert_eq(Aquarium.backpack_upgrade_cost(site), -1.0)
	site.shop_level = DataRegistry.shop_levels.size()
	assert_eq(Selling.shop_upgrade_cost(site), -1.0)


func test_building_at_the_reef_costs_more() -> void:
	var home := _site_with_tank()
	var reef := _site_with_tank(1, "coral_reef")
	var factor := DataRegistry.location("coral_reef").price_factor
	assert_gt(factor, 1.0)
	assert_eq(Aquarium.tank_upgrade_cost(reef), Aquarium.tank_upgrade_cost(home) * factor)
	assert_eq(Aquarium.net_upgrade_cost(reef), Aquarium.net_upgrade_cost(home) * factor)
	assert_eq(Selling.shop_upgrade_cost(reef), Selling.shop_upgrade_cost(home) * factor)
	assert_eq(Automation.next_drone_cost(reef), Automation.next_drone_cost(home) * factor)


func test_sellers_sell_every_grown_fish_first_grown_first() -> void:
	var state := PlayerState.new_game()
	var site := state.here()
	_fill(site.tank, "european_sprat", 3, 1.0)
	_fill(site.tank, "atlantic_herring", 2, 1.0)
	_fill(site.tank, "lesser_sand_eel", 3, 0.5)
	assert_eq(site.tank.fish[Selling.next_to_sell(site)].species_id, "european_sprat", "not the more valuable herring")
	site.seller_count = 1
	var earned := Selling.run_sellers(state, 600.0)
	var sprat := DataRegistry.species["european_sprat"]
	var herring := DataRegistry.species["atlantic_herring"]
	assert_eq(earned, 3.0 * Economy.sale_price(sprat, 1.0) + 2.0 * Economy.sale_price(herring, 1.0))
	assert_eq(site.tank.fish.size(), 3, "only the young eels stay")
	assert_eq(Selling.next_to_sell(site), -1)


func test_a_fish_that_grows_up_queues_behind_the_grown_fish() -> void:
	var state := PlayerState.new_game()
	var site := state.here()
	_fill(site.tank, "atlantic_herring", 1, 0.9)
	_fill(site.tank, "european_sprat", 1, 1.0)
	_fill(site.tank, "lesser_sand_eel", 1, 0.95)
	Aquarium.advance(state, 3600.0)
	var order: Array[String] = []
	for fish in site.tank.fish:
		order.append(fish.species_id)
	# The sprat was grown already; the eel and the herring follow in the order they grew up.
	assert_eq(order[0], "european_sprat")
	var eel_first := Aquarium.seconds_to_grow(site.tank, TankFish.new("lesser_sand_eel", 0.95)) 			< Aquarium.seconds_to_grow(site.tank, TankFish.new("atlantic_herring", 0.9))
	assert_eq(order.slice(1), (["lesser_sand_eel", "atlantic_herring"] if eel_first else ["atlantic_herring", "lesser_sand_eel"]) as Array[String])
	assert_eq(site.tank.fish[Selling.next_to_sell(site)].species_id, "european_sprat")
