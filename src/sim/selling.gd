class_name Selling
extends RefCounted
## Selling fish at a location's shops. Shop N sells the fish of depth zone N
## (SpeciesDef.shop_tier), so a deeper zone's catch needs another shop. The player sells by
## standing on a shop's "Sell fish" pad; the seller hired for a shop sells that shop's fish from
## the tanks on their own, at every location, also while the game is closed.


## The shop tier selling a species: 1 for the first shop, 2 for the second, ...
static func tier_of(species_id: String) -> int:
	return DataRegistry.species[species_id].shop_tier


## True if one of the site's built shops sells this species.
static func has_shop_for(site: Site, species_id: String) -> bool:
	return tier_of(species_id) <= site.shop_count


## The most valuable fish of a shop tier in the tanks as [tank, fish index], or [] if none.
static func best_fish(site: Site, tier: int) -> Array:
	var best: Array = []
	var best_price := -1.0
	for tank in site.tanks:
		for i in tank.fish.size():
			var fish := tank.fish[i]
			if tier_of(fish.species_id) != tier:
				continue
			var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
			if price > best_price:
				best = [tank, i]
				best_price = price
	return best


## Sells the most valuable fish of a shop tier from the site's tanks. Returns
## [species id, price, tank], or [] if there was nothing to sell. Adds the coins to the state.
static func sell_best(state: PlayerState, site: Site, tier: int) -> Array:
	var choice := best_fish(site, tier)
	if choice.is_empty():
		return []
	var tank: TankState = choice[0]
	var fish: TankFish = tank.fish[choice[1]]
	tank.fish.remove_at(choice[1])
	var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
	state.add_money(price)
	return [fish.species_id, price, tank]


## Fish in the site's tanks that none of its shops sells.
static func unsellable_count(site: Site) -> int:
	var count := 0
	for tank in site.tanks:
		for fish in tank.fish:
			if not has_shop_for(site, fish.species_id):
				count += 1
	return count


## Fish per second the seller of the site's shop with this tier sells; 0 if none is hired.
static func seller_rate(site: Site, tier: int) -> float:
	if tier > site.seller_count or tier > DataRegistry.staff_levels.size():
		return 0.0
	return DataRegistry.staff_levels[tier - 1].capacity / 60.0


## The sellers of every location at work for `seconds` (offline). Returns the coins earned.
static func run_sellers(state: PlayerState, seconds: float) -> float:
	var earned := 0.0
	for site: Site in state.sites.values():
		for tier in range(1, site.seller_count + 1):
			for i in int(seller_rate(site, tier) * seconds):
				var sale := sell_best(state, site, tier)
				if sale.is_empty():
					break
				earned += sale[1]
	return earned


## Price of the next shop, or -1 when all are built.
static func next_shop_cost(site: Site) -> float:
	var slots := DataRegistry.shop_slots
	return slots[site.shop_count].cost * site.price_factor() if site.shop_count < slots.size() else -1.0


## Price of the next seller, or -1 if every shop already has one (or all are hired).
static func next_seller_cost(site: Site) -> float:
	if site.seller_count >= site.shop_count or site.seller_count >= DataRegistry.staff_levels.size():
		return -1.0
	return DataRegistry.staff_levels[site.seller_count].cost * site.price_factor()
