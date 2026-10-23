extends GutTest
## Tank space, storing and growth rules.


func _state_with_tank(level: int = 1) -> PlayerState:
	var state := PlayerState.new()
	state.tanks.append(TankState.new(0, level))
	return state


func _fill(tank: TankState, species_id: String, count: int) -> void:
	for i in count:
		tank.fish.append(TankFish.new(species_id))


func test_store_fills_the_first_tank_with_room() -> void:
	var state := _state_with_tank()
	state.tanks.append(TankState.new(1, 1))
	assert_eq(Aquarium.store(state, "european_sprat"), state.tanks[0])
	# Glass tank: 60 L, sprats take 2 L each.
	_fill(state.tanks[0], "european_sprat", 29)
	assert_eq(Aquarium.used_space(state.tanks[0]), 60.0)
	assert_eq(Aquarium.store(state, "european_sprat"), state.tanks[1])


func test_store_returns_null_when_every_tank_is_full() -> void:
	var state := _state_with_tank()
	_fill(state.tanks[0], "european_sprat", 30)
	assert_null(Aquarium.store(state, "european_sprat"))
	assert_eq(state.tanks[0].fish.size(), 30)


func test_big_species_need_a_big_enough_tank() -> void:
	var state := _state_with_tank(1)
	# Mackerel needs at least 100 L; the glass tank holds 60 L.
	assert_null(Aquarium.store(state, "atlantic_mackerel"))
	state.tanks[0].level = 2
	assert_not_null(Aquarium.store(state, "atlantic_mackerel"))


func test_fish_grow_to_adult_and_stop() -> void:
	var state := _state_with_tank()
	_fill(state.tanks[0], "european_sprat", 1)
	Aquarium.advance(state, 60.0)
	assert_almost_eq(state.tanks[0].fish[0].growth, 0.5, 0.001)
	Aquarium.advance(state, 1000.0)
	assert_eq(state.tanks[0].fish[0].growth, 1.0)


func test_grown_fish_are_worth_three_times_as_much() -> void:
	var sprat := DataRegistry.species["european_sprat"]
	assert_eq(Economy.sale_price(sprat, 1.0), Economy.sale_price(sprat, 0.0) * Economy.GROWN_VALUE_MULT)


func test_tank_value_and_adults_follow_growth() -> void:
	var state := _state_with_tank()
	_fill(state.tanks[0], "european_sprat", 2)
	state.tanks[0].fish[0].growth = 1.0
	assert_eq(Aquarium.adult_count(state), 1)
	var sprat := DataRegistry.species["european_sprat"]
	assert_eq(Aquarium.tank_value(state), Economy.sale_price(sprat, 1.0) + Economy.sale_price(sprat, 0.0))


func test_upgrade_prices_run_out_at_the_top_level() -> void:
	var state := _state_with_tank(1)
	assert_eq(Aquarium.tank_upgrade_cost(state.tanks[0]), DataRegistry.tank_levels[1].cost)
	state.tanks[0].level = DataRegistry.tank_levels.size()
	assert_eq(Aquarium.tank_upgrade_cost(state.tanks[0]), -1.0)
	assert_eq(Aquarium.next_tank_cost(state), DataRegistry.tank_slots[1].cost)
	state.backpack_level = DataRegistry.backpack_levels.size()
	assert_eq(Aquarium.backpack_upgrade_cost(state), -1.0)
