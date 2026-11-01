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
	assert_null(_store.square("buy_drone"))
	var shallows := DataRegistry.zones[0]
	for i in Charting.CATCHES_TO_CHART:
		GameState.record_catch("european_sprat", shallows.id)
	for id in Charting.required_species(shallows):
		GameState.record_catch(id, shallows.id)
	_store._refresh_squares()
	assert_not_null(_store.square("buy_drone"))


func test_the_door_leads_back_to_the_beach() -> void:
	watch_signals(_store)
	_stand_on("exit")
	await wait_seconds(UpgradeStore.DOOR_DELAY_S + 0.3)
	assert_signal_emitted(_store, "left")


func test_the_upgrades_show_on_the_beach_when_back() -> void:
	_store.queue_free()
	var beach: Control = FishingSceneFile.instantiate()
	beach.auto_spawn = false
	add_child_autofree(beach)
	await wait_process_frames(2)
	watch_signals(beach)
	beach.wader.ground_position = beach.square("gear_shop").ground_center
	await wait_seconds(beach.DOOR_DELAY_S + 0.3)
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
