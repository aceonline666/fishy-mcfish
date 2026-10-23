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
## Diving gear, index 0 = level 1 (waders).
var gear_levels: Array[LevelDef] = []
## Fishing drones: level n is the n-th drone; capacity = fish it carries per trip.
var drone_levels: Array[LevelDef] = []
## Sellers: level n is the n-th seller; capacity = adult fish sold per minute.
var staff_levels: Array[LevelDef] = []
## Hand nets: capacity = how much faster big fish are landed.
var net_levels: Array[LevelDef] = []
## Prices of the shops on the beach, index 0 = the first (free) shop.
var shop_slots: Array[LevelDef] = []
## Places to fish, home first.
var locations: Array[LocationDef] = []
## Depth zones of all locations, grouped by location and ordered from the shore outwards.
var zones: Array[ZoneDef] = []
## Goals, in the order shown.
var achievements: Array[AchievementDef] = []
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
	gear_levels = _load_levels(dir.path_join("gear.csv"))
	drone_levels = _load_levels(dir.path_join("drones.csv"))
	staff_levels = _load_levels(dir.path_join("staff.csv"))
	net_levels = _load_levels(dir.path_join("nets.csv"))
	shop_slots = _load_levels(dir.path_join("shop_slots.csv"))
	_load_locations(dir.path_join("locations.csv"))
	_load_zones(dir.path_join("zones.csv"))
	_load_achievements(dir.path_join("achievements.csv"))


func home() -> LocationDef:
	return locations[0]


func location(location_id: String) -> LocationDef:
	for def in locations:
		if def.id == location_id:
			return def
	return null


## The depth zones of one location, from the shore outwards.
func zones_in(location_id: String) -> Array[ZoneDef]:
	var result: Array[ZoneDef] = []
	result.assign(zones.filter(func(z: ZoneDef) -> bool: return z.location == location_id))
	return result


func _load_locations(path: String) -> void:
	locations.clear()
	var table := CsvTable.load_file(path)
	errors.append_array(table.errors)
	for i in table.rows.size():
		var def := LocationDef.from_row(table.rows[i], errors, "%s row %d" % [path, i + 2])
		if def != null:
			locations.append(def)
	locations.sort_custom(func(a: LocationDef, b: LocationDef) -> bool: return a.order < b.order)
	if locations.is_empty() and table.errors.is_empty():
		errors.append("%s: no locations" % path)


func _load_achievements(path: String) -> void:
	achievements.clear()
	var table := CsvTable.load_file(path)
	errors.append_array(table.errors)
	for i in table.rows.size():
		var def := AchievementDef.from_row(table.rows[i], errors, "%s row %d" % [path, i + 2])
		if def != null:
			achievements.append(def)


func _load_zones(path: String) -> void:
	zones.clear()
	var table := CsvTable.load_file(path)
	errors.append_array(table.errors)
	for i in table.rows.size():
		var where := "%s row %d" % [path, i + 2]
		var zone := ZoneDef.from_row(table.rows[i], species, errors, where)
		if zone == null:
			continue
		if location(zone.location) == null:
			errors.append("%s: unknown location '%s'" % [where, zone.location])
			continue
		zones.append(zone)
	zones.sort_custom(func(a: ZoneDef, b: ZoneDef) -> bool:
		var a_order := location(a.location).order
		var b_order := location(b.location).order
		return a.order < b.order if a_order == b_order else a_order < b_order)
	for def in locations:
		var own := zones_in(def.id)
		if own.is_empty():
			errors.append("%s: location '%s' has no zones" % [path, def.id])
		elif not is_zero_approx(own[0].depth_start):
			errors.append("%s: the first zone of '%s' must start at the shore (0)" % [path, def.id])
		for i in range(1, own.size()):
			if not is_equal_approx(own[i].depth_start, own[i - 1].depth_end):
				errors.append("%s: zone '%s' must start where '%s' ends" % [path, own[i].id, own[i - 1].id])


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
