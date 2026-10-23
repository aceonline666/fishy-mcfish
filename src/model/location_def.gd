class_name LocationDef
extends RefCounted
## A place to fish, from data/locations.csv. The first location is home. Others unlock when
## their goal (`unlock`, an achievement id) is reached and the travel fee is paid once. Each has
## its own beach business, started from scratch.

var id: String
var name: String
var order: int
## Water environment of its fish: temperate or tropical.
var env: String
## Achievement id that must be reached first; empty for home.
var unlock: String
var travel_cost: float
## Buildings and upgrades here cost the data prices times this.
var price_factor := 1.0
var shallow_color: Color
var deep_color: Color
var sand_color: Color
var description: String


static func from_row(row: Dictionary, errors: PackedStringArray, where: String) -> LocationDef:
	var error_count := errors.size()
	var def := LocationDef.new()
	def.id = str(row.get("id", ""))
	def.name = str(row.get("name", ""))
	def.env = str(row.get("env", ""))
	def.unlock = str(row.get("unlock", ""))
	def.description = str(row.get("description", ""))
	if not def.id.is_valid_ascii_identifier() or def.name.is_empty():
		errors.append("%s: location needs an id and a name" % where)
	if not SpeciesDef.Env.has(def.env.to_upper()):
		errors.append("%s: unknown env '%s'" % [where, def.env])
	def.order = str(row.get("order", "0")).to_int()
	def.travel_cost = str(row.get("travel_cost", "0")).to_float()
	var factor_text := str(row.get("price_factor", "1"))
	if factor_text.is_valid_float() and factor_text.to_float() > 0.0:
		def.price_factor = factor_text.to_float()
	else:
		errors.append("%s: price_factor must be a number > 0, got '%s'" % [where, factor_text])
	for column: String in ["shallow_color", "deep_color", "sand_color"]:
		var text := str(row.get(column, ""))
		if not Color.html_is_valid(text):
			errors.append("%s: invalid %s '%s'" % [where, column, text])
			continue
		def.set(column, Color.html(text))
	return def if errors.size() == error_count else null
