extends GutTest
## The game menu: saving, loading, starting over, sound and music settings, language.

var _menu: GameMenu
var _original_state: PlayerState


func before_each() -> void:
	_original_state = GameState.state
	GameState.replace_state(PlayerState.new_game())
	_menu = GameMenu.new()
	add_child_autofree(_menu)
	_menu.open()


func after_each() -> void:
	Settings.use_sandbox(Settings.settings_path)
	GameState.replace_state(_original_state)


func test_loading_goes_back_to_the_saved_game() -> void:
	GameState.add_money(500.0)
	_menu._on_save()
	assert_false(_menu._load_button.disabled)
	GameState.add_money(1000.0)
	watch_signals(_menu)

	_menu._on_load()
	assert_eq(GameState.state.money, 500.0)
	assert_signal_emitted(_menu, "game_replaced")
	assert_false(_menu.visible)


func test_a_new_game_needs_a_confirmation() -> void:
	GameState.add_money(500.0)
	_menu._new_button.pressed.emit()
	assert_true(_menu._confirm.visible)
	assert_eq(GameState.state.money, 500.0, "nothing happens before confirming")

	_menu._on_new_game_cancelled()
	assert_false(_menu._confirm.visible)
	assert_eq(GameState.state.money, 500.0)

	watch_signals(_menu)
	_menu._on_new_game_asked()
	_menu._on_new_game_confirmed()
	assert_eq(GameState.state.money, PlayerState.new_game().money)
	assert_signal_emitted(_menu, "game_replaced")


func test_sound_can_be_turned_down_and_off() -> void:
	var bus := AudioServer.get_bus_index(Settings.SOUND_BUS)
	_menu._sound_slider.value = 0.5
	assert_eq(Settings.sound_volume, 0.5)
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(bus))

	_menu._sound_toggle.button_pressed = false
	assert_false(Settings.sound_on)
	assert_true(AudioServer.is_bus_mute(bus))
	assert_eq(_menu._sound_toggle.text, "Off")


func test_music_settings_exist_and_are_remembered() -> void:
	_menu._music_slider.value = 0.3
	_menu._music_toggle.button_pressed = false
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index(Settings.MUSIC_BUS)))
	assert_true(Music.player.stream_paused, "the music pauses while off")

	Settings.music_on = true
	Settings.music_volume = 1.0
	Settings._load()
	assert_false(Settings.music_on)
	assert_almost_eq(Settings.music_volume, 0.3, 0.001)


func test_choosing_a_language_rebuilds_the_menu_in_it() -> void:
	_menu._language_buttons["de"].pressed.emit()
	await wait_process_frames(1)
	assert_eq(Settings.current_language(), "de")
	assert_eq(_menu._sound_toggle.text, "An")
	assert_true(_menu._language_buttons["de"].button_pressed)
