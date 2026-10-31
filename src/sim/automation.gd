class_name Automation
extends RefCounted
## Drones: prices, where they work, and what they achieve while the player is elsewhere. Each
## location has its own drones; drone N fishes zone N there (the first drone the shallowest
## zone, ...) once the player has charted it, and only takes species the player has caught.

## Fish one drone brings in per second while the player is not watching it (game closed, or at
## another location). Lower than when playing (about one fish every 12 s), so being there pays.
const OFFLINE_DRONE_FISH_PER_SECOND := 0.02


## Price of the site's next drone, or -1 if all are bought.
static func next_drone_cost(site: Site) -> float:
	var levels := DataRegistry.drone_levels
	return levels[site.drone_count].cost * site.price_factor() if site.drone_count < levels.size() else -1.0


## True if the site's next drone can be bought: its zone must be charted first.
static func next_drone_available(state: PlayerState, site: Site) -> bool:
	return next_drone_cost(site) >= 0.0 and drone_zone(state, site, site.drone_count) != null


## Fish drone number `index` carries per trip. Later drones are bigger.
static func drone_capacity(index: int) -> int:
	return int(DataRegistry.drone_levels[mini(index, DataRegistry.drone_levels.size() - 1)].capacity)


## True if drones may take this species: only ones the player has caught themselves.
static func drone_can_catch(state: PlayerState, species_id: String) -> bool:
	return state.species_caught.has(species_id)


## The zone the site's drone number `index` works in: the zone with order index + 1 of the
## site's location, or null while it is not charted.
static func drone_zone(state: PlayerState, site: Site, index: int) -> ZoneDef:
	for zone in DataRegistry.zones_in(site.location_id):
		if zone.order == index + 1:
			return zone if Charting.is_charted(state, zone) else null
	return null


## A species a drone in the zone could bring back right now, by the zone's spawn weights;
## empty if it knows none of them.
static func pick_drone_catch(state: PlayerState, zone: ZoneDef, rng: RandomNumberGenerator) -> String:
	var weights: Dictionary[String, float] = {}
	for id in zone.spawns:
		if drone_can_catch(state, id):
			weights[id] = zone.spawns[id]
	return SpawnTable.new(weights).pick(rng) if not weights.is_empty() else ""


## True if a drone could still put a fish of this species into the site's tank, with
## `reserved_l` litres already taken by fish drones carry.
static func drone_fits(site: Site, def: SpeciesDef, reserved_l: float) -> bool:
	var tank_capacity := Aquarium.capacity(site.tank)
	return Aquarium.species_env(def) == site.location().env and tank_capacity >= def.min_tank_l 			and Aquarium.used_space(site.tank) + reserved_l + def.space_l <= tank_capacity


## True if the tank has room for none of the species the drones of this zone may catch. They
## then stop fishing and rest on the ground until there is room again.
static func drone_tank_full(state: PlayerState, site: Site, zone: ZoneDef, reserved_l: float) -> bool:
	for id in zone.spawns:
		if drone_can_catch(state, id) and drone_fits(site, DataRegistry.species[id], reserved_l):
			return false
	return true


## Drones of the given sites keep catching known species in their zones and put them into
## their tanks. A drone stops fishing while the tank is full. Returns how many fish were stored.
static func run_drones(state: PlayerState, sites: Array[Site], seconds: float, rng: RandomNumberGenerator) -> int:
	var stored := 0
	for site in sites:
		for index in site.drone_count:
			var zone := drone_zone(state, site, index)
			if zone == null:
				continue
			for i in int(seconds * OFFLINE_DRONE_FISH_PER_SECOND):
				if drone_tank_full(state, site, zone, 0.0):
					break
				var species_id := pick_drone_catch(state, zone, rng)
				if not species_id.is_empty() and Aquarium.store(site, species_id, Aquarium.catch_growth(rng)) != null:
					stored += 1
	return stored


## While the game was closed, the drones of every location kept fishing.
static func run_drones_offline(state: PlayerState, seconds: float, rng: RandomNumberGenerator) -> int:
	var all_sites: Array[Site] = []
	all_sites.assign(state.sites.values())
	return run_drones(state, all_sites, seconds, rng)
