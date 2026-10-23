class_name PlayerState
extends RefCounted
## Everything about a player's progress that gets saved. Pure data: no nodes, no signals.

var money := 0.0
## Lifetime earnings. Used later to pick the "most progressed" save on cloud conflicts.
var total_earned := 0.0
var stats: Dictionary[String, int] = {}


func add_money(amount: float) -> void:
	assert(amount >= 0.0, "Use try_spend to remove money.")
	money += amount
	total_earned += amount


func try_spend(amount: float) -> bool:
	if amount < 0.0 or amount > money:
		return false
	money -= amount
	return true


func increment_stat(key: String, by: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + by


func to_dict() -> Dictionary:
	return {
		"money": money,
		"total_earned": total_earned,
		"stats": stats.duplicate(),
	}


static func from_dict(data: Dictionary) -> PlayerState:
	var state := PlayerState.new()
	state.money = float(data.get("money", 0.0))
	state.total_earned = float(data.get("total_earned", 0.0))
	var raw_stats: Dictionary = data.get("stats", {})
	for key: Variant in raw_stats:
		# JSON turns ints into floats, so convert back.
		state.stats[str(key)] = int(raw_stats[key])
	return state
