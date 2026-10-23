extends GutTest
## Integration tests for the pier spot: catching with the wader, and the beach aquarium loop
## (store, sell at the shops, building, sellers).

const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")

var _scene: Control
var _wader: Wader
var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state
	var state := PlayerState.new_game()
	# Goal rewards would add coins in the middle of the money checks below.
	for def in DataRegistry.achievements:
		state.achievements.append(def.id)
	GameState.replace_state(state)
	_scene = FishingSceneFile.instantiate()
	_scene.auto_spawn = false
	add_child_autofree(_scene)
	await wait_process_frames(2)
	_wader = _scene.wader


func after_each() -> void:
	GameState.replace_state(_original_state)


func _touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	_scene._gui_input(event)


func _stand_on(square_id: String) -> void:
	var target: ActionSquare = _scene.square(square_id)
	assert_not_null(target, "square %s is visible" % square_id)
	_wader.ground_position = target.ground_center


## Catches fish by placing them in the net and waiting.
func _catch(species_ids: Array[String]) -> void:
	for id in species_ids:
		_scene.spawn_fish(id, _wader.scoop_center(), 0.0)
	await wait_seconds(1.0)


#region Catching

func test_wader_walks_to_the_touched_spot() -> void:
	var target_screen: Vector2 = _scene.ground_to_scene(_wader.ground_position) + Vector2(180.0, 120.0)
	# The camera follows the wader, so convert before it moves.
	var target: Vector2 = _scene.scene_to_ground(target_screen)
	_touch(target_screen, true)
	_touch(target_screen, false)
	await wait_seconds(1.5)

	assert_almost_eq(_wader.ground_position.distance_to(target), 0.0, 15.0)
	assert_false(_wader.is_walking())


func test_fish_within_reach_is_scooped_instantly() -> void:
	_scene.spawn_fish("european_sprat", _wader.scoop_center(), 0.0)
	await wait_process_frames(2)

	assert_eq(_scene.fish_count(), 0)
	assert_eq(_scene.live_well.count(), 1)
	assert_eq(GameState.state.species_caught.get("european_sprat"), 1)


func test_fish_out_of_reach_is_not_caught() -> void:
	_scene.spawn_fish("european_sprat", _wader.ground_position + Vector2(-400.0, 300.0), PI)
	await wait_process_frames(3)
	assert_eq(_scene.fish_count(), 1)


func test_big_fish_must_be_held_before_it_is_caught() -> void:
	_scene.spawn_fish("atlantic_mackerel", _wader.scoop_center(), 0.0)
	await wait_process_frames(3)
	assert_eq(_scene.fish_count(), 1, "caught too early")

	await wait_seconds(1.0)
	assert_eq(_scene.fish_count(), 0)
	assert_eq(_scene.live_well.count(), 1)


func test_quick_successive_catches_build_a_combo() -> void:
	for i in 3:
		_scene.spawn_fish("european_sprat", _wader.scoop_center() + Vector2(i * 10.0, 0.0), 0.0)
	await wait_process_frames(3)

	assert_eq(_scene.live_well.count(), 3)
	assert_eq(GameState.state.stats.get("best_combo"), 3)


func test_full_backpack_stops_catching() -> void:
	for i: int in _scene.live_well.capacity:
		_scene.live_well.add("european_sprat")
	_scene.spawn_fish("european_sprat", _wader.scoop_center(), 0.0)
	await wait_process_frames(3)

	assert_eq(_scene.fish_count(), 1)
	assert_true(_wader.full)


func test_caught_fish_stack_up_in_the_backpack() -> void:
	await _catch(["european_sprat", "lesser_sand_eel"] as Array[String])
	assert_eq(_wader.carried.size(), 2)
	assert_eq(_wader.carried.size(), _scene.live_well.count())

#endregion


#region Beach

func test_store_square_moves_the_catch_into_a_tank() -> void:
	await _catch(["european_sprat", "atlantic_herring"] as Array[String])
	_stand_on("store")
	await wait_seconds(1.0)

	assert_eq(_scene.live_well.count(), 0)
	assert_eq(_wader.carried.size(), 0)
	assert_eq(GameState.state.tanks[0].fish.size(), 2)
	assert_eq(GameState.state.money, 0.0, "storing does not sell")


func test_fish_too_big_for_every_tank_stay_in_the_backpack() -> void:
	# The glass tank is too small for mackerel.
	await _catch(["atlantic_mackerel", "european_sprat"] as Array[String])
	_stand_on("store")
	await wait_seconds(1.0)

	assert_eq(_scene.live_well.species_ids, ["atlantic_mackerel"] as Array[String])
	assert_eq(GameState.state.tanks[0].fish.size(), 1)


func test_sell_square_sells_the_backpack_first() -> void:
	await _catch(["european_sprat", "european_sprat"] as Array[String])
	GameState.state.tanks[0].fish.append(TankFish.new("atlantic_herring", 1.0))
	_stand_on("sell_0")
	await wait_seconds(0.5)

	assert_eq(_scene.live_well.count(), 0)
	assert_eq(GameState.state.money, 10.0)
	assert_eq(GameState.state.tanks[0].fish.size(), 1, "the tanks come after the backpack")


func test_sell_square_then_sells_the_most_valuable_fish_from_the_tanks() -> void:
	var tank := GameState.state.tanks[0]
	tank.fish.append(TankFish.new("european_sprat", 0.0))
	tank.fish.append(TankFish.new("atlantic_herring", 1.0))
	_stand_on("sell_0")
	await wait_seconds(0.2)

	assert_eq(tank.fish.size(), 1)
	assert_eq(tank.fish[0].species_id, "european_sprat", "the grown herring went first")
	assert_eq(GameState.state.money, 24.0)


func test_selling_is_slower_than_storing() -> void:
	for i in 10:
		GameState.state.tanks[0].fish.append(TankFish.new("european_sprat"))
	_stand_on("sell_0")
	await wait_seconds(1.0)
	assert_between(GameState.state.tanks[0].fish.size(), 5, 8)


func test_paying_a_build_square_builds_a_tank() -> void:
	var price := Aquarium.next_tank_cost(GameState.state)
	GameState.add_money(price + 25.0)
	_stand_on("build_tank")
	await wait_seconds(3.0)

	assert_eq(GameState.state.tanks.size(), 2)
	assert_almost_eq(GameState.state.money, 25.0, 0.01, "the next purchase waits until the wader steps off")
	assert_not_null(_scene.square("upgrade_tank_1"), "the new tank can be upgraded")
	assert_not_null(_scene.square("build_tank"), "the next slot can be built")


func test_partial_payment_is_kept() -> void:
	GameState.add_money(30.0)
	_stand_on("build_tank")
	await wait_seconds(1.5)

	assert_eq(GameState.state.money, 0.0)
	assert_eq(GameState.state.tanks.size(), 1)
	assert_eq(GameState.state.build_progress.get("build_tank"), 30.0)


func test_bigger_backpack_holds_more_fish() -> void:
	GameState.add_money(Aquarium.backpack_upgrade_cost(GameState.state))
	_stand_on("upgrade_backpack")
	await wait_seconds(3.0)

	assert_eq(GameState.state.backpack_level, 2)
	assert_eq(_scene.live_well.capacity, int(DataRegistry.backpack_levels[1].capacity))


func test_building_a_second_shop() -> void:
	GameState.add_money(Selling.next_shop_cost(GameState.state))
	_stand_on("build_shop")
	await wait_seconds(3.0)
	assert_eq(GameState.state.shop_count, 2)
	assert_not_null(_scene.square("sell_1"))


func test_hired_sellers_sell_only_grown_fish() -> void:
	GameState.add_money(Selling.next_seller_cost(GameState.state))
	_stand_on("hire_seller")
	await wait_seconds(3.0)
	assert_eq(GameState.state.seller_count, 1)
	assert_null(_scene.square("hire_seller"), "one seller per shop")

	var tank := GameState.state.tanks[0]
	tank.fish.append(TankFish.new("european_sprat", 0.2))
	tank.fish.append(TankFish.new("atlantic_herring", 1.0))
	var money := GameState.state.money
	GameState._run_sellers(30.0)
	assert_eq(tank.fish.size(), 1)
	assert_eq(tank.fish[0].species_id, "european_sprat")
	assert_eq(GameState.state.money, money + 24.0)


func test_a_better_net_lands_big_fish_faster_and_is_wider() -> void:
	var radius := _wader.scoop_radius
	GameState.add_money(Aquarium.net_upgrade_cost(GameState.state))
	_stand_on("upgrade_net")
	await wait_seconds(3.0)
	assert_eq(GameState.state.net_level, 2)
	assert_gt(_wader.scoop_radius, radius)


func test_deeper_zones_are_closed_without_gear() -> void:
	var shallows := DataRegistry.zones[0]
	var deep_target := Vector2(_wader.ground_position.x, shallows.depth_end + 300.0)
	_touch(_scene.ground_to_scene(deep_target), true)
	_touch(_scene.ground_to_scene(deep_target), false)
	await wait_seconds(3.0)
	assert_lte(_wader.ground_position.y, shallows.depth_end)


func test_buying_gear_opens_the_next_zone() -> void:
	GameState.add_money(Aquarium.gear_upgrade_cost(GameState.state))
	_stand_on("upgrade_gear")
	await wait_seconds(3.0)

	assert_eq(GameState.state.gear_level, 2)
	assert_gt(_scene.walk_area.rect.end.y, DataRegistry.zones[0].depth_end)
	assert_eq(_wader.gear_level, 2)


func test_catches_count_towards_charting_their_zone() -> void:
	await _catch(["european_sprat"] as Array[String])
	assert_eq(GameState.state.zone_catches.get(DataRegistry.zones[0].id), 1)


func test_fish_keep_to_their_zone() -> void:
	var deep := DataRegistry.zones[1]
	var fish: SwimmingFish = _scene.spawn_fish("european_plaice", Vector2(600.0, deep.depth_start + 100.0), -PI * 0.5)
	assert_eq(fish.zone, deep)
	await wait_seconds(3.0)
	assert_gte(fish.ground_position.y, deep.depth_start - 120.0, "swims back into its zone")


func _chart_shallows() -> void:
	var shallows := DataRegistry.zones[0]
	for i in Charting.CATCHES_TO_CHART:
		GameState.record_catch("european_sprat", shallows.id)
	for id in Charting.required_species(shallows):
		GameState.record_catch(id, shallows.id)


func test_drones_are_offered_once_a_zone_is_charted() -> void:
	assert_null(_scene.square("buy_drone"))
	_chart_shallows()
	GameState.replace_state(GameState.state)
	await wait_process_frames(1)
	assert_not_null(_scene.square("buy_drone"))


func test_a_drone_catches_known_fish_and_brings_them_to_the_tanks() -> void:
	_chart_shallows()
	GameState.state.drone_count = 1
	GameState.replace_state(GameState.state)
	await wait_process_frames(1)
	var shallows := DataRegistry.zones[0]
	for i in 3:
		_scene.spawn_fish("european_sprat", Vector2(300.0 + i * 40.0, 200.0), 0.0)
	# Unknown to the player: the drone must leave it alone.
	GameState.state.species_caught.erase("lumpsucker")
	_scene.spawn_fish("lumpsucker", Vector2(200.0, 250.0), 0.0)
	_wader.ground_position = Vector2(1100.0, 400.0)
	await wait_seconds(14.0)

	assert_eq(GameState.state.tanks[0].fish.size(), 3, "three sprats delivered")
	assert_eq(_scene.fish_count(), 1, "the unknown lumpsucker is still swimming")
	assert_eq(_scene._drones[0].zone, shallows)


func test_the_reef_dock_ships_the_catch_to_a_tropical_tank_at_home() -> void:
	var state := GameState.state
	state.unlocked_locations.append("coral_reef")
	state.current_location = "coral_reef"
	var tropical := GameState.build_next_tank("tropical")
	var reef: Control = FishingSceneFile.instantiate()
	reef.auto_spawn = false
	add_child_autofree(reef)
	await wait_process_frames(2)

	assert_false(reef.is_home)
	assert_null(reef.square("sell_0"), "no shops away from home")
	assert_not_null(reef.square("sell_dock"))
	var reef_wader: Wader = reef.wader
	reef.spawn_fish("ocellaris_clownfish", reef_wader.scoop_center(), 0.0)
	await wait_seconds(0.5)
	reef_wader.ground_position = reef.square("store").ground_center
	await wait_seconds(1.0)
	assert_eq(tropical.fish.size(), 1)
	assert_eq(tropical.fish[0].species_id, "ocellaris_clownfish")


func test_tapping_the_store_square_walks_the_wader_onto_it() -> void:
	var store: ActionSquare = _scene.square("store")
	var square_screen: Vector2 = _scene.ground_to_scene(store.ground_center)
	_touch(square_screen, true)
	_touch(square_screen, false)
	await wait_seconds(3.0)
	assert_true(store.contains(_wader.ground_position), "wader at %s" % _wader.ground_position)

#endregion
