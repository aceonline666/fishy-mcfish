class_name Automation
extends RefCounted
## Drones and staff: prices, and what drones achieve while the game is closed.

## Fish one drone brings in per second while the game is closed. Lower than when playing
## (about one fish every 12 s), so being there still pays.
const OFFLINE_DRONE_FISH_PER_SECOND := 0.02


## Price of the next drone, or -1 if all are bought.
static func next_drone_cost(state: PlayerState) -> float:
	var levels := DataRegistry.drone_levels
	return levels[state.drone_count].cost if state.drone_count < levels.size() else -1.0


static func drone_capacity(state: PlayerState) -> int:
	var index := clampi(state.drone_count - 1, 0, DataRegistry.drone_levels.size() - 1)
	return int(DataRegistry.drone_levels[index].capacity)


## Price of hiring the cashier, or -1 once hired.
static func cashier_cost(state: PlayerState) -> float:
	return -1.0 if state.has_cashier else DataRegistry.staff_levels[0].cost


## True if drones may take this species: only ones the player has caught themselves.
static func drone_can_catch(state: PlayerState, species_id: String) -> bool:
	return state.species_caught.has(species_id)


## The zone drone number `index` works in: charted zones in turn, deepest first. Null if
## nothing is charted.
static func drone_zone(state: PlayerState, index: int) -> ZoneDef:
	var charted := Charting.charted_zones(state)
	return charted[index % charted.size()] if not charted.is_empty() else null


## A species a drone in the zone could bring back right now, by the zone's spawn weights;
## empty if it knows none of them.
static func pick_drone_catch(state: PlayerState, zone: ZoneDef, rng: RandomNumberGenerator) -> String:
	var weights: Dictionary[String, float] = {}
	for id in zone.spawns:
		if drone_can_catch(state, id):
			weights[id] = zone.spawns[id]
	return SpawnTable.new(weights).pick(rng) if not weights.is_empty() else ""


## While away, drones keep catching known species in their zones and put them into tanks with
## room. Fish that do not fit are let go. Returns how many fish were stored.
static func run_drones_offline(state: PlayerState, seconds: float, rng: RandomNumberGenerator) -> int:
	var stored := 0
	for index in state.drone_count:
		var zone := drone_zone(state, index)
		if zone == null:
			return stored
		for i in int(seconds * OFFLINE_DRONE_FISH_PER_SECOND):
			var species_id := pick_drone_catch(state, zone, rng)
			if not species_id.is_empty() and Aquarium.store(state, species_id) != null:
				stored += 1
	return stored
