class_name LevelDef
extends RefCounted
## One level of something upgradeable (tank size, tank slot, backpack), loaded from a CSV with
## the columns level, name, capacity and cost, and optionally speed, width and depth. `cost` is
## the price to reach this level, before the location's price factor.

var level: int
var name: String
var capacity: float
var cost: float
## How fast this level works compared to the first (tanks: how fast fish grow in it); 1 if the
## CSV has no speed column.
var speed := 1.0
## Cells of the layout grid (Grid) this level covers, east-west by north-south (tanks: on the
## beach); 1 × 1 if the CSV has no width and depth columns.
var footprint := Vector2i.ONE


## Builds a level from a CSV row. Appends to `errors` and returns null if the row is invalid.
static func from_row(row: Dictionary, errors: PackedStringArray, where: String) -> LevelDef:
	var error_count := errors.size()
	var def := LevelDef.new()
	var level_text := str(row.get("level", ""))
	if level_text.is_valid_int() and level_text.to_int() >= 1:
		def.level = level_text.to_int()
	else:
		errors.append("%s: level must be a whole number >= 1, got '%s'" % [where, level_text])
	def.name = str(row.get("name", ""))
	if def.name.is_empty():
		errors.append("%s: 'name' is empty" % where)
	for column: String in ["capacity", "cost"]:
		var text := str(row.get(column, ""))
		if not text.is_valid_float() or text.to_float() < 0.0:
			errors.append("%s: '%s' must be a number >= 0, got '%s'" % [where, column, text])
			continue
		def.set(column, text.to_float())
	var speed_text := str(row.get("speed", "1"))
	if speed_text.is_valid_float() and speed_text.to_float() > 0.0:
		def.speed = speed_text.to_float()
	else:
		errors.append("%s: 'speed' must be a number > 0, got '%s'" % [where, speed_text])
	for axis in 2:
		var column: String = ["width", "depth"][axis]
		var text := str(row.get(column, "1"))
		if text.is_valid_int() and text.to_int() >= 1:
			def.footprint[axis] = text.to_int()
		else:
			errors.append("%s: '%s' must be a whole number >= 1, got '%s'" % [where, column, text])
	return def if errors.size() == error_count else null
