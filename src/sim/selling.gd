class_name Selling
extends RefCounted
## Selling fish at a location's shop. Each shop level buys the fish of one more depth zone (shop
## level N buys SpeciesDef.shop_tier 1 to N). The player sells by standing on the shop's "Sell
## fish" pad; the sellers hired for the shop sell on their own, at every location, also while
## the game is closed. From the tank only grown fish are sold, and a breeding pair of each
## species stays in it.

## Fish of a species that stay in the tank to breed.
const BREEDING_PAIR := 2


## The shop level that starts buying a species: 1 for fish of the first zone.
static func tier_of(species_id: String) -> int:
	return DataRegistry.species[species_id].shop_tier


## True if the site's shop buys this species.
static func has_shop_for(site: Site, species_id: String) -> bool:
	return tier_of(species_id) <= site.shop_level


## Index of the most valuable grown fish in the tank that the shop buys and that is not needed
## for breeding, or -1 if none.
static func best_fish(site: Site) -> int:
	var tank := site.tank
	var counts: Dictionary[String, int] = {}
	for fish in tank.fish:
		counts[fish.species_id] = counts.get(fish.species_id, 0) + 1
	var best := -1
	var best_price := -1.0
	for i in tank.fish.size():
		var fish := tank.fish[i]
		if fish.growth < 1.0 or counts[fish.species_id] <= BREEDING_PAIR or not has_shop_for(site, fish.species_id):
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


## Fish in the tank that the shop does not buy yet.
static func unsellable_count(site: Site) -> int:
	var count := 0
	for fish in site.tank.fish:
		if not has_shop_for(site, fish.species_id):
			count += 1
	return count


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
