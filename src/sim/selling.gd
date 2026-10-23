class_name Selling
extends RefCounted
## Selling fish at the shops: by the player standing on a shop's "Sell fish" square, or by hired
## sellers who sell grown fish from the tanks on their own, also while the game is closed.


## The most valuable fish in the tanks as [tank, fish index], or [] if none qualifies.
## Sellers only take adults; the player sells anything.
static func best_fish(state: PlayerState, adults_only: bool) -> Array:
	var best: Array = []
	var best_price := -1.0
	for tank in state.tanks:
		for i in tank.fish.size():
			var fish := tank.fish[i]
			if adults_only and fish.growth < 1.0:
				continue
			var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
			if price > best_price:
				best = [tank, i]
				best_price = price
	return best


## Sells the most valuable qualifying fish from the tanks. Returns [species id, price, tank],
## or [] if there was nothing to sell. Adds the coins to the state.
static func sell_best(state: PlayerState, adults_only: bool) -> Array:
	var choice := best_fish(state, adults_only)
	if choice.is_empty():
		return []
	var tank: TankState = choice[0]
	var fish: TankFish = tank.fish[choice[1]]
	tank.fish.remove_at(choice[1])
	var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
	state.add_money(price)
	return [fish.species_id, price, tank]


## Adult fish per second all hired sellers together sell.
static func seller_rate(state: PlayerState) -> float:
	var per_minute := 0.0
	for i in mini(state.seller_count, DataRegistry.staff_levels.size()):
		per_minute += DataRegistry.staff_levels[i].capacity
	return per_minute / 60.0


## Sellers at work for `seconds` (offline). Returns the coins earned.
static func run_sellers(state: PlayerState, seconds: float) -> float:
	var earned := 0.0
	for i in int(seller_rate(state) * seconds):
		var sale := sell_best(state, true)
		if sale.is_empty():
			break
		earned += sale[1]
	return earned


## Price of the next shop, or -1 when all are built.
static func next_shop_cost(state: PlayerState) -> float:
	var slots := DataRegistry.shop_slots
	return slots[state.shop_count].cost if state.shop_count < slots.size() else -1.0


## Price of the next seller, or -1 if every shop already has one (or all are hired).
static func next_seller_cost(state: PlayerState) -> float:
	if state.seller_count >= state.shop_count or state.seller_count >= DataRegistry.staff_levels.size():
		return -1.0
	return DataRegistry.staff_levels[state.seller_count].cost
