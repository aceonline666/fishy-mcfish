class_name Automation
extends RefCounted
## Drones: prices, where they work, and what they achieve while the game is closed. Drone N
## fishes zone N (the first drone the shallowest zone, ...) once the player has charted it, and
## only takes species the player has caught themselves.

## Fish one drone brings in per second while the game is closed. Lower than when playing
## (about one fish every 12 s), so being there still pays.
const OFFLINE_DRONE_FISH_PER_SECOND := 0.02


## Price of the next drone, or -1 if all are bought.
static func next_drone_cost(state: PlayerState) -> float:
	var levels := DataRegistry.drone_levels
	return levels[state.drone_count].cost if state.drone_count < levels.size() else -1.0


## True if the next drone can be bought: its zone must be charted first.
static func next_drone_available(state: PlayerState) -> bool:
	return next_drone_cost(state) >= 0.0 and drone_zone(state, state.drone_count) != null


## Fish drone number `index` carries per trip. Later drones are bigger.
static func drone_capacity(index: int) -> int:
	return int(DataRegistry.drone_levels[mini(index, DataRegistry.drone_levels.size() - 1)].capacity)


## True if drones may take this species: only ones the player has caught themselves.
static func drone_can_catch(state: PlayerState, species_id: String) -> bool:
	return state.species_caught.has(species_id)


## The zone drone number `index` works in: the zone with order index + 1 where the player is,
## if charted, else the first charted one of that order elsewhere. Null if none is charted.
static func drone_zone(state: PlayerState, index: int) -> ZoneDef:
	var found: ZoneDef = null
	for zone in DataRegistry.zones:
		if zone.order != index + 1 or not Charting.is_charted(state, zone):
			continue
		if zone.location == state.current_location:
			return zone
		if found == null:
			found = zone
	return found


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
			continue
		for i in int(seconds * OFFLINE_DRONE_FISH_PER_SECOND):
			var species_id := pick_drone_catch(state, zone, rng)
			if not species_id.is_empty() and Aquarium.store(state, species_id) != null:
				stored += 1
	return stored
