extends Node
## Holds the live PlayerState. Scenes read from it; player actions go through its command methods
## so the matching EventBus signals are always emitted. Purchases are for the business where the
## player is. Every sim tick, at every location, fish grow and breed, hired sellers sell grown
## fish, and drones of the locations the player is not at keep fishing; the same happens for the
## time the game was closed.

## Time away is played in steps of at least this many seconds, at most OFFLINE_MAX_STEPS of them,
## so tanks breed, fish grow and sellers sell over the whole time.
const OFFLINE_MIN_STEP_S := 60.0
const OFFLINE_MAX_STEPS := 24

## Empty until SaveSystem loads the game (the game data is not loaded yet at this point).
var state := PlayerState.new()
## Coins the sellers earned while the player was away; shown once, then reset.
var last_offline_earned := 0.0
## Fish the drones stored while the player was away; shown once, then reset.
var last_offline_stored := 0

## Progress of each location's sellers towards their next sale, by location id.
var _seller_progress: Dictionary[String, float] = {}
## Progress of the drones at other locations towards their next fish, by "<location id>/<index>".
var _remote_drone_progress: Dictionary[String, float] = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	EventBus.sim_tick.connect(_on_sim_tick)
	EventBus.offline_progress.connect(_on_offline_progress)


func replace_state(new_state: PlayerState) -> void:
	state = new_state
	EventBus.state_replaced.emit()
	EventBus.money_changed.emit(state.money)


func add_money(amount: float) -> void:
	state.add_money(amount)
	EventBus.money_changed.emit(state.money)


func try_spend(amount: float) -> bool:
	if not state.try_spend(amount):
		return false
	EventBus.money_changed.emit(state.money)
	return true


## Records a fish entering the net in the given depth zone. Returns true the first time a
## species is ever caught.
func record_catch(species_id: String, zone_id: String = "") -> bool:
	var is_new := state.record_catch(species_id, zone_id)
	EventBus.fish_caught.emit(species_id, is_new)
	return is_new


func record_best(stat: String, value: int) -> void:
	state.record_best(stat, value)


## What the given fish would sell for fresh from the net.
func catch_value(species_ids: Array[String]) -> float:
	var total := 0.0
	for id in species_ids:
		total += Economy.sale_price(DataRegistry.species[id])
	return total


## The business where the player is.
func here() -> Site:
	return state.here()


## Puts a caught fish into the tank here. Returns the tank, or null if it does not fit.
func store_fish(species_id: String) -> TankState:
	var tank := Aquarium.store(here(), species_id)
	if tank != null:
		EventBus.fish_stored.emit(species_id)
	return tank


## Sells a fish fresh from the backpack and returns the price.
func sell_fish(species_id: String) -> float:
	var price := Economy.sale_price(DataRegistry.species[species_id])
	add_money(price)
	return price


## Sells the most valuable sellable fish from the tank here. Returns [species id, price], or []
## if there was nothing to sell.
func sell_from_tank() -> Array:
	var sale := Selling.sell_best(state, here())
	if not sale.is_empty():
		EventBus.money_changed.emit(state.money)
	return sale


## Pays up to `amount` towards a build square costing `price`. Returns true once fully paid,
## which also clears the progress so the next purchase starts fresh.
func pay_into(square_id: String, amount: float, price: float) -> bool:
	var progress := here().build_progress
	var paid: float = progress.get(square_id, 0.0)
	var payment := minf(minf(amount, price - paid), state.money)
	if payment > 0.0:
		try_spend(payment)
		paid += payment
		progress[square_id] = paid
	if paid >= price - 0.001:
		progress.erase(square_id)
		return true
	return false


## Pays the one-time travel fee and opens a location.
func unlock_location(def: LocationDef) -> bool:
	if not Travel.can_unlock(state, def) or not try_spend(def.travel_cost):
		return false
	state.unlocked_locations.append(def.id)
	return true


func travel_to(def: LocationDef) -> void:
	state.current_location = def.id


func upgrade_tank() -> void:
	here().tank.level = mini(here().tank.level + 1, DataRegistry.tank_levels.size())


func upgrade_backpack() -> void:
	here().backpack_level = mini(here().backpack_level + 1, DataRegistry.backpack_levels.size())


func upgrade_gear() -> void:
	here().gear_level = mini(here().gear_level + 1, DataRegistry.gear_levels.size())


func buy_drone() -> void:
	here().drone_count = mini(here().drone_count + 1, DataRegistry.drone_levels.size())


func upgrade_net() -> void:
	here().net_level = mini(here().net_level + 1, DataRegistry.net_levels.size())


func upgrade_shop() -> void:
	here().shop_level = mini(here().shop_level + 1, DataRegistry.shop_levels.size())


func hire_seller() -> void:
	here().seller_count = mini(here().seller_count + 1, here().shop_level)


## Records newly reached goals, pays their rewards and announces them.
func check_achievements() -> void:
	for def in Achievements.newly_reached(state):
		state.achievements.append(def.id)
		if def.reward > 0.0:
			add_money(def.reward)
		EventBus.achievement_reached.emit(def)


func _on_sim_tick(dt: float) -> void:
	Aquarium.advance(state, dt)
	_run_sellers(dt)
	_run_remote_drones(dt)
	check_achievements()


## The sellers of every location sell grown fish from the tank at their pace. Sales where the
## player is are announced so the scene can show them.
func _run_sellers(dt: float) -> void:
	for site: Site in state.sites.values():
		var key := site.location_id
		var progress: float = _seller_progress.get(key, 0.0) + Selling.seller_rate(site) * dt
		while progress >= 1.0:
			progress -= 1.0
			var sale := Selling.sell_best(state, site)
			if sale.is_empty():
				progress = 0.0
				break
			EventBus.money_changed.emit(state.money)
			if site == here():
				EventBus.fish_sold_by_seller.emit(sale[0], sale[1])
		_seller_progress[key] = progress


## Drones at the locations the player is not at keep fishing at the slower unwatched rate.
## Fish that do not fit are let go.
func _run_remote_drones(dt: float) -> void:
	for site: Site in state.sites.values():
		if site == here():
			continue
		for index in site.drone_count:
			var zone := Automation.drone_zone(state, site, index)
			if zone == null:
				continue
			var key := "%s/%d" % [site.location_id, index]
			var progress: float = _remote_drone_progress.get(key, 0.0) + Automation.OFFLINE_DRONE_FISH_PER_SECOND * dt
			if progress >= 1.0:
				progress -= 1.0
				var species_id := Automation.pick_drone_catch(state, zone, _rng)
				if not species_id.is_empty() and Aquarium.store(site, species_id) != null:
					EventBus.fish_stored.emit(species_id)
			_remote_drone_progress[key] = progress


## While the player was away, drones kept filling the tanks, fish grew and sellers kept selling.
func _on_offline_progress(seconds: float) -> void:
	var rng := RandomNumberGenerator.new()
	var steps := clampi(ceili(seconds / OFFLINE_MIN_STEP_S), 1, OFFLINE_MAX_STEPS)
	var step := seconds / steps
	var earned := 0.0
	for i in steps:
		last_offline_stored += Automation.run_drones_offline(state, step, rng)
		Aquarium.advance(state, step)
		earned += Selling.run_sellers(state, step)
	if earned > 0.0:
		last_offline_earned += earned
		EventBus.money_changed.emit(state.money)
