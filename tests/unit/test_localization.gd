extends GutTest
## Every text the player sees must have a German translation. Texts are found where the game
## translates them: tr("...") and Lang.text("...") in scripts, `text` in scenes, and the
## display columns of the data tables. Fix failures by adding the text to localization/de.po.

const TRANSLATION_FILES: Array[String] = ["res://localization/de.po"]
const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")

var _settings_path := ""


func before_each() -> void:
	_settings_path = Settings.settings_path


func after_each() -> void:
	TranslationServer.set_locale("en")
	Settings.language = ""
	Settings.settings_path = _settings_path


func test_every_shown_text_is_translated() -> void:
	for path in TRANSLATION_FILES:
		var translation: Translation = load(path)
		var missing: Array[String] = []
		for msgid in _shown_texts():
			if translation.get_message(msgid).is_empty():
				missing.append(msgid.c_escape())
		assert_eq(missing, [] as Array[String], "%s lacks translations" % path)


func test_translations_keep_the_placeholders() -> void:
	var placeholder := RegEx.create_from_string("%[sd]")
	for path in TRANSLATION_FILES:
		var translation: Translation = load(path)
		for msgid: StringName in translation.get_message_list():
			var wanted := placeholder.search_all(msgid).map(func(m: RegExMatch) -> String: return m.get_string())
			var found := placeholder.search_all(translation.get_message(msgid)).map(func(m: RegExMatch) -> String: return m.get_string())
			assert_eq(found, wanted, "placeholders of '%s' in %s" % [String(msgid).c_escape(), path])


func test_no_unused_translations() -> void:
	var shown := _shown_texts()
	for path in TRANSLATION_FILES:
		var translation: Translation = load(path)
		var unused: Array[String] = []
		for msgid: StringName in translation.get_message_list():
			if not shown.has(String(msgid)):
				unused.append(String(msgid).c_escape())
		assert_eq(unused, [] as Array[String], "%s has texts the game no longer shows" % path)


func test_german_is_used_when_chosen() -> void:
	Settings.settings_path = "user://test_run/settings.cfg"
	Settings.set_language("de")
	assert_eq(Settings.current_language(), "de")
	assert_eq(tr("Sell fish"), "Fisch verkaufen")
	assert_eq(Lang.text(DataRegistry.species["atlantic_cod"].common_name), "Kabeljau")
	assert_eq(NumberFormat.compact(1234.0), "1,23K")
	Settings.set_language("en")
	assert_eq(Settings.current_language(), "en")
	assert_eq(NumberFormat.compact(1234.0), "1.23K")


func test_the_choice_is_remembered() -> void:
	Settings.settings_path = "user://test_run/settings.cfg"
	Settings.set_language("de")
	TranslationServer.set_locale("en")
	Settings._load()
	assert_eq(Settings.language, "de")
	assert_eq(Settings.current_language(), "de")


func test_the_fishing_screen_switches_language_live() -> void:
	Settings.settings_path = "user://test_run/settings.cfg"
	var scene: Control = FishingSceneFile.instantiate()
	scene.auto_spawn = false
	add_child_autofree(scene)
	await wait_process_frames(2)
	var hint: Label = scene.get_node("%HintLabel")
	assert_eq(hint.text, "Touch and hold to wade there and catch fish.")

	Settings.set_language("de")
	await wait_process_frames(1)
	assert_eq(hint.text, "Tippe und halte, um hinzuwaten und Fische zu fangen.")
	assert_eq(scene.square("store").title, "Fisch einlagern")


#region Finding the shown texts

func _shown_texts() -> Dictionary[String, bool]:
	var texts: Dictionary[String, bool] = {}
	var call := RegEx.create_from_string("(?:\\btr|Lang\\.text)\\(\"((?:[^\"\\\\]|\\\\.)*)\"\\)")
	var scene_text := RegEx.create_from_string("(?m)^text = \"((?:[^\"\\\\]|\\\\.)*)\"")
	for path in _files("res://src"):
		var source := FileAccess.get_file_as_string(path)
		var pattern := call if path.ends_with(".gd") else scene_text if path.ends_with(".tscn") else null
		if pattern == null:
			continue
		for m in pattern.search_all(source):
			texts[m.get_string(1).c_unescape()] = true

	for def: SpeciesDef in DataRegistry.species.values():
		texts[def.common_name] = true
		texts[def.fun_fact] = true
	for def in DataRegistry.zones:
		texts[def.name] = true
	for def in DataRegistry.locations:
		texts[def.name] = true
		texts[def.description] = true
	for def in DataRegistry.achievements:
		texts[def.name] = true
		texts[def.description] = true
	for levels: Array[LevelDef] in [DataRegistry.tank_levels, DataRegistry.tank_slots, DataRegistry.backpack_levels,
			DataRegistry.gear_levels, DataRegistry.net_levels, DataRegistry.drone_levels, DataRegistry.staff_levels,
			DataRegistry.shop_slots]:
		for def in levels:
			texts[def.name] = true
	texts.erase("")
	return texts


func _files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(dir_path):
		found.append(dir_path.path_join(file))
	for dir in DirAccess.get_directories_at(dir_path):
		found.append_array(_files(dir_path.path_join(dir)))
	return found

#endregion
