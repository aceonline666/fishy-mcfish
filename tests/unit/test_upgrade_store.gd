extends GutTest
## Integration tests for the upgrade store: buying upgrades on its pads, and going in and out
## through the gear shop's door on the beach.

const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")

var _store: UpgradeStore
var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state
	var state := PlayerState.new_game()
	# Goal rewards would add coins in the middle of the money checks below.
	for def in DataRegistry.achievements:
		state.achievements.append(def.id)
	GameState.replace_state(state)
	_store = UpgradeStore.new()
	add_child_autofree(_store)
	await wait_process_frames(2)


func after_each() -> void:
	GameState.in_store = false
	GameState.replace_state(_original_state)


func _stand_on(square_id: String) -> void:
	var target := _store.square(square_id)
	assert_not_null(target, "pad %s is visible" % square_id)
	_store.wader.ground_position = target.ground_center


func test_paying_a_pad_upgrades_the_tank() -> void:
	var price := Aquarium.tank_upgrade_cost(GameState.here())
	GameState.add_money(price + 25.0)
	_stand_on("upgrade_tank")
	await wait_seconds(3.0)

	assert_eq(GameState.here().tank.level, 2)
	assert_almost_eq(GameState.state.money, 25.0, 0.01, "the next purchase waits until the wader steps off")
	assert_not_null(_store.square("upgrade_tank"), "the next level is offered")


func test_partial_payment_is_kept() -> void:
	GameState.add_money(30.0)
	_stand_on("upgrade_tank")
	await wait_seconds(1.5)

	assert_eq(GameState.state.money, 0.0)
	assert_eq(GameState.here().tank.level, 1)
	assert_eq(GameState.here().build_progress.get("upgrade_tank"), 30.0)


func test_every_upgrade_can_be_bought() -> void:
	var site := GameState.here()
	GameState.add_money(Aquarium.backpack_upgrade_cost(site) + Aquarium.net_upgrade_cost(site)
			+ Aquarium.gear_upgrade_cost(site) + Selling.shop_upgrade_cost(site))
	for id: String in ["upgrade_backpack", "upgrade_net", "upgrade_gear", "upgrade_shop"]:
		_stand_on(id)
		await wait_seconds(2.5)
		_store.wader.ground_position = UpgradeStore.ENTRY
		await wait_process_frames(2)
	assert_eq(site.backpack_level, 2)
	assert_eq(site.net_level, 2)
	assert_eq(site.gear_level, 2)
	assert_eq(site.shop_level, 2)
	assert_eq(_store.wader.gear_level, 2, "the wader wears the new gear")


func test_drones_are_offered_once_a_zone_is_charted() -> void:
	var drone := _store.square("buy_drone")
	assert_not_null(drone, "shown from the start")
	assert_true(drone.disabled, "but greyed out until its zone is charted")
	GameState.add_money(Automation.next_drone_cost(GameState.here()) * 2.0)
	_stand_on("buy_drone")
	await wait_seconds(1.0)
	assert_eq(GameState.here().drone_count, 0, "a greyed-out pad takes no coins")
	var shallows := DataRegistry.zones[0]
	for i in Charting.CATCHES_TO_CHART:
		GameState.record_catch("european_sprat", shallows.id)
	for id in Charting.required_species(shallows):
		GameState.record_catch(id, shallows.id)
	_store._refresh_squares()
	assert_false(_store.square("buy_drone").disabled)


func test_the_door_leads_back_to_the_beach() -> void:
	watch_signals(_store)
	_store.wader.ground_position = _store._floor.mat().get_center()
	await wait_seconds(UpgradeStore.DOOR_DELAY_S + 0.3)
	assert_signal_emitted(_store, "left")


func test_the_upgrades_show_on_the_beach_when_back() -> void:
	_store.queue_free()
	var beach: Control = FishingSceneFile.instantiate()
	beach.auto_spawn = false
	add_child_autofree(beach)
	await wait_process_frames(2)
	watch_signals(beach)
	var front: float = Grid.rect(beach.GEAR_SHOP_CELL, beach.GEAR_SHOP_SIZE).end.y
	beach.wader.ground_position = Vector2(beach.GEAR_SHOP_DOOR_X + 400.0, front + 10.0)
	await wait_process_frames(2)
	assert_signal_not_emitted(beach, "store_requested", "only the door leads inside")
	assert_gt(beach.wader.ground_position.y, front, "the wall keeps the wader out")
	beach.wader.ground_position = Vector2(beach.GEAR_SHOP_DOOR_X, front + 10.0)
	await wait_process_frames(2)
	assert_signal_emitted(beach, "store_requested")

	GameState.here().backpack_level = 2
	GameState.here().net_level = 2
	beach.return_from_store()
	assert_eq(beach.live_well.capacity, int(DataRegistry.backpack_levels[1].capacity))
	assert_gt(beach.wader.scoop_radius, Wader.SCOOP_RADIUS)
	assert_null(beach._square_under_wader(), "back in front of the door, not on it")


func test_the_beach_drones_keep_fishing_while_the_player_is_in_the_store() -> void:
	var shallows := DataRegistry.zones[0]
	for i in Charting.CATCHES_TO_CHART:
		GameState.record_catch("european_sprat", shallows.id)
	for id in Charting.required_species(shallows):
		GameState.record_catch(id, shallows.id)
	GameState.here().drone_count = 1
	GameState.in_store = true
	# One fish per call; a catch the glass tank cannot hold is lost.
	for i in 20:
		GameState._run_remote_drones(1.0 / Automation.OFFLINE_DRONE_FISH_PER_SECOND)
	assert_gt(GameState.here().tank.fish.size(), 0)


#region Tutorial

func test_on_the_first_visit_a_tip_over_each_pad_says_what_it_is_for() -> void:
	GameState.state.tutorial_step = Tutorial.Step.SHOP
	await wait_process_frames(2)
	assert_eq(_store.tutorial.message_title(), "Welcome to the gear shop!")
	var tips := _store.tutorial.tip_texts()
	assert_has(tips, "More fish at once")
	assert_eq(tips.size(), _store._squares.filter(func(s: ActionSquare) -> bool: return s.visible and s.kind == ActionSquare.Kind.BUY).size(), "one per pad")

	GameState.add_money(Aquarium.backpack_upgrade_cost(GameState.here()))
	_stand_on("upgrade_backpack")
	await wait_seconds(2.0)
	assert_eq(GameState.state.tutorial_step, Tutorial.Step.HIRE, "buying something ends the shop's tips")
	assert_eq(_store.tutorial.message_title(), "")
	assert_eq(_store.tutorial.tip_texts(), [] as Array[String])


func test_leaving_the_gear_shop_ends_its_tips() -> void:
	GameState.state.tutorial_step = Tutorial.Step.SHOP
	_store.left.emit()
	assert_eq(GameState.state.tutorial_step, Tutorial.Step.HIRE)


func test_no_tips_once_the_tutorial_is_done() -> void:
	GameState.state.tutorial_step = Tutorial.Step.DONE
	await wait_process_frames(2)
	assert_eq(_store.tutorial.tip_texts(), [] as Array[String])

#endregion


func test_the_travel_pad_opens_the_next_beach_and_goes_there() -> void:
	var reef := DataRegistry.location("coral_reef")
	GameState.add_money(reef.travel_cost)
	watch_signals(_store)
	_stand_on("travel_next")
	await wait_seconds(2.5)
	assert_true(GameState.state.unlocked_locations.has("coral_reef"))
	assert_eq(GameState.state.current_location, "coral_reef")
	assert_eq(GameState.state.money, 0.0, "the travel fee was paid")
	assert_signal_emitted(_store, "travelled")


func test_the_travel_pad_is_free_once_the_beach_is_open() -> void:
	GameState.state.unlocked_locations.append("coral_reef")
	_store._refresh_squares()
	watch_signals(_store)
	_stand_on("travel_next")
	await wait_process_frames(3)
	assert_eq(GameState.state.current_location, "coral_reef")
	assert_signal_emitted(_store, "travelled")


func test_the_travel_pad_waits_for_the_goal() -> void:
	var reef := DataRegistry.location("coral_reef")
	GameState.state.achievements.erase(reef.unlock)
	_store._refresh_squares()
	assert_true(_store.square("travel_next").disabled)
	GameState.add_money(reef.travel_cost)
	_stand_on("travel_next")
	await wait_seconds(1.0)
	assert_eq(GameState.state.money, reef.travel_cost, "no coins taken")
	assert_false(GameState.state.unlocked_locations.has("coral_reef"))


func test_there_is_no_travel_pad_at_the_last_beach() -> void:
	GameState.state.current_location = DataRegistry.locations[-1].id
	_store._refresh_squares()
	assert_null(_store.square("travel_next"))
