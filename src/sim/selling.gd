class_name Selling
extends RefCounted
## Selling fish at the shops. Shop N sells the fish of depth zone N (SpeciesDef.shop_tier), so a
## deeper zone's catch needs another shop. The player sells by standing on a shop's "Sell fish"
## square; the seller hired for a shop sells that shop's fish from the tanks on their own, also
## while the game is closed.


## The shop tier selling a species: 1 for the first shop, 2 for the second, ...
static func tier_of(species_id: String) -> int:
	return DataRegistry.species[species_id].shop_tier


## True if one of the built shops sells this species.
static func has_shop_for(state: PlayerState, species_id: String) -> bool:
	return tier_of(species_id) <= state.shop_count


## The most valuable fish of a shop tier in the tanks as [tank, fish index], or [] if none.
static func best_fish(state: PlayerState, tier: int) -> Array:
	var best: Array = []
	var best_price := -1.0
	for tank in state.tanks:
		for i in tank.fish.size():
			var fish := tank.fish[i]
			if tier_of(fish.species_id) != tier:
				continue
			var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
			if price > best_price:
				best = [tank, i]
				best_price = price
	return best


## Sells the most valuable fish of a shop tier from the tanks. Returns [species id, price, tank],
## or [] if there was nothing to sell. Adds the coins to the state.
static func sell_best(state: PlayerState, tier: int) -> Array:
	var choice := best_fish(state, tier)
	if choice.is_empty():
		return []
	var tank: TankState = choice[0]
	var fish: TankFish = tank.fish[choice[1]]
	tank.fish.remove_at(choice[1])
	var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
	state.add_money(price)
	return [fish.species_id, price, tank]


## Fish in the tanks that none of the built shops sells.
static func unsellable_count(state: PlayerState) -> int:
	var count := 0
	for tank in state.tanks:
		for fish in tank.fish:
			if not has_shop_for(state, fish.species_id):
				count += 1
	return count


## Fish per second the seller of the shop with this tier sells; 0 if none is hired there.
static func seller_rate(state: PlayerState, tier: int) -> float:
	if tier > state.seller_count or tier > DataRegistry.staff_levels.size():
		return 0.0
	return DataRegistry.staff_levels[tier - 1].capacity / 60.0


## Sellers at work for `seconds` (offline). Returns the coins earned.
static func run_sellers(state: PlayerState, seconds: float) -> float:
	var earned := 0.0
	for tier in range(1, state.seller_count + 1):
		for i in int(seller_rate(state, tier) * seconds):
			var sale := sell_best(state, tier)
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
