class_name Aquarium
extends RefCounted
## Rules for a location's aquarium (its one tank): space, storing fish, growth, breeding and
## upgrade prices. Operates on a Site using the read-only data in DataRegistry. Prices are scaled by the
## location's price factor.
##
## Fish breed: two or more fish of a species in a tank get young, one per pair every
## BREED_TIME_MULT growth times, while the tank is less than BREED_FILL full. The rest of the
## space stays free for the catch. So a tank keeps producing fish for the sellers.

const BREED_FILL := 0.8
const BREED_TIME_MULT := 2.0
## A crowded tank stops breeding, however small its fish are.
const MAX_BREEDING_FISH := 300


static func capacity(tank: TankState) -> float:
	return DataRegistry.tank_levels[tank.level - 1].capacity


static func used_space(tank: TankState) -> float:
	var used := 0.0
	for fish in tank.fish:
		used += DataRegistry.species[fish.species_id].space_l
	return used


static func species_env(def: SpeciesDef) -> String:
	return SpeciesDef.Env.keys()[def.env].to_lower()


## True if the tank is big enough for the species and has room for it.
static func fits(tank: TankState, def: SpeciesDef) -> bool:
	var tank_capacity := capacity(tank)
	return tank_capacity >= def.min_tank_l and used_space(tank) + def.space_l <= tank_capacity


## The site's tank if the species fits in, else null. The tank holds the water of its location,
## so only its own kind of fish (temperate or tropical) live there.
static func tank_for(site: Site, def: SpeciesDef) -> TankState:
	if species_env(def) != site.location().env or not fits(site.tank, def):
		return null
	return site.tank


## Puts a juvenile fish into the tank if it fits. Returns the tank, or null.
static func store(site: Site, species_id: String) -> TankState:
	var tank := tank_for(site, DataRegistry.species[species_id])
	if tank != null:
		tank.fish.append(TankFish.new(species_id))
	return tank


## What all fish in the tank would sell for right now.
static func tank_value(site: Site) -> float:
	var value := 0.0
	for fish in site.tank.fish:
		value += Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
	return value


static func adult_count(site: Site) -> int:
	var count := 0
	for fish in site.tank.fish:
		if fish.growth >= 1.0:
			count += 1
	return count


## Lets time pass at every location: fish grow towards adult, which triples their value, and
## breed.
static func advance(state: PlayerState, seconds: float) -> void:
	if seconds <= 0.0:
		return
	for site: Site in state.sites.values():
		for fish in site.tank.fish:
			var def := DataRegistry.species[fish.species_id]
			fish.growth = minf(fish.growth + seconds / def.growth_time_s, 1.0)
		breed(site.tank, seconds)


## Young are born to every pair in the tank while there is breeding room. Returns how many.
static func breed(tank: TankState, seconds: float) -> int:
	var counts: Dictionary[String, int] = {}
	for fish in tank.fish:
		counts[fish.species_id] = counts.get(fish.species_id, 0) + 1
	var room := capacity(tank) * BREED_FILL - used_space(tank)
	var born := 0
	for id: String in counts:
		var pairs := counts[id] / 2
		if pairs == 0:
			tank.breeding.erase(id)
			continue
		var def := DataRegistry.species[id]
		var progress: float = tank.breeding.get(id, 0.0) + pairs * seconds / (def.growth_time_s * BREED_TIME_MULT)
		while progress >= 1.0 and def.space_l <= room and tank.fish.size() < MAX_BREEDING_FISH:
			progress -= 1.0
			tank.fish.append(TankFish.new(id))
			room -= def.space_l
			born += 1
		# A full tank does not save up young for later.
		tank.breeding[id] = minf(progress, 1.0)
	return born


static func backpack_capacity(site: Site) -> int:
	return int(DataRegistry.backpack_levels[site.backpack_level - 1].capacity)


## Price of upgrading the tank, or -1 at the top level.
static func tank_upgrade_cost(site: Site) -> float:
	return _next_level_cost(site, DataRegistry.tank_levels, site.tank.level)


## Price of the next diving gear, or -1 at the top level.
static func gear_upgrade_cost(site: Site) -> float:
	return _next_level_cost(site, DataRegistry.gear_levels, site.gear_level)


## How much faster than the hand net big fish are landed.
static func net_speed(site: Site) -> float:
	return DataRegistry.net_levels[site.net_level - 1].capacity


## Price of the next net, or -1 at the top level.
static func net_upgrade_cost(site: Site) -> float:
	return _next_level_cost(site, DataRegistry.net_levels, site.net_level)


## Price of the next backpack, or -1 at the top level.
static func backpack_upgrade_cost(site: Site) -> float:
	return _next_level_cost(site, DataRegistry.backpack_levels, site.backpack_level)


## Price of the level after `level` (1-based) at this site, or -1 if there is none.
static func _next_level_cost(site: Site, levels: Array[LevelDef], level: int) -> float:
	return levels[level].cost * site.price_factor() if level < levels.size() else -1.0
