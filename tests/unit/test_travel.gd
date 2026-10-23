extends GutTest
## Locations, travel and tropical tanks.

var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state
	GameState.replace_state(PlayerState.new_game())


func after_each() -> void:
	GameState.replace_state(_original_state)


func _reef() -> LocationDef:
	return DataRegistry.location("coral_reef")


func test_home_is_open_and_the_reef_is_locked() -> void:
	var state := GameState.state
	assert_eq(Travel.current(state), DataRegistry.home())
	assert_true(Travel.is_home(state))
	assert_false(Travel.is_unlocked(state, _reef()))
	assert_false(Travel.can_unlock(state, _reef()), "its goal is not reached yet")


func test_reaching_the_goal_and_paying_opens_the_reef() -> void:
	var state := GameState.state
	state.achievements.append(_reef().unlock)
	assert_true(Travel.can_unlock(state, _reef()))
	assert_false(GameState.unlock_location(_reef()), "not enough coins")

	GameState.add_money(_reef().travel_cost)
	assert_true(GameState.unlock_location(_reef()))
	assert_eq(state.money, 0.0)
	GameState.travel_to(_reef())
	assert_eq(Travel.current(state), _reef())
	assert_false(Travel.is_home(state))


func test_tropical_fish_need_a_tropical_tank() -> void:
	var state := GameState.state
	assert_null(Aquarium.store(state, "ocellaris_clownfish"), "the first tank is temperate")
	var tank := GameState.build_next_tank("tropical")
	assert_eq(Aquarium.tank_env(tank), "tropical")
	assert_eq(Aquarium.store(state, "ocellaris_clownfish"), tank)
	assert_eq(Aquarium.store(state, "european_sprat"), state.tanks[0], "temperate fish still go to the temperate tank")


func test_each_environment_has_its_own_slots_and_prices() -> void:
	var state := GameState.state
	var temperate_slot := Aquarium.next_slot(state, "temperate")
	var tropical_slot := Aquarium.next_slot(state, "tropical")
	assert_eq(DataRegistry.tank_slots[temperate_slot].env, "temperate")
	assert_eq(DataRegistry.tank_slots[tropical_slot].env, "tropical")
	assert_eq(Aquarium.next_tank_cost(state, "tropical"), DataRegistry.tank_slots[tropical_slot].cost)


func test_the_map_offers_travel_once_unlocked() -> void:
	var state := GameState.state
	state.achievements.append(_reef().unlock)
	state.unlocked_locations.append(_reef().id)
	var map := WorldMap.new()
	add_child_autofree(map)
	watch_signals(map)
	map.open()
	await wait_process_frames(1)
	assert_eq(map.content.get_child_count(), DataRegistry.locations.size())
