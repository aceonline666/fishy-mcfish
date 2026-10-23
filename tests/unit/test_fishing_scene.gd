extends GutTest
## Integration tests for the fishing scene: the net catches fish it touches and the catch can be sold.

const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")

var _scene: Control
var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state
	GameState.replace_state(PlayerState.new())
	_scene = FishingSceneFile.instantiate()
	_scene.auto_spawn = false
	add_child_autofree(_scene)
	await wait_process_frames(1)


func after_each() -> void:
	GameState.replace_state(_original_state)


func _center() -> Vector2:
	return _scene.size * 0.5


func _touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	_scene._gui_input(event)


func test_touching_a_small_fish_catches_it_instantly() -> void:
	_scene.spawn_fish("european_sprat", _center(), 0.0)
	_touch(_center(), true)
	await wait_process_frames(2)
	_touch(_center(), false)

	assert_eq(_scene.fish_count(), 0)
	assert_eq(_scene.live_well.count(), 1)
	assert_eq(GameState.state.species_caught.get("european_sprat"), 1)


func test_big_fish_must_be_held_before_it_is_caught() -> void:
	_scene.spawn_fish("atlantic_mackerel", _center(), 0.0)
	_touch(_center(), true)
	await wait_process_frames(3)
	assert_eq(_scene.fish_count(), 1, "caught too early")

	await wait_seconds(1.0)
	_touch(_center(), false)
	assert_eq(_scene.fish_count(), 0)
	assert_eq(_scene.live_well.count(), 1)


func test_several_fish_in_one_drag_count_as_a_combo() -> void:
	for i in 3:
		_scene.spawn_fish("european_sprat", _center() + Vector2(i * 20.0, 0.0), 0.0)
	_touch(_center(), true)
	await wait_process_frames(2)
	_touch(_center(), false)

	assert_eq(_scene.live_well.count(), 3)
	assert_eq(GameState.state.stats.get("best_combo"), 3)


func test_full_live_well_stops_catching() -> void:
	for i: int in _scene.live_well.capacity:
		_scene.live_well.add("european_sprat")
	_scene.spawn_fish("european_sprat", _center(), 0.0)
	_touch(_center(), true)
	await wait_process_frames(3)
	_touch(_center(), false)

	assert_eq(_scene.fish_count(), 1)
	assert_true(_scene.live_well.is_full())


func test_selling_turns_the_catch_into_money() -> void:
	_scene.live_well.add("european_sprat")
	_scene.live_well.add("atlantic_mackerel")
	var sell_button: Button = _scene.get_node("%SellButton")
	sell_button.pressed.emit()

	assert_eq(GameState.state.money, 5.0 + 60.0)
	assert_eq(_scene.live_well.count(), 0)
