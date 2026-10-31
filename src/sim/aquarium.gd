class_name Aquarium
extends RefCounted
## Rules for a location's aquarium (its one tank): space, storing fish, growth and
## upgrade prices. Operates on a Site using the read-only data in DataRegistry. Prices are scaled by the
## location's price factor.
##


## Share of caught fish that are already grown.
const GROWN_CATCH_CHANCE := 0.1


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


## True if the site's tank could hold the species once there is room: the right water, and big
## enough for it.
static func can_ever_hold(site: Site, def: SpeciesDef) -> bool:
	var tank_capacity := capacity(site.tank)
	return species_env(def) == site.location().env and tank_capacity >= def.min_tank_l and tank_capacity >= def.space_l


## The size of the smallest tank level that can hold the species, in litres.
static func tank_needed(def: SpeciesDef) -> float:
	for level in DataRegistry.tank_levels:
		if level.capacity >= def.min_tank_l and level.capacity >= def.space_l:
			return level.capacity
	return DataRegistry.tank_levels[-1].capacity


## The site's tank if the species fits in, else null. The tank holds the water of its location,
## so only its own kind of fish (temperate or tropical) live there.
static func tank_for(site: Site, def: SpeciesDef) -> TankState:
	if species_env(def) != site.location().env or not fits(site.tank, def):
		return null
	return site.tank


## Puts a fish into the tank if it fits, as far grown as given (0 young, 1 grown). Returns the
## tank, or null.
static func store(site: Site, species_id: String, growth: float = 0.0) -> TankState:
	var tank := tank_for(site, DataRegistry.species[species_id])
	if tank != null:
		tank.fish.append(TankFish.new(species_id, growth))
	return tank


## How far grown a freshly caught fish is: one in ten is already grown, the others anywhere
## between young and nearly grown, so they grow up one after the other.
static func catch_growth(rng: RandomNumberGenerator) -> float:
	return 1.0 if rng.randf() < GROWN_CATCH_CHANCE else rng.randf_range(0.0, 0.95)


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


## Lets time pass at every location: fish grow towards adult, which triples their value.
## Bigger tanks grow them faster.
static func advance(state: PlayerState, seconds: float) -> void:
	if seconds <= 0.0:
		return
	for site: Site in state.sites.values():
		var speed := growth_speed(site.tank)
		for fish in site.tank.fish:
			var def := DataRegistry.species[fish.species_id]
			fish.growth = minf(fish.growth + seconds * speed / def.growth_time_s, 1.0)


## How many times faster than in the first tank fish grow in this one.
static func growth_speed(tank: TankState) -> float:
	return DataRegistry.tank_levels[tank.level - 1].speed


## The young fish that will be grown first, or null if all are grown (or the tank is empty).
static func next_to_grow(tank: TankState) -> TankFish:
	var next: TankFish = null
	var shortest := INF
	for fish in tank.fish:
		var left := seconds_to_grow(tank, fish)
		if fish.growth < 1.0 and left < shortest:
			next = fish
			shortest = left
	return next


## Seconds until a fish in this tank is grown.
static func seconds_to_grow(tank: TankState, fish: TankFish) -> float:
	var def := DataRegistry.species[fish.species_id]
	return (1.0 - fish.growth) * def.growth_time_s / growth_speed(tank)


## The share of the tank's space that is taken, 0 to 1.
static func fill_share(tank: TankState) -> float:
	return minf(used_space(tank) / capacity(tank), 1.0)


## The least space any species of this kind of water needs. Below that much free space the
## tank counts as full: nothing can be added any more.
static func smallest_space(env: String) -> float:
	var smallest := INF
	for def: SpeciesDef in DataRegistry.species.values():
		if species_env(def) == env:
			smallest = minf(smallest, def.space_l)
	return smallest


## True if not even the smallest fish fits into the tank any more.
static func is_full(site: Site) -> bool:
	return capacity(site.tank) - used_space(site.tank) < smallest_space(site.location().env)


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
