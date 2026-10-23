extends GutTest
## Goals: progress, rewards and the panel.

var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state
	GameState.replace_state(PlayerState.new_game())


func after_each() -> void:
	GameState.replace_state(_original_state)


func _def(id: String) -> AchievementDef:
	for def in DataRegistry.achievements:
		if def.id == id:
			return def
	return null


func test_shipped_goals_are_valid() -> void:
	assert_gt(DataRegistry.achievements.size(), 5)
	for def in DataRegistry.achievements:
		if def.type == "charted":
			assert_true(DataRegistry.zones.any(func(z: ZoneDef) -> bool: return z.id == def.param), def.id)


func test_first_catch_pays_once() -> void:
	GameState.record_catch("european_sprat")
	watch_signals(EventBus)
	GameState.check_achievements()
	assert_has(GameState.state.achievements, "first_catch")
	assert_eq(GameState.state.money, _def("first_catch").reward)
	assert_signal_emitted(EventBus, "achievement_reached")

	GameState.check_achievements()
	assert_eq(GameState.state.money, _def("first_catch").reward, "no second payout")


func test_progress_measures_the_right_things() -> void:
	var state := GameState.state
	state.record_best("best_combo", 4)
	assert_eq(Achievements.progress(state, _def("combo_3")), 4.0)
	state.record_catch("atlantic_cod")
	assert_eq(Achievements.progress(state, _def("first_rare")), 1.0)
	assert_eq(Achievements.progress(state, _def("first_epic")), 0.0)
	assert_eq(Achievements.progress(state, _def("chart_shallows")), 0.0)


func test_panel_lists_every_goal() -> void:
	var panel := GoalsPanel.new()
	add_child_autofree(panel)
	panel.open()
	await wait_process_frames(1)
	assert_eq(panel.content.get_child_count(), DataRegistry.achievements.size())
