class_name GameMenu
extends OverlayPanel
## The game menu: save, load or start a new game (after a confirmation), sound and music with
## on/off switches and volume sliders, and the language.

## The game state was loaded or started over: the spot must be rebuilt.
signal game_replaced

const SECTION_COLOR := Color(1.0, 0.86, 0.3)
const ON_COLOR := Color(0.55, 1.0, 0.65)
const OFF_COLOR := Color(1.0, 0.6, 0.5)
const DANGER := Color(0.85, 0.25, 0.2)
const KNOB := preload("res://assets/ui/knob.svg")
const FLAGS: Dictionary[String, Texture2D] = {
	"en": preload("res://assets/ui/flag_us.svg"),
	"de": preload("res://assets/ui/flag_de.svg"),
}
## Each language by its own name, so it can be found whatever language is shown.
const LANGUAGE_NAMES: Dictionary[String, String] = {"en": "English", "de": "Deutsch"}

var _load_button: Button
var _new_button: Button
var _confirm: PanelContainer
var _status: Label
var _sound_toggle: Button
var _sound_slider: HSlider
var _music_toggle: Button
var _music_slider: HSlider
var _language_buttons: Dictionary[String, Button] = {}


func _build() -> void:
	content.add_child(_section(tr("Game")))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	content.add_child(buttons)
	var save_button := make_button(tr("Save game"), _on_save)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(save_button)
	_load_button = make_button(tr("Load game"), _on_load)
	_load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_load_button)
	_new_button = make_button(tr("New game"), _on_new_game_asked)
	content.add_child(_new_button)
	_build_confirmation()
	_status = make_label("", 34)
	_status.add_theme_color_override("font_color", ON_COLOR)
	content.add_child(_status)

	content.add_child(_section(tr("Sound")))
	_sound_toggle = _make_toggle(_on_sound_changed)
	_sound_slider = _make_slider(_on_sound_changed)
	content.add_child(_audio_card(tr("Sound effects"), _sound_toggle, _sound_slider, ""))
	_music_toggle = _make_toggle(_on_music_changed)
	_music_slider = _make_slider(_on_music_changed)
	content.add_child(_audio_card(tr("Music"), _music_toggle, _music_slider, ""))

	content.add_child(_section(tr("Language")))
	var languages := HBoxContainer.new()
	languages.add_theme_constant_override("separation", 20)
	content.add_child(languages)
	for code: String in Settings.LANGUAGES:
		var button := make_button(LANGUAGE_NAMES[code], Settings.set_language.bind(code))
		button.icon = FLAGS[code]
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.add_theme_constant_override("icon_max_width", 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		languages.add_child(button)
		_language_buttons[code] = button


func _refresh() -> void:
	set_title(tr("Menu"))
	_load_button.disabled = not SaveSystem.has_save()
	_confirm.hide()
	_new_button.show()
	_status.text = ""
	_sound_slider.set_value_no_signal(Settings.sound_volume)
	_show_toggle(_sound_toggle, Settings.sound_on)
	_music_slider.set_value_no_signal(Settings.music_volume)
	_show_toggle(_music_toggle, Settings.music_on)
	for code in _language_buttons:
		_language_buttons[code].set_pressed_no_signal(code == Settings.current_language())


#region Game

func _on_save() -> void:
	SaveSystem.save_game()
	_load_button.disabled = false
	_status.text = tr("Game saved.")


## Goes back to the last save. The catch in the backpack is not saved and gets lost.
func _on_load() -> void:
	SaveSystem.load_game(false)
	hide()
	game_replaced.emit()


func _on_new_game_asked() -> void:
	_new_button.hide()
	_confirm.show()


func _on_new_game_confirmed() -> void:
	SaveSystem.new_game()
	hide()
	game_replaced.emit()


func _on_new_game_cancelled() -> void:
	_confirm.hide()
	_new_button.show()


## Asks before throwing the game away.
func _build_confirmation() -> void:
	_confirm = PanelContainer.new()
	_confirm.add_theme_stylebox_override("panel", card_style(DANGER.darkened(0.55)))
	_confirm.hide()
	content.add_child(_confirm)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	_confirm.add_child(column)
	column.add_child(make_label(tr("Start over? All progress will be lost."), 36))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	var yes := make_button(tr("Yes, start over"), _on_new_game_confirmed)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(yes)
	var no := make_button(tr("Cancel"), _on_new_game_cancelled)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(no)

#endregion


#region Sound

func _on_sound_changed(_value: Variant = null) -> void:
	Settings.set_sound(_sound_toggle.button_pressed, _sound_slider.value)
	_show_toggle(_sound_toggle, Settings.sound_on)
	Sfx.play(&"coin")


func _on_music_changed(_value: Variant = null) -> void:
	Settings.set_music(_music_toggle.button_pressed, _music_slider.value)
	_show_toggle(_music_toggle, Settings.music_on)


## A card with a name, an on/off switch and a volume slider, and an optional note.
func _audio_card(title: String, toggle: Button, slider: HSlider, note: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	var name_label := make_label(title, 40, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	top.add_child(toggle)
	column.add_child(slider)
	if not note.is_empty():
		var note_label := make_label(note, 28, HORIZONTAL_ALIGNMENT_LEFT)
		note_label.add_theme_color_override("font_color", MUTED)
		column.add_child(note_label)
	return card


func _make_toggle(on_change: Callable) -> Button:
	var toggle := make_button("", func() -> void: pass)
	toggle.toggle_mode = true
	toggle.custom_minimum_size = Vector2(180.0, 90.0)
	toggle.toggled.connect(on_change)
	return toggle


func _show_toggle(toggle: Button, on: bool) -> void:
	toggle.set_pressed_no_signal(on)
	toggle.text = tr("On") if on else tr("Off")
	toggle.add_theme_color_override("font_color", ON_COLOR if on else OFF_COLOR)
	toggle.add_theme_color_override("font_pressed_color", ON_COLOR if on else OFF_COLOR)
	toggle.add_theme_color_override("font_hover_pressed_color", ON_COLOR if on else OFF_COLOR)


## A volume slider from 0 to 1, big enough for a thumb.
func _make_slider(on_change: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(0.0, 64.0)
	slider.add_theme_icon_override("grabber", KNOB)
	slider.add_theme_icon_override("grabber_highlight", KNOB)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.02, 0.07, 0.14)
	track.set_corner_radius_all(10)
	track.content_margin_top = 10.0
	track.content_margin_bottom = 10.0
	slider.add_theme_stylebox_override("slider", track)
	var filled := StyleBoxFlat.new()
	filled.bg_color = Color(0.98, 0.6, 0.18)
	filled.set_corner_radius_all(10)
	filled.content_margin_top = 10.0
	filled.content_margin_bottom = 10.0
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	slider.value_changed.connect(on_change)
	return slider

#endregion


func _section(text: String) -> Label:
	var label := make_label(text, 44, HORIZONTAL_ALIGNMENT_LEFT)
	label.add_theme_color_override("font_color", SECTION_COLOR)
	return label
