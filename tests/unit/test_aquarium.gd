extends GutTest
## Tank space, storing, growth, breeding and price rules.


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
	Aquarium.advance(state, 60.0)
	assert_almost_eq(state.here().tank.fish[0].growth, 0.5, 0.001)
	assert_gt(state.site("coral_reef").tank.fish[0].growth, 0.0)
	Aquarium.advance(state, 1000.0)
	assert_eq(state.here().tank.fish[0].growth, 1.0)


func test_a_pair_gets_young() -> void:
	var site := _site_with_tank()
	_fill(site.tank, "european_sprat", 2)
	# One young per pair every BREED_TIME_MULT growth times (sprat: 120 s).
	var breed_time := 120.0 * Aquarium.BREED_TIME_MULT
	assert_eq(Aquarium.breed(site.tank, breed_time * 0.9), 0)
	assert_eq(Aquarium.breed(site.tank, breed_time * 0.1), 1)
	assert_eq(site.tank.fish.size(), 3)
	assert_eq(site.tank.fish[2].growth, 0.0, "young start small")


func test_a_single_fish_does_not_breed() -> void:
	var site := _site_with_tank()
	_fill(site.tank, "european_sprat", 1)
	_fill(site.tank, "atlantic_herring", 1)
	assert_eq(Aquarium.breed(site.tank, 10000.0), 0)


func test_breeding_leaves_room_for_the_catch() -> void:
	var site := _site_with_tank()
	_fill(site.tank, "european_sprat", 2)
	Aquarium.breed(site.tank, 100000.0)
	assert_eq(Aquarium.used_space(site.tank), 60.0 * Aquarium.BREED_FILL, "breeding stops at 80 %")
	assert_not_null(Aquarium.store(site, "european_sprat"), "the rest is for the catch")


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


func test_sellers_sell_grown_fish_and_keep_a_breeding_pair() -> void:
	var state := PlayerState.new_game()
	var site := state.here()
	_fill(site.tank, "european_sprat", 3, 1.0)
	_fill(site.tank, "atlantic_herring", 2, 1.0)
	_fill(site.tank, "lesser_sand_eel", 3, 0.5)
	site.seller_count = 1
	var earned := Selling.run_sellers(state, 600.0)
	assert_eq(earned, Economy.sale_price(DataRegistry.species["european_sprat"], 1.0), "only the third grown sprat")
	assert_eq(site.tank.fish.size(), 7)


func test_the_shop_level_decides_which_fish_it_buys() -> void:
	var site := _site_with_tank()
	_fill(site.tank, "european_plaice", 3, 1.0)
	assert_eq(Selling.best_fish(site), -1, "plaice live in the second zone")
	site.shop_level = 2
	assert_eq(Selling.best_fish(site), 0)
