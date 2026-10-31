extends GutTest
## Integration tests for the pier spot: catching with the wader, and the beach aquarium loop
## (store, sell at the shops, building, sellers).

const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")
const Scene := preload("res://src/scenes/fishing/fishing_scene.gd")

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
	_scene.refresh_sell_pad()
	var target: ActionSquare = _scene.square(square_id)
	assert_not_null(target, "square %s is visible" % square_id)
	_wader.ground_position = target.ground_center


## Puts `count` buyers straight into their places in line, waiting at the shop.
func _buyers_waiting(count: int) -> void:
	for i in count:
		_scene.add_buyer()
	for buyer: Customer in _scene._queue:
		buyer.ground_position = buyer.target
	await wait_process_frames(2)


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
	await wait_seconds(1.5)
	_touch(target_screen, false)

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
	GameState.here().tank.level = 2
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

func test_store_square_moves_the_catch_into_the_tank() -> void:
	await _catch(["european_sprat", "atlantic_herring"] as Array[String])
	_stand_on("store")
	await wait_seconds(1.0)

	assert_eq(_scene.live_well.count(), 0)
	assert_eq(_wader.carried.size(), 0)
	assert_eq(GameState.here().tank.fish.size(), 2)
	assert_eq(GameState.state.money, 0.0, "storing does not sell")


func test_fish_the_tank_cannot_hold_slip_through_the_net_but_count() -> void:
	# The glass tank is too small for mackerel (100 L).
	await _catch(["atlantic_mackerel", "european_sprat"] as Array[String])
	assert_eq(_scene.live_well.species_ids, ["european_sprat"] as Array[String], "the mackerel stays in the water")
	assert_true(GameState.state.species_caught.has("atlantic_mackerel"), "but counts as caught")
	assert_eq(Aquarium.tank_needed(DataRegistry.species["atlantic_mackerel"]), 200.0)


func test_the_backpack_stays_at_its_location_and_is_saved() -> void:
	await _catch(["european_sprat", "atlantic_herring"] as Array[String])
	assert_eq(GameState.here().backpack, ["european_sprat", "atlantic_herring"] as Array[String])
	var saved := Site.from_dict("north_sea", GameState.here().to_dict())
	assert_eq(saved.backpack, ["european_sprat", "atlantic_herring"] as Array[String])


func test_sell_square_does_not_sell_the_backpack() -> void:
	await _catch(["european_sprat", "european_sprat"] as Array[String])
	GameState.here().tank.fish.append(TankFish.new("atlantic_herring", 0.5))
	GameState.here().tank.fish.append(TankFish.new("atlantic_herring", 1.0))
	await _buyers_waiting(3)
	_stand_on("sell")
	await wait_seconds(Scene.SELL_INTERVAL_S + 1.5)

	assert_eq(_scene.live_well.count(), 2, "fish in the backpack are too young to sell")
	assert_eq(GameState.state.money, 24.0, "only the grown herring")
	assert_eq(GameState.here().tank.fish.size(), 1, "young fish stay in the tank to grow")


func test_sell_square_then_sells_the_grown_fish_from_the_tank() -> void:
	var tank := GameState.here().tank
	for i in 3:
		tank.fish.append(TankFish.new("atlantic_herring", 1.0))
	tank.fish.append(TankFish.new("european_sprat", 0.0))
	tank.fish.append(TankFish.new("european_sprat", 0.0))
	tank.fish.append(TankFish.new("european_sprat", 0.0))
	await _buyers_waiting(5)
	_stand_on("sell")
	await wait_seconds(Scene.SELL_INTERVAL_S * 3.0 + 1.5)

	assert_eq(tank.fish.size(), 3, "the grown herring are sold, the young sprats stay")
	assert_eq(GameState.state.money, 72.0)


func test_selling_by_hand_takes_one_buyer_at_a_time() -> void:
	var tank := GameState.here().tank
	for i in 9:
		tank.fish.append(TankFish.new("european_sprat", 1.0))
	await _buyers_waiting(5)
	_stand_on("sell")
	await wait_seconds(1.5)
	assert_eq(tank.fish.size(), 8, "the first buyer walks to the player's booth and gets one fish")
	await wait_seconds(Scene.SELL_INTERVAL_S)
	assert_eq(tank.fish.size(), 7, "then the next buyer, after a while")


func test_each_seller_has_a_booth_and_the_line_feeds_the_next_free_one() -> void:
	GameState.here().seller_count = 1
	GameState.replace_state(GameState.state)
	await wait_process_frames(1)
	assert_eq(_scene._booths.size(), 2, "one booth for the player, one for the seller")
	await _buyers_waiting(4)
	await wait_seconds(0.2)
	assert_null(_scene._booths[0], "the player's booth stays empty while the player is away")
	assert_not_null(_scene._booths[1], "the first buyer goes to the seller")
	_stand_on("sell")
	await wait_until(func() -> bool: return _scene._booths[0] != null, 3.0)
	assert_not_null(_scene._booths[0], "the next buyer goes to the player")


func test_selling_waits_for_a_buyer_at_the_counter() -> void:
	GameState.here().tank.fish.append(TankFish.new("european_sprat", 1.0))
	_stand_on("sell")
	await wait_seconds(0.5)
	assert_eq(GameState.here().tank.fish.size(), 1, "nobody has come yet")
	await wait_until(func() -> bool: return GameState.here().tank.fish.is_empty(), 20.0)
	assert_eq(GameState.here().tank.fish.size(), 0, "sold once the first buyer is in line")


func test_buyers_line_up_without_sellers() -> void:
	assert_eq(GameState.here().seller_count, 0)
	assert_gt(_scene._queue_capacity(), 4, "the line may grow past the counters")
	await wait_seconds(8.0)
	assert_gte(_scene._queue.size(), 2, "buyers come from the start")
	var in_line: int = _scene._queue.size()
	GameState.here().tank.fish.append(TankFish.new("atlantic_herring", 1.0))
	await wait_until(func() -> bool: return _scene._queue[0].is_waiting(), 10.0)
	_stand_on("sell")
	await wait_until(func() -> bool: return _scene._booths[0] != null, 3.0)
	var buyer: Customer = _scene._booths[0]
	await wait_until(func() -> bool: return GameState.here().tank.fish.is_empty(), 5.0)
	assert_eq(GameState.here().tank.fish.size(), 0)
	assert_true(buyer.has_fish, "the buyer at the player's booth leaves with the fish")
	assert_gt(in_line, 0)


func test_the_sell_pad_is_greyed_out_until_a_fish_is_grown() -> void:
	await wait_process_frames(1)
	var pad: ActionSquare = _scene.square("sell")
	assert_true(pad.disabled, "grow fish first")
	assert_eq(pad.subtitle, "No grown fish")
	GameState.here().tank.fish.append(TankFish.new("european_sprat", 0.5))
	await wait_process_frames(1)
	assert_true(pad.disabled, "young fish cannot be sold")
	GameState.here().tank.fish[0].growth = 1.0
	await wait_process_frames(1)
	assert_false(pad.disabled)
	assert_eq(pad.subtitle, "1 grown")


func test_paying_a_build_square_upgrades_the_tank() -> void:
	var price := Aquarium.tank_upgrade_cost(GameState.here())
	GameState.add_money(price + 25.0)
	_stand_on("upgrade_tank")
	await wait_seconds(3.0)

	assert_eq(GameState.here().tank.level, 2)
	assert_almost_eq(GameState.state.money, 25.0, 0.01, "the next purchase waits until the wader steps off")
	assert_not_null(_scene.square("upgrade_tank"), "the next level is offered")


func test_partial_payment_is_kept() -> void:
	GameState.add_money(30.0)
	_stand_on("upgrade_tank")
	await wait_seconds(1.5)

	assert_eq(GameState.state.money, 0.0)
	assert_eq(GameState.here().tank.level, 1)
	assert_eq(GameState.here().build_progress.get("upgrade_tank"), 30.0)


func test_bigger_backpack_holds_more_fish() -> void:
	GameState.add_money(Aquarium.backpack_upgrade_cost(GameState.here()))
	_stand_on("upgrade_backpack")
	await wait_seconds(3.0)

	assert_eq(GameState.here().backpack_level, 2)
	assert_eq(_scene.live_well.capacity, int(DataRegistry.backpack_levels[1].capacity))


func test_upgrading_the_shop_makes_room_for_another_seller() -> void:
	GameState.here().seller_count = 1
	GameState.replace_state(GameState.state)
	await wait_process_frames(1)
	assert_null(_scene.square("hire_seller"), "one seller at the fish stall")
	GameState.add_money(Selling.shop_upgrade_cost(GameState.here()))
	_stand_on("upgrade_shop")
	await wait_seconds(3.0)
	assert_eq(GameState.here().shop_level, 2)
	assert_not_null(_scene.square("hire_seller"))


func test_a_hired_seller_sells_grown_fish_on_their_own() -> void:
	GameState.add_money(Selling.next_seller_cost(GameState.here()))
	_stand_on("hire_seller")
	await wait_seconds(3.0)
	assert_eq(GameState.here().seller_count, 1)
	assert_null(_scene.square("hire_seller"), "one seller booth at the fish stall")

	var tank := GameState.here().tank
	for i in 3:
		tank.fish.append(TankFish.new("atlantic_herring", 1.0))
	tank.fish.append(TankFish.new("european_sprat", 0.2))
	var money := GameState.state.money
	GameState._run_sellers(2.0)
	assert_eq(tank.fish.size(), 3, "a seller sells one fish in 2 s")
	assert_eq(GameState.state.money, money + 24.0, "the grown herring")
	GameState._run_sellers(60.0)
	assert_eq(tank.fish.size(), 1, "only the young sprat stays")


func test_the_shop_buys_fish_of_every_zone() -> void:
	var tank := GameState.here().tank
	tank.fish.append(TankFish.new("european_sprat", 1.0))
	tank.fish.append(TankFish.new("european_plaice", 1.0))
	await _buyers_waiting(2)
	_stand_on("sell")
	await wait_seconds(Scene.SELL_INTERVAL_S + 2.0)
	assert_eq(tank.fish.size(), 0)
	assert_eq(GameState.state.money, 75.0 * Economy.GROWN_VALUE_MULT)


func test_a_better_net_lands_big_fish_faster_and_is_wider() -> void:
	var radius := _wader.scoop_radius
	GameState.add_money(Aquarium.net_upgrade_cost(GameState.here()))
	_stand_on("upgrade_net")
	await wait_seconds(3.0)
	assert_eq(GameState.here().net_level, 2)
	assert_gt(_wader.scoop_radius, radius)


func test_deeper_zones_are_closed_without_gear() -> void:
	var shallows := DataRegistry.zones[0]
	var deep_target := Vector2(_wader.ground_position.x, shallows.depth_end + 300.0)
	_touch(_scene.ground_to_scene(deep_target), true)
	await wait_seconds(3.0)
	_touch(_scene.ground_to_scene(deep_target), false)
	assert_lte(_wader.ground_position.y, shallows.depth_end)


func test_wader_walks_no_further_up_the_beach_than_the_pier_end() -> void:
	var top_target := Vector2(_wader.ground_position.x, _scene.BEACH_TOP)
	_touch(_scene.ground_to_scene(top_target), true)
	await wait_seconds(4.0)
	_touch(_scene.ground_to_scene(top_target), false)
	assert_gte(_wader.ground_position.y, _scene.PIER_TOP)


func test_buying_gear_opens_the_next_zone() -> void:
	GameState.add_money(Aquarium.gear_upgrade_cost(GameState.here()))
	_stand_on("upgrade_gear")
	await wait_seconds(3.0)

	assert_eq(GameState.here().gear_level, 2)
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
	assert_gte(fish.ground_position.y, deep.depth_start, "stays behind its buoy line")


func test_fish_behind_a_closed_buoy_line_are_not_caught() -> void:
	var deep := DataRegistry.zones[1]
	assert_gt(deep.gear_level, GameState.here().gear_level)
	# A fish of the closed zone, right in the net (as if the net reached across the line).
	_scene._spawn_fish_in(1, "european_plaice", _wader.scoop_center(), 0.0)
	await wait_process_frames(3)
	assert_eq(_scene.live_well.count(), 0)


func test_beach_decoration_keeps_off_the_pads() -> void:
	# The props are drawn over the pads, so they must not cover them (margin for the sprite).
	for entry: Array in _scene.DECOR:
		for pad: ActionSquare in _scene._squares:
			var covered := Rect2(pad.ground_center - pad.half_extents, pad.half_extents * 2.0).grow(80.0)
			assert_false(covered.has_point(entry[1]), "%s covers the pad %s" % [entry[0], pad.id])


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


func test_a_drone_catches_known_fish_and_brings_them_to_the_tank() -> void:
	_chart_shallows()
	GameState.here().drone_count = 1
	GameState.replace_state(GameState.state)
	await wait_process_frames(1)
	var shallows := DataRegistry.zones[0]
	for i in 3:
		_scene.spawn_fish("european_sprat", Vector2(300.0 + i * 40.0, 200.0), 0.0)
	# Unknown to the player: the drone must leave it alone.
	GameState.state.species_caught.erase("lumpsucker")
	_scene.spawn_fish("lumpsucker", Vector2(200.0, 250.0), 0.0)
	_wader.ground_position = Vector2(1100.0, 400.0)
	# The drone first flies to a random spot of its zone, so the delivery takes a varying time.
	await wait_until(func() -> bool: return GameState.here().tank.fish.size() >= 3, 30.0)

	assert_eq(GameState.here().tank.fish.size(), 3, "three sprats delivered")
	assert_eq(_scene.fish_count(), 1, "the unknown lumpsucker is still swimming")
	assert_eq(_scene._drones[0].zone, shallows)
	assert_eq(_scene._drones[0].capacity, Automation.drone_capacity(0))


func test_the_reef_has_its_own_business_from_scratch() -> void:
	var state := GameState.state
	state.here().shop_level = 2
	state.here().gear_level = 3
	state.unlocked_locations.append("coral_reef")
	state.current_location = "coral_reef"
	var reef: Control = FishingSceneFile.instantiate()
	reef.auto_spawn = false
	add_child_autofree(reef)
	await wait_process_frames(2)

	assert_not_null(reef.square("sell"), "the reef has its own shop")
	assert_eq(GameState.here().shop_level, 1, "a fish stall to start with")
	assert_eq(reef.walk_area.rect.end.y, DataRegistry.zones_in("coral_reef")[0].depth_end, "only the first zone is open")
	var reef_wader: Wader = reef.wader
	reef.spawn_fish("ocellaris_clownfish", reef_wader.scoop_center(), 0.0)
	await wait_seconds(0.5)
	reef_wader.ground_position = reef.square("store").ground_center
	await wait_seconds(1.0)
	var reef_tank := GameState.here().tank
	assert_eq(reef_tank.fish.size(), 1)
	assert_eq(reef_tank.fish[0].species_id, "ocellaris_clownfish")


func test_holding_on_the_store_square_walks_the_wader_onto_it() -> void:
	var store: ActionSquare = _scene.square("store")
	var square_screen: Vector2 = _scene.ground_to_scene(store.ground_center)
	_touch(square_screen, true)
	await wait_seconds(3.0)
	_touch(square_screen, false)
	assert_true(store.contains(_wader.ground_position), "wader at %s" % _wader.ground_position)


func test_the_wader_stops_when_the_finger_lifts() -> void:
	var start := _wader.ground_position
	var target_screen: Vector2 = _scene.ground_to_scene(start + Vector2(0.0, 400.0))
	_touch(target_screen, true)
	await wait_seconds(0.3)
	_touch(target_screen, false)
	var stopped_at := _wader.ground_position
	await wait_seconds(1.0)

	assert_gt(stopped_at.distance_to(start), 20.0, "walked while held")
	assert_lt(_wader.ground_position.distance_to(stopped_at), 8.0, "stands still after a short step")

#endregion
