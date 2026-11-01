class_name Selling
extends RefCounted
## Selling fish at a location's shop. The shop buys every fish; each shop level has booths for
## more sellers (data/shop_levels.csv: capacity), up to 15 in the seafood palace. The player sells by standing on the shop's "Sell fish" pad; the sellers sell on
## their own, at every location, also while the game is closed. From the tank only grown fish are
## sold; the drones fill the space up again.


## Index of the grown fish in the tank that is sold next, or -1 if none: the one that grew up
## first (Aquarium.advance keeps the grown fish in the order they grew up).
static func next_to_sell(site: Site) -> int:
	for i in site.tank.fish.size():
		if site.tank.fish[i].growth >= 1.0:
			return i
	return -1


## Sells the grown fish that grew up first. Returns [species id, price], or [] if there was
## nothing to sell. Adds the coins to the state.
static func sell_next(state: PlayerState, site: Site) -> Array:
	var index := next_to_sell(site)
	if index < 0:
		return []
	var fish: TankFish = site.tank.fish[index]
	site.tank.fish.remove_at(index)
	var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
	state.add_money(price)
	return [fish.species_id, price]


## Fish per second the site's sellers sell together; 0 if none is hired.
static func seller_rate(site: Site) -> float:
	var per_minute := 0.0
	for i in mini(site.seller_count, DataRegistry.staff_levels.size()):
		per_minute += DataRegistry.staff_levels[i].capacity
	return per_minute / 60.0


## The sellers of every location at work for `seconds` (offline). Returns the coins earned.
static func run_sellers(state: PlayerState, seconds: float) -> float:
	var earned := 0.0
	for site: Site in state.sites.values():
		for i in int(seller_rate(site) * seconds):
			var sale := sell_next(state, site)
			if sale.is_empty():
				break
			earned += sale[1]
	return earned


## How many sellers the shop has booths for at its level.
static func seller_slots(site: Site) -> int:
	return int(DataRegistry.shop_levels[clampi(site.shop_level, 1, DataRegistry.shop_levels.size()) - 1].capacity)


## Price of the next shop level, or -1 at the top level.
static func shop_upgrade_cost(site: Site) -> float:
	var levels := DataRegistry.shop_levels
	return levels[site.shop_level].cost * site.price_factor() if site.shop_level < levels.size() else -1.0


## Price of the next seller, or -1 if the shop has as many as its level allows (or all are hired).
static func next_seller_cost(site: Site) -> float:
	if site.seller_count >= seller_slots(site) or site.seller_count >= DataRegistry.staff_levels.size():
		return -1.0
	return DataRegistry.staff_levels[site.seller_count].cost * site.price_factor()
