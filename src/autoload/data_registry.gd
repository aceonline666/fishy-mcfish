extends Node
## Loads all balancing data from CSV files at startup. Read-only afterwards.

const DATA_DIR := "res://data"

var species: Dictionary[String, SpeciesDef] = {}
## Tank sizes, index 0 = level 1.
var tank_levels: Array[LevelDef] = []
## Prices of the beach slots where tanks can be built, index 0 = first slot.
var tank_slots: Array[LevelDef] = []
## Backpack sizes, index 0 = level 1.
var backpack_levels: Array[LevelDef] = []
var errors: PackedStringArray = []


func _ready() -> void:
	load_all(DATA_DIR)
	for message in errors:
		push_error(message)
	assert(errors.is_empty(), "Invalid game data, see errors above.")


func load_all(dir: String) -> void:
	species.clear()
	errors.clear()
	_load_species(dir.path_join("species.csv"))
	tank_levels = _load_levels(dir.path_join("tanks.csv"))
	tank_slots = _load_levels(dir.path_join("tank_slots.csv"))
	backpack_levels = _load_levels(dir.path_join("backpacks.csv"))


func _load_species(path: String) -> void:
	var table := CsvTable.load_file(path)
	errors.append_array(table.errors)
	for i in table.rows.size():
		var where := "%s row %d" % [path, i + 2]
		var def := SpeciesDef.from_row(table.rows[i], errors, where)
		if def == null:
			continue
		if species.has(def.id):
			errors.append("%s: duplicate species id '%s'" % [where, def.id])
			continue
		species[def.id] = def


## Loads a level table. Levels must run 1, 2, 3, ... in order.
func _load_levels(path: String) -> Array[LevelDef]:
	var levels: Array[LevelDef] = []
	var table := CsvTable.load_file(path)
	errors.append_array(table.errors)
	for i in table.rows.size():
		var where := "%s row %d" % [path, i + 2]
		var def := LevelDef.from_row(table.rows[i], errors, where)
		if def == null:
			continue
		if def.level != levels.size() + 1:
			errors.append("%s: expected level %d, got %d" % [where, levels.size() + 1, def.level])
			continue
		levels.append(def)
	if levels.is_empty() and table.errors.is_empty():
		errors.append("%s: no levels" % path)
	return levels
