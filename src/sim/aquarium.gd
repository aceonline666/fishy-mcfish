class_name Aquarium
extends RefCounted
## Rules for the beach aquarium: tank space, storing fish, growth, income and upgrade prices.
## Operates on PlayerState using the read-only data in DataRegistry.


static func capacity(tank: TankState) -> float:
	return DataRegistry.tank_levels[tank.level - 1].capacity


static func used_space(tank: TankState) -> float:
	var used := 0.0
	for fish in tank.fish:
		used += DataRegistry.species[fish.species_id].space_l
	return used


## Water environment of a tank, from its slot: temperate or tropical.
static func tank_env(tank: TankState) -> String:
	return DataRegistry.tank_slots[tank.slot].env


static func species_env(def: SpeciesDef) -> String:
	return SpeciesDef.Env.keys()[def.env].to_lower()


## True if the species may live in this tank (right water, big enough) and there is room.
static func fits(tank: TankState, def: SpeciesDef) -> bool:
	var tank_capacity := capacity(tank)
	return tank_env(tank) == species_env(def) and tank_capacity >= def.min_tank_l \
			and used_space(tank) + def.space_l <= tank_capacity


## The first tank (by slot) with room for the species, or null.
static func tank_for(state: PlayerState, def: SpeciesDef) -> TankState:
	for tank in state.tanks:
		if fits(tank, def):
			return tank
	return null


## Puts a juvenile fish into the first tank with room. Returns that tank, or null if none fits.
static func store(state: PlayerState, species_id: String) -> TankState:
	var tank := tank_for(state, DataRegistry.species[species_id])
	if tank != null:
		tank.fish.append(TankFish.new(species_id))
	return tank


## Coins per second all displayed fish bring in right now.
static func income_rate(state: PlayerState) -> float:
	var rate := 0.0
	for tank in state.tanks:
		for fish in tank.fish:
			rate += Economy.appeal_per_second(DataRegistry.species[fish.species_id], fish.growth)
	return rate


## Lets time pass: fish grow and earn income for the next visitors.
static func advance(state: PlayerState, seconds: float) -> void:
	if seconds <= 0.0:
		return
	for tank in state.tanks:
		for fish in tank.fish:
			var def := DataRegistry.species[fish.species_id]
			state.pending_income += Economy.income_over(def, fish.growth, seconds)
			fish.growth = minf(fish.growth + seconds / def.growth_time_s, 1.0)


static func backpack_capacity(state: PlayerState) -> int:
	return int(DataRegistry.backpack_levels[state.backpack_level - 1].capacity)


## The first free tank slot for the environment, or -1 if all are built.
static func next_slot(state: PlayerState, env: String = "temperate") -> int:
	for i in DataRegistry.tank_slots.size():
		if DataRegistry.tank_slots[i].env == env and state.tank_in_slot(i) == null:
			return i
	return -1


## Price of the next tank for the environment, or -1 if all its slots are built.
static func next_tank_cost(state: PlayerState, env: String = "temperate") -> float:
	var slot := next_slot(state, env)
	return DataRegistry.tank_slots[slot].cost if slot >= 0 else -1.0


## Price of upgrading the tank, or -1 at the top level.
static func tank_upgrade_cost(tank: TankState) -> float:
	return DataRegistry.tank_levels[tank.level].cost if tank.level < DataRegistry.tank_levels.size() else -1.0


## Price of the next diving gear, or -1 at the top level.
static func gear_upgrade_cost(state: PlayerState) -> float:
	var levels := DataRegistry.gear_levels
	return levels[state.gear_level].cost if state.gear_level < levels.size() else -1.0


## Price of the next backpack, or -1 at the top level.
static func backpack_upgrade_cost(state: PlayerState) -> float:
	var levels := DataRegistry.backpack_levels
	return levels[state.backpack_level].cost if state.backpack_level < levels.size() else -1.0
