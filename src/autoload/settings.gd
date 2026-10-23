extends Node
## Device settings that are not game progress, for now the language. Kept apart from the
## save file, so starting a new game keeps them.

const SETTINGS_PATH := "user://settings.cfg"
## Languages the game is translated into. English is the source language of all texts.
const LANGUAGES: Array[String] = ["en", "de"]

## Changed by use_sandbox() so tests and tools never touch the player's settings.
var settings_path := SETTINGS_PATH
## The chosen language, or "" to follow the device language.
var language := ""


func _ready() -> void:
	_load()


## Redirects the settings to `path` and shows English, the language tests expect.
func use_sandbox(path: String) -> void:
	settings_path = path
	language = ""
	TranslationServer.set_locale("en")


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


func _load() -> void:
	var file := ConfigFile.new()
	if file.load(settings_path) != OK:
		return
	language = str(file.get_value("general", "language", ""))
	if LANGUAGES.has(language):
		TranslationServer.set_locale(language)
	else:
		language = ""


func _save() -> void:
	var file := ConfigFile.new()
	file.set_value("general", "language", language)
	var err := file.save(settings_path)
	if err != OK:
		push_error("Saving the settings failed: %s" % error_string(err))
