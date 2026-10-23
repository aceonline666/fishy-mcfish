class_name Aquarium
extends RefCounted
## Rules for a location's aquarium: tank space, storing fish, growth and upgrade prices.
## Operates on a Site using the read-only data in DataRegistry. Prices are scaled by the
## location's price factor.


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


## The first tank (by slot) with room for the species, or null. Tanks hold the water of their
## location, so only its own kind of fish (temperate or tropical) live there.
static func tank_for(site: Site, def: SpeciesDef) -> TankState:
	if species_env(def) != site.location().env:
		return null
	for tank in site.tanks:
		if fits(tank, def):
			return tank
	return null


## Puts a juvenile fish into the first tank with room. Returns that tank, or null if none fits.
static func store(site: Site, species_id: String) -> TankState:
	var tank := tank_for(site, DataRegistry.species[species_id])
	if tank != null:
		tank.fish.append(TankFish.new(species_id))
	return tank


## What all fish in the tanks would sell for right now.
static func tank_value(site: Site) -> float:
	var value := 0.0
	for tank in site.tanks:
		for fish in tank.fish:
			value += Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
	return value


static func adult_count(site: Site) -> int:
	var count := 0
	for tank in site.tanks:
		for fish in tank.fish:
			if fish.growth >= 1.0:
				count += 1
	return count


## Lets time pass at every location: fish grow towards adult, which triples their value.
static func advance(state: PlayerState, seconds: float) -> void:
	if seconds <= 0.0:
		return
	for site: Site in state.sites.values():
		for tank in site.tanks:
			for fish in tank.fish:
				var def := DataRegistry.species[fish.species_id]
				fish.growth = minf(fish.growth + seconds / def.growth_time_s, 1.0)


static func backpack_capacity(site: Site) -> int:
	return int(DataRegistry.backpack_levels[site.backpack_level - 1].capacity)


## The first free tank slot, or -1 if all are built.
static func next_slot(site: Site) -> int:
	for i in DataRegistry.tank_slots.size():
		if site.tank_in_slot(i) == null:
			return i
	return -1


## Price of the next tank, or -1 if all slots are built.
static func next_tank_cost(site: Site) -> float:
	var slot := next_slot(site)
	return DataRegistry.tank_slots[slot].cost * site.price_factor() if slot >= 0 else -1.0


## Price of upgrading the tank, or -1 at the top level.
static func tank_upgrade_cost(site: Site, tank: TankState) -> float:
	return _next_level_cost(site, DataRegistry.tank_levels, tank.level)


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
