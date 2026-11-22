class_name ZoneDef
extends RefCounted
## A depth zone of a fishing spot, loaded from data/zones.csv. Zones are bands of water at
## increasing distance from the shore (ground y); deeper zones need better gear and hold rarer fish.

var id: String
## Id of the location the zone belongs to.
var location: String
var name: String
## Position from the shore outwards, within its location.
var order: int
## Ground y where the zone starts and ends (distance from the waterline).
var depth_start: float
var depth_end: float
## Gear level needed to enter (1 = waders).
var gear_level: int
## How many fish swim in the zone at once.
var population: int
## Spawn weights by species id.
var spawns: Dictionary[String, float] = {}
## Spawn weights added at night (optional): species that come up from the deep or out of their
## hiding places after dark. Not needed to chart the zone.
var night_spawns: Dictionary[String, float] = {}


## Builds a zone from a CSV row. `species` is used to check the spawn table.
## Appends to `errors` and returns null if the row is invalid.
static func from_row(row: Dictionary, species: Dictionary[String, SpeciesDef], errors: PackedStringArray, where: String) -> ZoneDef:
	var error_count := errors.size()
	var zone := ZoneDef.new()
	zone.id = str(row.get("id", ""))
	zone.location = str(row.get("location", ""))
	zone.name = str(row.get("name", ""))
	if not zone.id.is_valid_ascii_identifier() or zone.name.is_empty():
		errors.append("%s: zone needs a lower_snake_case id and a name" % where)
	for column: String in ["order", "gear", "population"]:
		var text := str(row.get(column, ""))
		if not text.is_valid_int() or text.to_int() < 1:
			errors.append("%s: '%s' must be a whole number >= 1, got '%s'" % [where, column, text])
	zone.order = str(row.get("order", "0")).to_int()
	zone.gear_level = str(row.get("gear", "0")).to_int()
	zone.population = str(row.get("population", "0")).to_int()
	zone.depth_start = str(row.get("depth_start", "")).to_float()
	zone.depth_end = str(row.get("depth_end", "")).to_float()
	if zone.depth_end <= zone.depth_start:
		errors.append("%s: depth_end must be greater than depth_start" % where)
	zone.spawns = _weights(str(row.get("spawns", "")), species, errors, where)
	zone.night_spawns = _weights(str(row.get("night_spawns", "")), species, errors, where)
	if zone.spawns.is_empty():
		errors.append("%s: zone has no spawns" % where)
	return zone if errors.size() == error_count else null


## The spawns at night: the day's with the night's added.
func spawns_at_night() -> Dictionary[String, float]:
	var weights := spawns.duplicate()
	for id in night_spawns:
		weights[id] = weights.get(id, 0.0) + night_spawns[id]
	return weights


## Spawn weights from "species_id:weight;species_id:weight".
static func _weights(text: String, species: Dictionary[String, SpeciesDef], errors: PackedStringArray, where: String) -> Dictionary[String, float]:
	var weights: Dictionary[String, float] = {}
	for entry in text.split(";", false):
		var parts := entry.split(":")
		if parts.size() != 2 or not species.has(parts[0]) or not parts[1].is_valid_float() or parts[1].to_float() <= 0.0:
			errors.append("%s: invalid spawn entry '%s' (expected species_id:weight)" % [where, entry])
			continue
		weights[parts[0]] = parts[1].to_float()
	return weights
