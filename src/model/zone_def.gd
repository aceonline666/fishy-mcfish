class_name ZoneDef
extends RefCounted
## A depth zone of a fishing spot, loaded from data/zones.csv. Zones are bands of water at
## increasing distance from the shore (ground y); deeper zones need better gear and hold rarer fish.

var id: String
var name: String
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


## Builds a zone from a CSV row. `species` is used to check the spawn table.
## Appends to `errors` and returns null if the row is invalid.
static func from_row(row: Dictionary, species: Dictionary[String, SpeciesDef], errors: PackedStringArray, where: String) -> ZoneDef:
	var error_count := errors.size()
	var zone := ZoneDef.new()
	zone.id = str(row.get("id", ""))
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
	for entry in str(row.get("spawns", "")).split(";", false):
		var parts := entry.split(":")
		if parts.size() != 2 or not species.has(parts[0]) or not parts[1].is_valid_float() or parts[1].to_float() <= 0.0:
			errors.append("%s: invalid spawn entry '%s' (expected species_id:weight)" % [where, entry])
			continue
		zone.spawns[parts[0]] = parts[1].to_float()
	if zone.spawns.is_empty():
		errors.append("%s: zone has no spawns" % where)
	return zone if errors.size() == error_count else null
