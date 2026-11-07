class_name Treasure
extends RefCounted
## The secret treasure chest: one per location, lying on the seabed of the deepest zone the gear
## opens. The wader scoops it up like a fish; it pays a fortune and is gone until COOLDOWN_S
## later, when it turns up somewhere else. Not shown during the tutorial.

## Seconds until a found chest turns up again: a little less than a day, so a daily visit finds
## it.
const COOLDOWN_S := 20 * 3600
## A chest holds the price of this many grown fish of its zone...
const CHEST_FISH := 25.0
## ...plus what the location's sellers make in this many seconds, so it stays worth finding later.
const INCOME_S := 300.0
## The chest keeps this far from the zone's edges (ground units).
const EDGE_MARGIN := 150.0


## True when the location's chest is waiting to be found.
static func is_ready(state: PlayerState, location_id: String, now_unix: int) -> bool:
	if not Tutorial.is_done(state):
		return false
	return not state.chest_found_at.has(location_id) or now_unix >= state.chest_found_at[location_id] + COOLDOWN_S


## Where the chest lies in the zone's area: the same spot until it is found, a new one after.
static func spot(state: PlayerState, location_id: String, zone: ZoneDef, area: PlayArea) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([location_id, zone.id, int(state.stats.get("chests_found", 0))])
	return area.random_point(rng, EDGE_MARGIN)


## Coins in a chest found in the zone, at the site's beach.
static func reward(site: Site, zone: ZoneDef) -> float:
	var weight := 0.0
	var value := 0.0
	for id in zone.spawns:
		weight += zone.spawns[id]
		value += zone.spawns[id] * Economy.sale_price(DataRegistry.species[id], 1.0)
	var price := value / weight if weight > 0.0 else 0.0
	return roundf(price * (CHEST_FISH + Selling.seller_rate(site) * INCOME_S))


## Records the chest of a location as found now.
static func record_find(state: PlayerState, location_id: String, now_unix: int) -> void:
	state.chest_found_at[location_id] = now_unix
	state.increment_stat("chests_found")
