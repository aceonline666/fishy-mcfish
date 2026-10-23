extends GutTest
## Integration tests for the fishing scene: the wader walks where you touch and scoops up fish
## that come within reach of the net; the catch can be sold.

const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")

var _scene: Control
var _wader: Wader
var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state
	GameState.replace_state(PlayerState.new())
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


func test_wader_walks_to_the_touched_spot() -> void:
	var target_screen: Vector2 = _scene.ground_to_scene(_wader.ground_position) + Vector2(180.0, 120.0)
	_touch(target_screen, true)
	_touch(target_screen, false)
	await wait_seconds(1.5)

	var target: Vector2 = _scene.scene_to_ground(target_screen)
	assert_almost_eq(_wader.ground_position.distance_to(target), 0.0, 15.0)
	assert_false(_wader.is_walking())


func test_fish_within_reach_is_scooped_instantly() -> void:
	_scene.spawn_fish("european_sprat", _wader.scoop_center(), 0.0)
	await wait_process_frames(2)

	assert_eq(_scene.fish_count(), 0)
	assert_eq(_scene.live_well.count(), 1)
	assert_eq(GameState.state.species_caught.get("european_sprat"), 1)


func test_fish_out_of_reach_is_not_caught() -> void:
	_scene.spawn_fish("european_sprat", _wader.ground_position + Vector2(-400.0, 0.0), PI)
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


func test_full_bucket_stops_catching() -> void:
	for i: int in _scene.live_well.capacity:
		_scene.live_well.add("european_sprat")
	_scene.spawn_fish("european_sprat", _wader.scoop_center(), 0.0)
	await wait_process_frames(3)

	assert_eq(_scene.fish_count(), 1)
	assert_true(_wader.full)


func test_caught_fish_stack_up_in_the_backpack() -> void:
	_scene.spawn_fish("european_sprat", _wader.scoop_center(), 0.0)
	_scene.spawn_fish("lesser_sand_eel", _wader.scoop_center(), 0.0)
	await wait_process_frames(3)

	assert_eq(_wader.carried.size(), 2)
	assert_eq(_wader.carried.size(), _scene.live_well.count())


func test_walking_onto_the_store_square_moves_the_catch_into_the_tank() -> void:
	_scene.spawn_fish("european_sprat", _wader.scoop_center(), 0.0)
	_scene.spawn_fish("atlantic_herring", _wader.scoop_center(), 0.0)
	await wait_seconds(0.6)
	assert_eq(_scene.live_well.count(), 2)

	_wader.ground_position = _scene.store_zone.ground_center
	await wait_seconds(1.5)

	assert_eq(_scene.live_well.count(), 0)
	assert_eq(_wader.carried.size(), 0)
	assert_eq(GameState.state.tank_fish.size(), 2)
	assert_has(GameState.state.tank_fish, "atlantic_herring")
	assert_eq(GameState.state.money, 0.0, "storing does not sell")


func test_tapping_the_store_square_walks_the_wader_onto_it() -> void:
	var square_screen: Vector2 = _scene.ground_to_scene(_scene.store_zone.ground_center)
	_touch(square_screen, true)
	_touch(square_screen, false)
	await wait_seconds(3.0)
	assert_true(_scene.store_zone.contains(_wader.ground_position), "wader at %s" % _wader.ground_position)


func test_store_square_is_inside_the_walkable_water() -> void:
	assert_true(_scene.area.contains(_scene.store_zone.ground_center, 20.0))
