class_name AchievementDef
extends RefCounted
## A goal from data/achievements.csv. `type` says what is measured (see Achievements), `target`
## is the value to reach, `param` narrows it down (a zone id, a rarity name), `reward` is paid
## in coins when it is reached.

const TYPES: PackedStringArray = [
	"catch_count", "best_combo", "tank_level", "species_count", "charted", "rarity_caught",
	"drone_count", "total_earned", "seller_count", "shop_level",
]

var id: String
var name: String
var description: String
var type: String
var target: float
var param: String
var reward: float


static func from_row(row: Dictionary, errors: PackedStringArray, where: String) -> AchievementDef:
	var error_count := errors.size()
	var def := AchievementDef.new()
	def.id = str(row.get("id", ""))
	def.name = str(row.get("name", ""))
	def.description = str(row.get("description", ""))
	def.type = str(row.get("type", ""))
	def.param = str(row.get("param", ""))
	if not def.id.is_valid_ascii_identifier() or def.name.is_empty() or def.description.is_empty():
		errors.append("%s: achievement needs an id, a name and a description" % where)
	if not TYPES.has(def.type):
		errors.append("%s: unknown achievement type '%s'" % [where, def.type])
	for column: String in ["target", "reward"]:
		var text := str(row.get(column, ""))
		if not text.is_valid_float() or text.to_float() < 0.0:
			errors.append("%s: '%s' must be a number >= 0, got '%s'" % [where, column, text])
			continue
		def.set(column, text.to_float())
	return def if errors.size() == error_count else null
