extends Node
## Holds the live PlayerState. Scenes read from it; player actions go through its command methods
## so the matching EventBus signals are always emitted. Every sim tick fish grow and hired sellers
## sell their shop's fish; the same happens for the time the game was closed.

var state := PlayerState.new_game()
## Coins the sellers earned while the player was away; shown once, then reset.
var last_offline_earned := 0.0
## Fish the drones stored while the player was away; shown once, then reset.
var last_offline_stored := 0

## Progress of each shop's seller towards their next sale, by shop index.
var _seller_progress: Array[float] = []


func _ready() -> void:
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


## Puts a caught fish into the first tank with room. Returns the tank, or null if none fits.
func store_fish(species_id: String) -> TankState:
	var tank := Aquarium.store(state, species_id)
	if tank != null:
		EventBus.fish_stored.emit(species_id)
	return tank


## Sells a fish fresh from the backpack and returns the price.
func sell_fish(species_id: String) -> float:
	var price := Economy.sale_price(DataRegistry.species[species_id])
	add_money(price)
	return price


## Sells the most valuable fish a shop tier takes from the tanks. Returns
## [species id, price, tank], or [] if there was nothing to sell.
func sell_from_tanks(tier: int) -> Array:
	var sale := Selling.sell_best(state, tier)
	if not sale.is_empty():
		EventBus.money_changed.emit(state.money)
	return sale


## Pays up to `amount` towards a build square costing `price`. Returns true once fully paid,
## which also clears the progress so the next purchase starts fresh.
func pay_into(square_id: String, amount: float, price: float) -> bool:
	var paid: float = state.build_progress.get(square_id, 0.0)
	var payment := minf(minf(amount, price - paid), state.money)
	if payment > 0.0:
		try_spend(payment)
		paid += payment
		state.build_progress[square_id] = paid
	if paid >= price - 0.001:
		state.build_progress.erase(square_id)
		return true
	return false


## Builds a tank in the next free slot for the environment.
func build_next_tank(env: String = "temperate") -> TankState:
	var tank := TankState.new(Aquarium.next_slot(state, env), 1)
	state.tanks.append(tank)
	state.tanks.sort_custom(func(a: TankState, b: TankState) -> bool: return a.slot < b.slot)
	return tank


## Pays the one-time travel fee and opens a location.
func unlock_location(def: LocationDef) -> bool:
	if not Travel.can_unlock(state, def) or not try_spend(def.travel_cost):
		return false
	state.unlocked_locations.append(def.id)
	return true


func travel_to(def: LocationDef) -> void:
	state.current_location = def.id


func upgrade_tank(tank: TankState) -> void:
	tank.level = mini(tank.level + 1, DataRegistry.tank_levels.size())


func upgrade_backpack() -> void:
	state.backpack_level = mini(state.backpack_level + 1, DataRegistry.backpack_levels.size())


func upgrade_gear() -> void:
	state.gear_level = mini(state.gear_level + 1, DataRegistry.gear_levels.size())


func buy_drone() -> void:
	state.drone_count = mini(state.drone_count + 1, DataRegistry.drone_levels.size())


func upgrade_net() -> void:
	state.net_level = mini(state.net_level + 1, DataRegistry.net_levels.size())


func build_shop() -> void:
	state.shop_count = mini(state.shop_count + 1, DataRegistry.shop_slots.size())


func hire_seller() -> void:
	state.seller_count = mini(state.seller_count + 1, state.shop_count)


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
	check_achievements()


## Each hired seller sells their shop's fish from the tanks at their pace.
func _run_sellers(dt: float) -> void:
	_seller_progress.resize(state.seller_count)
	for i in state.seller_count:
		_seller_progress[i] += Selling.seller_rate(state, i + 1) * dt
		while _seller_progress[i] >= 1.0:
			_seller_progress[i] -= 1.0
			var sale := sell_from_tanks(i + 1)
			if sale.is_empty():
				_seller_progress[i] = 0.0
				break
			EventBus.fish_sold_by_seller.emit(sale[0], sale[1])


## While the player was away, drones kept filling the tanks, fish grew and sellers kept selling.
func _on_offline_progress(seconds: float) -> void:
	last_offline_stored += Automation.run_drones_offline(state, seconds, RandomNumberGenerator.new())
	Aquarium.advance(state, seconds)
	var earned := Selling.run_sellers(state, seconds)
	if earned > 0.0:
		last_offline_earned += earned
		EventBus.money_changed.emit(state.money)
