extends Node
## Device settings that are not game progress: language, sound and music. Kept apart from the
## save file, so starting a new game keeps them.

## Sound or music were switched on or off, or their volume changed.
signal audio_changed

const SETTINGS_PATH := "user://settings.cfg"
## Languages the game is translated into. English is the source language of all texts.
const LANGUAGES: Array[String] = ["en", "de"]
## Audio buses for sound effects and music, created at startup.
const SOUND_BUS := &"Sfx"
const MUSIC_BUS := &"Music"

## Changed by use_sandbox() so tests and tools never touch the player's settings.
var settings_path := SETTINGS_PATH
## The chosen language, or "" to follow the device language.
var language := ""
var sound_on := true
## 0..1
var sound_volume := 1.0
var music_on := true
## 0..1
var music_volume := 0.7


func _ready() -> void:
	for bus: StringName in [SOUND_BUS, MUSIC_BUS]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	_load()
	_apply_audio()


## Redirects the settings to `path` and resets them to the defaults in English, the language
## tests expect.
func use_sandbox(path: String) -> void:
	settings_path = path
	language = ""
	TranslationServer.set_locale("en")
	sound_on = true
	sound_volume = 1.0
	music_on = true
	music_volume = 0.7
	_apply_audio()


## The language shown now: one of LANGUAGES (English for untranslated device languages).
func current_language() -> String:
	var shown := TranslationServer.get_locale().get_slice("_", 0)
	return shown if LANGUAGES.has(shown) else "en"


## Switches the language and remembers the choice. "" follows the device language.
func set_language(code: String) -> void:
	language = code
	TranslationServer.set_locale(code if not code.is_empty() else OS.get_locale())
	_save()


## Switches to the next language; the language button cycles through them.
func cycle_language() -> void:
	set_language(LANGUAGES[(LANGUAGES.find(current_language()) + 1) % LANGUAGES.size()])


func set_sound(on: bool, volume: float) -> void:
	sound_on = on
	sound_volume = clampf(volume, 0.0, 1.0)
	_apply_audio()
	_save()


func set_music(on: bool, volume: float) -> void:
	music_on = on
	music_volume = clampf(volume, 0.0, 1.0)
	_apply_audio()
	_save()


func _apply_audio() -> void:
	_apply_bus(SOUND_BUS, sound_on, sound_volume)
	_apply_bus(MUSIC_BUS, music_on, music_volume)
	audio_changed.emit()


func _apply_bus(bus: StringName, on: bool, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, not on or volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))


func _load() -> void:
	var file := ConfigFile.new()
	if file.load(settings_path) != OK:
		return
	language = str(file.get_value("general", "language", ""))
	if LANGUAGES.has(language):
		TranslationServer.set_locale(language)
	else:
		language = ""
	sound_on = bool(file.get_value("audio", "sound_on", true))
	sound_volume = clampf(float(file.get_value("audio", "sound_volume", 1.0)), 0.0, 1.0)
	music_on = bool(file.get_value("audio", "music_on", true))
	music_volume = clampf(float(file.get_value("audio", "music_volume", 0.7)), 0.0, 1.0)


func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("general", "language", language)
	file.set_value("audio", "sound_on", sound_on)
	file.set_value("audio", "sound_volume", sound_volume)
	file.set_value("audio", "music_on", music_on)
	file.set_value("audio", "music_volume", music_volume)
	var err := file.save(settings_path)
	if err != OK:
		push_error("Saving the settings failed: %s" % error_string(err))
