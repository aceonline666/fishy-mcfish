class_name PlayerState
extends RefCounted
## Everything about a player's progress that gets saved. Pure data: no nodes, no signals.

var money := 0.0
## Lifetime earnings. Used later to pick the "most progressed" save on cloud conflicts.
var total_earned := 0.0
var stats: Dictionary[String, int] = {}
## How many of each species the player has ever caught. Feeds the Fishpedia later.
var species_caught: Dictionary[String, int] = {}
## Fish stored in the tank, by species id, oldest first. M2 turns these into individual
## tank fish that grow and can be sold.
var tank_fish: Array[String] = []


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


## Keeps the highest value seen for a stat, e.g. the best combo.
func record_best(key: String, value: int) -> void:
	if value > int(stats.get(key, 0)):
		stats[key] = value


## Returns true if this is the first catch of the species.
func record_catch(species_id: String) -> bool:
	var is_new := not species_caught.has(species_id)
	species_caught[species_id] = int(species_caught.get(species_id, 0)) + 1
	increment_stat("fish_caught")
	return is_new


func to_dict() -> Dictionary:
	return {
		"money": money,
		"total_earned": total_earned,
		"stats": stats.duplicate(),
		"species_caught": species_caught.duplicate(),
		"tank_fish": tank_fish.duplicate(),
	}


static func from_dict(data: Dictionary) -> PlayerState:
	var state := PlayerState.new()
	state.money = float(data.get("money", 0.0))
	state.total_earned = float(data.get("total_earned", 0.0))
	# JSON turns ints into floats, so convert back.
	var raw_stats: Dictionary = data.get("stats", {})
	for key: Variant in raw_stats:
		state.stats[str(key)] = int(raw_stats[key])
	var raw_caught: Dictionary = data.get("species_caught", {})
	for key: Variant in raw_caught:
		state.species_caught[str(key)] = int(raw_caught[key])
	var raw_tank: Array = data.get("tank_fish", [])
	for id: Variant in raw_tank:
		state.tank_fish.append(str(id))
	return state
