extends Node
## Loads all balancing data from CSV files at startup. Read-only afterwards.

const DATA_DIR := "res://data"

var species: Dictionary[String, SpeciesDef] = {}
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
