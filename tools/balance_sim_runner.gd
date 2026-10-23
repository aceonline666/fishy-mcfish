extends RefCounted
## Plays the game with a simple greedy strategy, using the real game rules, and prints when
## milestones are reached, to check the pacing. Started by tools/balance_sim.gd.
##
## The player model: fish the most useful open zone until the backpack is full, walk up the
## beach, store what fits (sell the rest), collect the visitors' coins, buy the cheapest
## affordable upgrade, walk back. Drones and visitors work in the background.

## Seconds of searching and walking per fish caught, plus its struggle time.
const SECONDS_PER_CATCH := 4.0
## A round trip between the fishing spot and the beach.
const TRIP_OVERHEAD_S := 14.0
## Fish per second a drone brings in while the game runs.
const DRONE_FISH_PER_SECOND := 0.2
const REPORT_EVERY_S := 600.0

## Game time in seconds when each milestone first happened: purchases by id ("tank", "gear",
## "unlock_coral_reef", ...), "charted_<zone id>" and "all_species".
var milestones: Dictionary[String, float] = {}

var _state := PlayerState.new_game()
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _next_report := REPORT_EVERY_S
var _drone_progress := 0.0
var _backpack: Array[String] = []
var _quiet := false


## Plays for the given number of hours and returns the milestones.
func run(hours: float, seed_value: int, quiet: bool = false) -> Dictionary[String, float]:
	_rng.seed = seed_value
	_quiet = quiet
	_print("time   event")
	while _time < hours * 3600.0:
		_fish_one()
		if _backpack.size() >= Aquarium.backpack_capacity(_state):
			_trip()
	_report()
	return milestones


## Catches one fish in the chosen zone, letting time pass.
func _fish_one() -> void:
	var zone := _choose_zone()
	var species_id := SpawnTable.new(zone.spawns).pick(_rng)
	_pass_time(SECONDS_PER_CATCH + CatchRules.struggle_seconds(DataRegistry.species[species_id]))
	var was_charted := Charting.is_charted(_state, zone)
	if _state.record_catch(species_id, zone.id):
		_event("new species: %s (%s)" % [DataRegistry.species[species_id].common_name, zone.name])
		if _state.species_caught.size() == DataRegistry.species.size():
			milestones.get_or_add("all_species", _time)
	if not was_charted and Charting.is_charted(_state, zone):
		_event("charted %s" % zone.name)
		milestones.get_or_add("charted_" + zone.id, _time)
	_backpack.append(species_id)


## Explore first: the shallowest uncharted open zone; otherwise the zone worth the most.
func _choose_zone() -> ZoneDef:
	var best: ZoneDef = null
	var best_value := -1.0
	for location: LocationDef in DataRegistry.locations:
		if not Travel.is_unlocked(_state, location):
			continue
		# Tropical fish need a tropical tank to be worth catching.
		if location.env == "tropical" and not _state.tanks.any(func(t: TankState) -> bool: return Aquarium.tank_env(t) == "tropical"):
			continue
		for zone: ZoneDef in DataRegistry.zones_in(location.id):
			if zone.gear_level > _state.gear_level:
				continue
			if not Charting.is_charted(_state, zone):
				return zone
			var value := 0.0
			for id: String in zone.spawns:
				value += zone.spawns[id] * DataRegistry.species[id].base_value
			if value > best_value:
				best = zone
				best_value = value
	return best


## Walks up the beach: store or sell the catch, collect coins, buy upgrades.
func _trip() -> void:
	_pass_time(TRIP_OVERHEAD_S)
	for id in _backpack:
		if Aquarium.store(_state, id) == null:
			_state.add_money(Economy.sale_price(DataRegistry.species[id]))
	_backpack.clear()
	_state.add_money(_state.cash_pile + _state.pending_income)
	_state.cash_pile = 0.0
	_state.pending_income = 0.0
	while _buy_cheapest():
		pass


## Buys the cheapest affordable upgrade. Returns false if nothing was bought.
func _buy_cheapest() -> bool:
	var options: Array[Dictionary] = []
	_add_option(options, "tank", Aquarium.next_tank_cost(_state, "temperate"))
	for tank in _state.tanks:
		if Aquarium.used_space(tank) >= Aquarium.capacity(tank) * 0.7:
			_add_option(options, "upgrade_tank_%d" % tank.slot, Aquarium.tank_upgrade_cost(tank))
	_add_option(options, "backpack", Aquarium.backpack_upgrade_cost(_state))
	var deepest := Charting.deepest_open_zone(DataRegistry.home().id, _state.gear_level)
	if Charting.is_charted(_state, deepest):
		_add_option(options, "gear", Aquarium.gear_upgrade_cost(_state))
	if not Charting.charted_zones(_state).is_empty():
		_add_option(options, "drone", Automation.next_drone_cost(_state))
	_add_option(options, "cashier", Automation.cashier_cost(_state))
	for location: LocationDef in DataRegistry.locations:
		if Travel.can_unlock(_state, location):
			_add_option(options, "unlock_" + location.id, location.travel_cost)
		elif Travel.is_unlocked(_state, location) and location.env == "tropical":
			_add_option(options, "tropical_tank", Aquarium.next_tank_cost(_state, "tropical"))
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["cost"] < b["cost"])
	if options.is_empty() or options[0]["cost"] > _state.money:
		return false
	var choice: Dictionary = options[0]
	_state.try_spend(choice["cost"])
	_apply(choice["id"])
	milestones.get_or_add(choice["id"], _time)
	_event("bought %s for %s" % [choice["id"], NumberFormat.compact(choice["cost"])])
	return true


func _add_option(options: Array[Dictionary], id: String, cost: float) -> void:
	if cost >= 0.0:
		options.append({"id": id, "cost": cost})


func _apply(id: String) -> void:
	if id == "tank":
		_state.tanks.append(TankState.new(Aquarium.next_slot(_state, "temperate"), 1))
	elif id == "tropical_tank":
		_state.tanks.append(TankState.new(Aquarium.next_slot(_state, "tropical"), 1))
	elif id.begins_with("upgrade_tank_"):
		_state.tank_in_slot(id.trim_prefix("upgrade_tank_").to_int()).level += 1
	elif id == "backpack":
		_state.backpack_level += 1
	elif id == "gear":
		_state.gear_level += 1
	elif id == "drone":
		_state.drone_count += 1
	elif id == "cashier":
		_state.has_cashier = true
	elif id.begins_with("unlock_"):
		_state.unlocked_locations.append(id.trim_prefix("unlock_"))
	_state.tanks.sort_custom(func(a: TankState, b: TankState) -> bool: return a.slot < b.slot)


## Lets time pass in one-second steps: fish grow and earn, drones fish, goals pay out.
func _pass_time(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step := minf(left, 1.0)
		left -= step
		_time += step
		Aquarium.advance(_state, step)
		_drone_progress += _state.drone_count * DRONE_FISH_PER_SECOND * step
		while _drone_progress >= 1.0:
			_drone_progress -= 1.0
			var zone := Automation.drone_zone(_state, _rng.randi())
			var id := Automation.pick_drone_catch(_state, zone, _rng) if zone != null else ""
			if not id.is_empty() and Aquarium.store(_state, id) == null:
				_state.add_money(Economy.sale_price(DataRegistry.species[id]))
		for def in Achievements.newly_reached(_state):
			_state.achievements.append(def.id)
			_state.add_money(def.reward)
			_event("goal: %s (+%s)" % [def.name, NumberFormat.compact(def.reward)])
		if _time >= _next_report:
			_next_report += REPORT_EVERY_S
			_report()


func _print(text: String) -> void:
	if not _quiet:
		print(text)


func _event(text: String) -> void:
	_print("%s  %s" % [_clock(), text])


func _report() -> void:
	var fish := 0
	for tank in _state.tanks:
		fish += tank.fish.size()
	_print("%s  -- coins %s, income %s/min, %d tanks, %d fish in tanks, %d species, gear %d, %d drones" % [
		_clock(), NumberFormat.compact(_state.money), NumberFormat.compact(Aquarium.income_rate(_state) * 60.0),
		_state.tanks.size(), fish, _state.species_caught.size(), _state.gear_level, _state.drone_count])


func _clock() -> String:
	return "%3d:%02d" % [int(_time / 60.0), int(_time) % 60]
