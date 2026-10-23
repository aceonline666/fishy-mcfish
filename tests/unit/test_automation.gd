extends GutTest
## Drones and staff rules.

var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state


func after_each() -> void:
	GameState.replace_state(_original_state)


## A state where the shallows are charted.
func _charted_state() -> PlayerState:
	var state := PlayerState.new_game()
	var shallows := DataRegistry.zones[0]
	for i in Charting.CATCHES_TO_CHART:
		state.record_catch("european_sprat", shallows.id)
	for id in Charting.required_species(shallows):
		state.record_catch(id, shallows.id)
	return state


func test_drones_work_in_charted_zones_only() -> void:
	var state := PlayerState.new_game()
	assert_null(Automation.drone_zone(state, 0))
	assert_false(Automation.next_drone_available(state))
	state = _charted_state()
	assert_eq(Automation.drone_zone(state, 0), DataRegistry.zones[0])
	assert_true(Automation.next_drone_available(state))


func test_drone_n_fishes_zone_n() -> void:
	var state := _charted_state()
	assert_null(Automation.drone_zone(state, 1), "the second zone is not charted yet")
	state.drone_count = 1
	assert_false(Automation.next_drone_available(state))

	var sandbanks := DataRegistry.zones[1]
	for i in Charting.catches_needed(sandbanks):
		state.record_catch("atlantic_herring", sandbanks.id)
	for id in Charting.required_species(sandbanks):
		state.record_catch(id, sandbanks.id)
	assert_eq(Automation.drone_zone(state, 0), DataRegistry.zones[0], "the first drone stays in the first zone")
	assert_eq(Automation.drone_zone(state, 1), sandbanks)
	assert_true(Automation.next_drone_available(state))


func test_drones_fish_the_zone_where_the_player_is() -> void:
	var state := _charted_state()
	var lagoon := DataRegistry.zones_in("coral_reef")[0]
	for i in Charting.catches_needed(lagoon):
		state.record_catch("ocellaris_clownfish", lagoon.id)
	for id in Charting.required_species(lagoon):
		state.record_catch(id, lagoon.id)
	assert_eq(Automation.drone_zone(state, 0), DataRegistry.zones[0])
	state.current_location = "coral_reef"
	assert_eq(Automation.drone_zone(state, 0), lagoon)


func test_later_drones_carry_more() -> void:
	assert_gt(Automation.drone_capacity(1), Automation.drone_capacity(0))
	assert_gt(Automation.drone_capacity(2), Automation.drone_capacity(1))


func test_drones_only_take_species_the_player_discovered() -> void:
	var state := PlayerState.new_game()
	state.record_catch("european_sprat")
	assert_true(Automation.drone_can_catch(state, "european_sprat"))
	assert_false(Automation.drone_can_catch(state, "atlantic_herring"))


func test_offline_drones_fill_tanks_up_to_their_space() -> void:
	var state := _charted_state()
	state.drone_count = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var stored := Automation.run_drones_offline(state, 8.0 * 3600.0, rng)

	assert_gt(stored, 0)
	assert_eq(state.tanks[0].fish.size(), stored)
	assert_lte(Aquarium.used_space(state.tanks[0]), Aquarium.capacity(state.tanks[0]))
	for fish in state.tanks[0].fish:
		assert_true(state.species_caught.has(fish.species_id), "only known species")


func test_without_drones_nothing_happens_offline() -> void:
	var state := _charted_state()
	assert_eq(Automation.run_drones_offline(state, 3600.0, RandomNumberGenerator.new()), 0)


func test_drone_prices_run_out() -> void:
	var state := PlayerState.new_game()
	assert_eq(Automation.next_drone_cost(state), DataRegistry.drone_levels[0].cost)
	state.drone_count = DataRegistry.drone_levels.size()
	assert_eq(Automation.next_drone_cost(state), -1.0)
