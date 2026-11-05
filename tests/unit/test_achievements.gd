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
	assert_eq(Achievements.progress(state, _def("all_locations")), 1.0, "the home beach is always open")
	state.unlocked_locations.append("coral_reef")
	assert_eq(Achievements.progress(state, _def("all_locations")), 2.0)


func test_panel_lists_every_goal() -> void:
	var panel := GoalsPanel.new()
	add_child_autofree(panel)
	panel.open()
	await wait_process_frames(1)
	assert_eq(panel.content.get_child_count(), DataRegistry.achievements.size())


func test_banner_celebrates_goals_one_after_the_other() -> void:
	var banner := GoalBanner.new()
	banner.size = Vector2(1080.0, 1920.0)
	add_child_autofree(banner)
	banner.celebrate(_def("first_catch"))
	banner.celebrate(_def("combo_3"))
	var cards := banner.get_children().filter(func(child: Node) -> bool: return child is PanelContainer)
	assert_eq(cards.size(), 1, "the second goal waits for the first")
	assert_true(banner.is_showing())
	await wait_seconds(GoalBanner.POP_IN_S + GoalBanner.HOLD_S + GoalBanner.LEAVE_S + 0.2)
	cards = banner.get_children().filter(func(child: Node) -> bool: return child is PanelContainer and not child.is_queued_for_deletion())
	assert_eq(cards.size(), 1, "then the second one shows")
	await wait_seconds(GoalBanner.POP_IN_S + GoalBanner.HOLD_S + GoalBanner.LEAVE_S + 0.2)
	assert_false(banner.is_showing())


func test_welcome_back_card_shows_the_money_big_and_waits_for_a_tap() -> void:
	var banner := GoalBanner.new()
	banner.size = Vector2(1080.0, 1920.0)
	add_child_autofree(banner)
	banner.welcome_back(1_390_000.0, 12)
	var texts := _card_texts(banner)
	assert_has(texts, "1.3 million coins")
	assert_has(texts, "Your drones caught 12 fish.")
	await wait_seconds(GoalBanner.POP_IN_S + GoalBanner.HOLD_S + GoalBanner.LEAVE_S + 0.2)
	assert_true(banner.is_showing(), "stays until tapped")
	assert_eq(banner.mouse_filter, Control.MOUSE_FILTER_STOP, "catches the tap")
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	banner._gui_input(tap)
	assert_eq(banner.mouse_filter, Control.MOUSE_FILTER_IGNORE, "lets touches through again")
	await wait_seconds(GoalBanner.LEAVE_S + 0.2)
	assert_false(banner.is_showing())


func test_no_welcome_back_card_without_earnings() -> void:
	var banner := GoalBanner.new()
	add_child_autofree(banner)
	banner.welcome_back(0.0, 0)
	assert_false(banner.is_showing())


func _card_texts(banner: GoalBanner) -> Array[String]:
	var texts: Array[String] = []
	for label in banner.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	return texts
