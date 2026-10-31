class_name Selling
extends RefCounted
## Selling fish at a location's shop. The shop buys every fish; each shop level makes room for one
## more seller. The player sells by standing on the shop's "Quick sale" pad; the sellers sell on
## their own, at every location, also while the game is closed. From the tank only grown fish are
## sold, and a breeding pair of each species stays in it, unless the tank is too full to breed:
## then pairs are sold too, so it never fills up with fish that nobody sells.

## Fish of a species that stay in the tank to breed.
const BREEDING_PAIR := 2


## Index of the most valuable grown fish in the tank that may be sold, or -1 if none.
static func best_fish(site: Site) -> int:
	var tank := site.tank
	var counts: Dictionary[String, int] = {}
	for fish in tank.fish:
		counts[fish.species_id] = counts.get(fish.species_id, 0) + 1
	var crowded := Aquarium.used_space(tank) >= Aquarium.capacity(tank) * Aquarium.BREED_FILL
	var best := -1
	var best_price := -1.0
	for i in tank.fish.size():
		var fish := tank.fish[i]
		if fish.growth < 1.0 or (counts[fish.species_id] <= BREEDING_PAIR and not crowded):
			continue
		var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
		if price > best_price:
			best = i
			best_price = price
	return best


## Sells the most valuable sellable fish from the tank. Returns [species id, price], or [] if
## there was nothing to sell. Adds the coins to the state.
static func sell_best(state: PlayerState, site: Site) -> Array:
	var index := best_fish(site)
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
			var sale := sell_best(state, site)
			if sale.is_empty():
				break
			earned += sale[1]
	return earned


## Price of the next shop level, or -1 at the top level.
static func shop_upgrade_cost(site: Site) -> float:
	var levels := DataRegistry.shop_levels
	return levels[site.shop_level].cost * site.price_factor() if site.shop_level < levels.size() else -1.0


## Price of the next seller, or -1 if the shop has as many as its level allows (or all are hired).
static func next_seller_cost(site: Site) -> float:
	if site.seller_count >= site.shop_level or site.seller_count >= DataRegistry.staff_levels.size():
		return -1.0
	return DataRegistry.staff_levels[site.seller_count].cost * site.price_factor()
