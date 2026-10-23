class_name PlayerState
extends RefCounted
## Everything about a player's progress that gets saved. Pure data: no nodes, no signals.
## Use new_game() for a fresh start; PlayerState.new() is completely empty.

var money := 0.0
## Lifetime earnings. Used later to pick the "most progressed" save on cloud conflicts.
var total_earned := 0.0
var stats: Dictionary[String, int] = {}
## How many of each species the player has ever caught. Feeds the Fishpedia later.
var species_caught: Dictionary[String, int] = {}
## Index + 1 into DataRegistry.backpack_levels.
var backpack_level := 1
## Built tanks, ordered by slot.
var tanks: Array[TankState] = []
## Coins visitors have paid that wait at the ticket booth to be collected.
var cash_pile := 0.0
## Income the tanks have earned that the next visitor will bring to the booth.
var pending_income := 0.0
## Coins already paid into build squares, by square id.
var build_progress: Dictionary[String, float] = {}


static func new_game() -> PlayerState:
	var state := PlayerState.new()
	state.tanks.append(TankState.new(0, 1))
	return state


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


func tank_in_slot(slot: int) -> TankState:
	for tank in tanks:
		if tank.slot == slot:
			return tank
	return null


func to_dict() -> Dictionary:
	var tank_data: Array[Dictionary] = []
	for tank in tanks:
		tank_data.append(tank.to_dict())
	return {
		"money": money,
		"total_earned": total_earned,
		"stats": stats.duplicate(),
		"species_caught": species_caught.duplicate(),
		"backpack_level": backpack_level,
		"tanks": tank_data,
		"cash_pile": cash_pile,
		"pending_income": pending_income,
		"build_progress": build_progress.duplicate(),
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
	state.backpack_level = maxi(int(data.get("backpack_level", 1)), 1)
	var raw_tanks: Array = data.get("tanks", [])
	for entry: Variant in raw_tanks:
		if entry is Dictionary:
			state.tanks.append(TankState.from_dict(entry))
	if state.tanks.is_empty():
		state.tanks.append(TankState.new(0, 1))
	state.tanks.sort_custom(func(a: TankState, b: TankState) -> bool: return a.slot < b.slot)
	# Early prototype saves kept stored fish as a flat list; move them into the first tank.
	var legacy_tank: Array = data.get("tank_fish", [])
	for id: Variant in legacy_tank:
		state.tanks[0].fish.append(TankFish.new(str(id)))
	state.cash_pile = float(data.get("cash_pile", 0.0))
	state.pending_income = float(data.get("pending_income", 0.0))
	var raw_progress: Dictionary = data.get("build_progress", {})
	for key: Variant in raw_progress:
		state.build_progress[str(key)] = float(raw_progress[key])
	return state
