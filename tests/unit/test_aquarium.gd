extends GutTest
## Tank space, storing, growth and price rules.


func _site_with_tank(level: int = 1, location: String = "north_sea") -> Site:
	var site := Site.create(location)
	site.tanks[0].level = level
	return site


func _fill(tank: TankState, species_id: String, count: int) -> void:
	for i in count:
		tank.fish.append(TankFish.new(species_id))


func test_store_fills_the_first_tank_with_room() -> void:
	var site := _site_with_tank()
	site.tanks.append(TankState.new(1, 1))
	assert_eq(Aquarium.store(site, "european_sprat"), site.tanks[0])
	# Glass tank: 60 L, sprats take 2 L each.
	_fill(site.tanks[0], "european_sprat", 29)
	assert_eq(Aquarium.used_space(site.tanks[0]), 60.0)
	assert_eq(Aquarium.store(site, "european_sprat"), site.tanks[1])


func test_store_returns_null_when_every_tank_is_full() -> void:
	var site := _site_with_tank()
	_fill(site.tanks[0], "european_sprat", 30)
	assert_null(Aquarium.store(site, "european_sprat"))
	assert_eq(site.tanks[0].fish.size(), 30)


func test_big_species_need_a_big_enough_tank() -> void:
	var site := _site_with_tank(1)
	# Mackerel needs at least 100 L; the glass tank holds 60 L.
	assert_null(Aquarium.store(site, "atlantic_mackerel"))
	site.tanks[0].level = 2
	assert_not_null(Aquarium.store(site, "atlantic_mackerel"))


func test_tanks_hold_the_water_of_their_location() -> void:
	assert_null(Aquarium.store(_site_with_tank(), "ocellaris_clownfish"), "no tropical fish in the North Sea tanks")
	var reef := _site_with_tank(1, "coral_reef")
	assert_not_null(Aquarium.store(reef, "ocellaris_clownfish"))
	assert_null(Aquarium.store(reef, "european_sprat"))


func test_fish_grow_to_adult_and_stop_at_every_location() -> void:
	var state := PlayerState.new_game()
	_fill(state.here().tanks[0], "european_sprat", 1)
	_fill(state.site("coral_reef").tanks[0], "ocellaris_clownfish", 1)
	Aquarium.advance(state, 60.0)
	assert_almost_eq(state.here().tanks[0].fish[0].growth, 0.5, 0.001)
	assert_gt(state.site("coral_reef").tanks[0].fish[0].growth, 0.0)
	Aquarium.advance(state, 1000.0)
	assert_eq(state.here().tanks[0].fish[0].growth, 1.0)


func test_grown_fish_are_worth_three_times_as_much() -> void:
	var sprat := DataRegistry.species["european_sprat"]
	assert_eq(Economy.sale_price(sprat, 1.0), Economy.sale_price(sprat, 0.0) * Economy.GROWN_VALUE_MULT)


func test_tank_value_and_adults_follow_growth() -> void:
	var site := _site_with_tank()
	_fill(site.tanks[0], "european_sprat", 2)
	site.tanks[0].fish[0].growth = 1.0
	assert_eq(Aquarium.adult_count(site), 1)
	var sprat := DataRegistry.species["european_sprat"]
	assert_eq(Aquarium.tank_value(site), Economy.sale_price(sprat, 1.0) + Economy.sale_price(sprat, 0.0))


func test_upgrade_prices_run_out_at_the_top_level() -> void:
	var site := _site_with_tank(1)
	assert_eq(Aquarium.tank_upgrade_cost(site, site.tanks[0]), DataRegistry.tank_levels[1].cost)
	site.tanks[0].level = DataRegistry.tank_levels.size()
	assert_eq(Aquarium.tank_upgrade_cost(site, site.tanks[0]), -1.0)
	assert_eq(Aquarium.next_tank_cost(site), DataRegistry.tank_slots[1].cost)
	site.backpack_level = DataRegistry.backpack_levels.size()
	assert_eq(Aquarium.backpack_upgrade_cost(site), -1.0)


func test_building_at_the_reef_costs_more() -> void:
	var home := _site_with_tank()
	var reef := _site_with_tank(1, "coral_reef")
	var factor := DataRegistry.location("coral_reef").price_factor
	assert_gt(factor, 1.0)
	assert_eq(Aquarium.next_tank_cost(reef), Aquarium.next_tank_cost(home) * factor)
	assert_eq(Aquarium.net_upgrade_cost(reef), Aquarium.net_upgrade_cost(home) * factor)
	assert_eq(Selling.next_shop_cost(reef), Selling.next_shop_cost(home) * factor)
	assert_eq(Automation.next_drone_cost(reef), Automation.next_drone_cost(home) * factor)
