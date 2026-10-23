extends Node
## Holds the live PlayerState. Scenes read from it; player actions go through its command methods
## so the matching EventBus signals are always emitted. Advances the aquarium every sim tick and
## after time away.

var state := PlayerState.new_game()
## Coins the visitors paid while the player was away; shown once, then reset.
var last_offline_earned := 0.0
## Fish the drones stored while the player was away; shown once, then reset.
var last_offline_stored := 0


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


## What the given fish would sell for at the market.
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


## Sells a caught fish at the market and returns the price.
func sell_fish(species_id: String) -> float:
	var price := Economy.sale_price(DataRegistry.species[species_id])
	add_money(price)
	return price


## Hands the income earned so far to a visitor, who brings it to the booth.
func take_pending_income() -> float:
	var amount := state.pending_income
	state.pending_income = 0.0
	return amount


## A visitor pays: into the wallet if a cashier is hired, otherwise onto the pile at the booth.
func receive_visitor_payment(amount: float) -> void:
	if state.has_cashier:
		add_money(amount)
	else:
		add_to_cash_pile(amount)


func add_to_cash_pile(amount: float) -> void:
	state.cash_pile += amount


## Moves the coins at the booth into the wallet and returns how many there were.
func collect_cash() -> float:
	var amount := state.cash_pile
	state.cash_pile = 0.0
	if amount > 0.0:
		add_money(amount)
	return amount


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


func build_next_tank() -> TankState:
	var tank := TankState.new(state.tanks.size(), 1)
	state.tanks.append(tank)
	return tank


func upgrade_tank(tank: TankState) -> void:
	tank.level = mini(tank.level + 1, DataRegistry.tank_levels.size())


func upgrade_backpack() -> void:
	state.backpack_level = mini(state.backpack_level + 1, DataRegistry.backpack_levels.size())


func upgrade_gear() -> void:
	state.gear_level = mini(state.gear_level + 1, DataRegistry.gear_levels.size())


func buy_drone() -> void:
	state.drone_count = mini(state.drone_count + 1, DataRegistry.drone_levels.size())


func hire_cashier() -> void:
	state.has_cashier = true


## Records newly reached goals, pays their rewards and announces them.
func check_achievements() -> void:
	for def in Achievements.newly_reached(state):
		state.achievements.append(def.id)
		if def.reward > 0.0:
			add_money(def.reward)
		EventBus.achievement_reached.emit(def)


func _on_sim_tick(dt: float) -> void:
	Aquarium.advance(state, dt)
	check_achievements()


## While the player was away, drones kept filling the tanks and visitors kept coming.
func _on_offline_progress(seconds: float) -> void:
	last_offline_stored += Automation.run_drones_offline(state, seconds, RandomNumberGenerator.new())
	Aquarium.advance(state, seconds)
	var earned := take_pending_income()
	if earned > 0.0:
		receive_visitor_payment(earned)
		last_offline_earned += earned
