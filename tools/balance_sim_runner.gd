extends RefCounted
## Plays the game with a simple greedy strategy, using the real game rules, and prints when
## milestones are reached, to check the pacing. Started by tools/balance_sim.gd.
##
## The player model: fish the most useful open zone of the current location until the backpack
## is full, walk up the beach, store what fits, sell the rest and the grown fish (all but the
## breeding pairs) at the shop of its zone (fish no shop buys are let go), buy the cheapest
## affordable upgrade there (or the travel fee), walk back. Once every species of a location is found and its gear is maxed, travel
## on to the next open location and build its business from scratch. Drones and sellers of every
## location work in the background.

## Seconds of searching and walking per fish caught, plus its struggle time.
const SECONDS_PER_CATCH := 4.0
## A round trip between the fishing spot, the store pad and the shop.
const TRIP_OVERHEAD_S := 12.0
## Seconds per fish sold on a "Sell fish" pad.
const SELL_SECONDS := 0.08
## Fish per second a drone brings in where the player is (elsewhere: the offline rate).
const DRONE_FISH_PER_SECOND := 0.2
const REPORT_EVERY_S := 600.0

## Game time in seconds when each milestone first happened: purchases by id ("tank", "gear",
## "unlock_coral_reef", ...), "travel_<location id>", "charted_<zone id>" and "all_species".
var milestones: Dictionary[String, float] = {}

var _state := PlayerState.new_game()
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _next_report := REPORT_EVERY_S
## By location id.
var _drone_progress: Dictionary[String, float] = {}
## By location id.
var _seller_progress: Dictionary[String, float] = {}
var _earned_at_report := 0.0
## Coins the sellers earned since the last report.
var _seller_earned := 0.0
var _backpack: Array[String] = []
var _quiet := false


## Plays for the given number of hours and returns the milestones.
func run(hours: float, seed_value: int, quiet: bool = false) -> Dictionary[String, float]:
	_rng.seed = seed_value
	_quiet = quiet
	_print("time   event")
	while _time < hours * 3600.0:
		_fish_one()
		if _backpack.size() >= Aquarium.backpack_capacity(_state.here()):
			_trip()
	_report()
	return milestones


## Catches one fish in the chosen zone, letting time pass.
func _fish_one() -> void:
	var zone := _choose_zone()
	var species_id := SpawnTable.new(zone.spawns).pick(_rng)
	_pass_time(SECONDS_PER_CATCH + CatchRules.struggle_seconds(DataRegistry.species[species_id], Aquarium.net_speed(_state.here())))
	var was_charted := Charting.is_charted(_state, zone)
	if _state.record_catch(species_id, zone.id):
		_event("new species: %s (%s)" % [DataRegistry.species[species_id].common_name, zone.name])
		if _state.species_caught.size() == DataRegistry.species.size():
			milestones.get_or_add("all_species", _time)
	if not was_charted and Charting.is_charted(_state, zone):
		_event("charted %s" % zone.name)
		milestones.get_or_add("charted_" + zone.id, _time)
	_backpack.append(species_id)


## Explore first: the shallowest open zone here that is uncharted or still hides an unknown
## species; otherwise the zone worth the most.
func _choose_zone() -> ZoneDef:
	var site := _state.here()
	var best: ZoneDef = null
	var best_value := -1.0
	for zone in DataRegistry.zones_in(site.location_id):
		if zone.gear_level > site.gear_level:
			continue
		if not Charting.is_charted(_state, zone) or _has_unknown_species(zone):
			return zone
		var value := 0.0
		for id: String in zone.spawns:
			value += zone.spawns[id] * DataRegistry.species[id].base_value
		if value > best_value:
			best = zone
			best_value = value
	return best


func _has_unknown_species(zone: ZoneDef) -> bool:
	return zone.spawns.keys().any(func(id: String) -> bool: return not _state.species_caught.has(id))


## Walks up the beach: store what fits, sell the rest and all grown fish, buy upgrades, and
## travel on once this location is done.
func _trip() -> void:
	var site := _state.here()
	_pass_time(TRIP_OVERHEAD_S)
	var sold := 0
	for id in _backpack:
		if Aquarium.store(site, id) == null and Selling.has_shop_for(site, id):
			_state.add_money(Economy.sale_price(DataRegistry.species[id]))
			sold += 1
	_backpack.clear()
	while not Selling.sell_best(_state, site).is_empty():
		sold += 1
	_pass_time(sold * SELL_SECONDS)
	while _buy_cheapest():
		pass
	_maybe_travel()


## Moves on to the next open location once every species here is found and the gear is maxed.
func _maybe_travel() -> void:
	var site := _state.here()
	if site.gear_level < DataRegistry.gear_levels.size():
		return
	if DataRegistry.zones_in(site.location_id).any(_has_unknown_species):
		return
	for location: LocationDef in DataRegistry.locations:
		if location.order > site.location().order and Travel.is_unlocked(_state, location):
			_state.current_location = location.id
			milestones.get_or_add("travel_" + location.id, _time)
			_event("travelled to %s" % location.name)
			return


## Buys the cheapest affordable upgrade here (or a travel fee). Returns false if nothing was
## bought.
func _buy_cheapest() -> bool:
	var site := _state.here()
	var options: Array[Dictionary] = []
	if Aquarium.used_space(site.tank) >= Aquarium.capacity(site.tank) * 0.7:
		_add_option(options, "tank", Aquarium.tank_upgrade_cost(site))
	_add_option(options, "backpack", Aquarium.backpack_upgrade_cost(site))
	var deepest := Charting.deepest_open_zone(site.location_id, site.gear_level)
	if Charting.is_charted(_state, deepest):
		_add_option(options, "gear", Aquarium.gear_upgrade_cost(site))
	if Automation.next_drone_available(_state, site):
		_add_option(options, "drone", Automation.next_drone_cost(site))
	_add_option(options, "net", Aquarium.net_upgrade_cost(site))
	_add_option(options, "shop", Selling.shop_upgrade_cost(site))
	_add_option(options, "seller", Selling.next_seller_cost(site))
	for location: LocationDef in DataRegistry.locations:
		if Travel.can_unlock(_state, location):
			_add_option(options, "unlock_" + location.id, location.travel_cost)
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["cost"] < b["cost"])
	if options.is_empty() or options[0]["cost"] > _state.money:
		return false
	var choice: Dictionary = options[0]
	_state.try_spend(choice["cost"])
	_apply(site, choice["id"])
	milestones.get_or_add(choice["id"], _time)
	_event("bought %s for %s" % [choice["id"], NumberFormat.compact(choice["cost"])])
	return true


func _add_option(options: Array[Dictionary], id: String, cost: float) -> void:
	if cost >= 0.0:
		options.append({"id": id, "cost": cost})


func _apply(site: Site, id: String) -> void:
	if id == "tank":
		site.tank.level += 1
	elif id == "backpack":
		site.backpack_level += 1
	elif id == "gear":
		site.gear_level += 1
	elif id == "drone":
		site.drone_count += 1
	elif id == "net":
		site.net_level += 1
	elif id == "shop":
		site.shop_level += 1
	elif id == "seller":
		site.seller_count += 1
	elif id.begins_with("unlock_"):
		_state.unlocked_locations.append(id.trim_prefix("unlock_"))


## Lets time pass in one-second steps: fish grow, drones fish, sellers sell, goals pay out.
func _pass_time(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step := minf(left, 1.0)
		left -= step
		_time += step
		Aquarium.advance(_state, step)
		for site: Site in _state.sites.values():
			_run_drones(site, step)
			_run_sellers(site, step)
		for def in Achievements.newly_reached(_state):
			_state.achievements.append(def.id)
			_state.add_money(def.reward)
			_event("goal: %s (+%s)" % [def.name, NumberFormat.compact(def.reward)])
		if _time >= _next_report:
			_next_report += REPORT_EVERY_S
			_report()


## Drones where the player is deliver their catch (sold if no tank has room); elsewhere they
## fish at the slower unwatched rate and let go what does not fit.
func _run_drones(site: Site, step: float) -> void:
	if site.drone_count == 0:
		return
	var watched := site == _state.here()
	var rate := DRONE_FISH_PER_SECOND if watched else Automation.OFFLINE_DRONE_FISH_PER_SECOND
	var progress: float = _drone_progress.get(site.location_id, 0.0) + site.drone_count * rate * step
	while progress >= 1.0:
		progress -= 1.0
		var zone := Automation.drone_zone(_state, site, _rng.randi() % site.drone_count)
		var id := Automation.pick_drone_catch(_state, zone, _rng) if zone != null else ""
		if not id.is_empty() and Aquarium.store(site, id) == null and watched:
			_state.add_money(Economy.sale_price(DataRegistry.species[id]))
	_drone_progress[site.location_id] = progress


func _run_sellers(site: Site, step: float) -> void:
	var progress: float = _seller_progress.get(site.location_id, 0.0) + Selling.seller_rate(site) * step
	while progress >= 1.0:
		progress -= 1.0
		var sale := Selling.sell_best(_state, site)
		if sale.is_empty():
			progress = 0.0
		else:
			_seller_earned += sale[1]
	_seller_progress[site.location_id] = progress


func _print(text: String) -> void:
	if not _quiet:
		print(text)


func _event(text: String) -> void:
	_print("%s  %s" % [_clock(), text])


## Prints the state, with the average earnings per minute since the last report.
func _report() -> void:
	var per_minute := (_state.total_earned - _earned_at_report) / (REPORT_EVERY_S / 60.0)
	_earned_at_report = _state.total_earned
	_print("%s  -- coins %s, earning %s/min (sellers %s/min), %d species, at %s" % [
		_clock(), NumberFormat.compact(_state.money), NumberFormat.compact(per_minute),
		NumberFormat.compact(_seller_earned / (REPORT_EVERY_S / 60.0)), _state.species_caught.size(),
		_state.here().location_id])
	_seller_earned = 0.0
	for site: Site in _state.sites.values():
		_print("          %s: tank %d, %d fish, gear %d, net %d, shop %d, %d sellers, %d drones" % [
			site.location_id, site.tank.level, site.tank.fish.size(), site.gear_level, site.net_level, site.shop_level,
			site.seller_count, site.drone_count])


func _clock() -> String:
	return "%3d:%02d" % [int(_time / 60.0), int(_time) % 60]
