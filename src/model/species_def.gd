class_name SpeciesDef
extends RefCounted
## Static data for one fish species, loaded from data/species.csv.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum Env { TEMPERATE, TROPICAL, POLAR, ABYSSAL }

const NUMBER_COLUMNS: PackedStringArray = [
	"base_value", "length_cm", "body_aspect", "space_l", "min_tank_l", "bioload", "growth_time_s",
]

var id: String
var common_name: String
var scientific_name: String
var rarity: Rarity
var base_value: float
var length_cm: float
## Side-on body depth / length, exaggerated for a chunky comic look (eels are slender,
## lumpsuckers round).
var body_aspect: float
## Tank volume one adult fish occupies.
var space_l: float
## Smallest tank this species may live in.
var min_tank_l: float
## Load on the tank filter.
var bioload: float
var food_id: String
var env: Env
## Seconds from juvenile to fully grown (while fed and in clean water).
var growth_time_s: float
## Shape colour until real art exists.
var placeholder_color: Color
var fun_fact: String


## Builds a definition from a CSV row. Appends to `errors` and returns null if the row is invalid.
static func from_row(row: Dictionary, errors: PackedStringArray, where: String) -> SpeciesDef:
	var error_count := errors.size()
	var def := SpeciesDef.new()

	def.id = row.get("id", "")
	if not def.id.is_valid_ascii_identifier() or def.id != def.id.to_lower():
		errors.append("%s: id '%s' must be lower_snake_case" % [where, def.id])
	def.common_name = row.get("common_name", "")
	def.scientific_name = row.get("scientific_name", "")
	def.food_id = row.get("food", "")
	def.fun_fact = row.get("fun_fact", "")
	for column: String in ["common_name", "scientific_name", "food", "fun_fact"]:
		if str(row.get(column, "")).is_empty():
			errors.append("%s: '%s' is empty" % [where, column])

	var rarity_name := str(row.get("rarity", "")).to_upper()
	if Rarity.has(rarity_name):
		def.rarity = Rarity[rarity_name]
	else:
		errors.append("%s: unknown rarity '%s'" % [where, row.get("rarity", "")])

	var env_name := str(row.get("env", "")).to_upper()
	if Env.has(env_name):
		def.env = Env[env_name]
	else:
		errors.append("%s: unknown env '%s'" % [where, row.get("env", "")])

	for column in NUMBER_COLUMNS:
		var text := str(row.get(column, ""))
		if not text.is_valid_float() or text.to_float() <= 0.0:
			errors.append("%s: '%s' must be a positive number, got '%s'" % [where, column, text])
			continue
		def.set(column, text.to_float())

	var color_text := str(row.get("placeholder_color", ""))
	if Color.html_is_valid(color_text):
		def.placeholder_color = Color.html(color_text)
	else:
		errors.append("%s: invalid placeholder_color '%s'" % [where, color_text])

	return def if errors.size() == error_count else null
