extends GutTest
## Locations, travel, and the business each location has of its own.

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


func test_the_reef_starts_from_scratch() -> void:
	var state := GameState.state
	var home := state.here()
	home.gear_level = 3
	home.net_level = 2
	home.shop_count = 2
	home.tanks.append(TankState.new(1, 2))
	state.unlocked_locations.append(_reef().id)
	GameState.travel_to(_reef())

	var reef := GameState.here()
	assert_ne(reef, home)
	assert_eq(reef.location_id, _reef().id)
	assert_eq(reef.gear_level, 1, "only the first zone is open")
	assert_eq(reef.net_level, 1, "the smallest net")
	assert_eq(reef.shop_count, 1)
	assert_eq(reef.tanks.size(), 1)
	assert_eq(home.gear_level, 3, "the North Sea keeps its business")


func test_coins_are_shared_and_purchases_are_per_location() -> void:
	var state := GameState.state
	state.unlocked_locations.append(_reef().id)
	GameState.travel_to(_reef())
	GameState.add_money(1000.0)
	GameState.upgrade_net()
	assert_eq(state.here().net_level, 2)
	assert_eq(state.site(DataRegistry.home().id).net_level, 1)
	GameState.travel_to(DataRegistry.home())
	assert_eq(state.money, 1000.0, "the wallet travels along")


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


func test_the_free_tank_and_shop_at_the_reef_do_not_reach_goals() -> void:
	var state := GameState.state
	state.unlocked_locations.append(_reef().id)
	GameState.travel_to(_reef())
	state.here()
	for goal_id: String in ["second_tank", "second_shop"]:
		var goal: AchievementDef = DataRegistry.achievements.filter(func(a: AchievementDef) -> bool: return a.id == goal_id)[0]
		assert_false(Achievements.is_reached(state, goal), goal_id)
