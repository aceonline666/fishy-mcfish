class_name Treasure
extends RefCounted
## The secret treasure chest: one per location, lying on the seabed of the deepest zone the gear
## opens, at most MAX_ZONE_ORDER (further out the dark water hides it). The wader scoops it up
## like a fish; it pays the location's fixed treasure (`treasure` in data/locations.csv), more at
## every location further on, and is gone until COOLDOWN_S later, when it turns up somewhere
## else. Not shown during the tutorial.

## Seconds until a found chest turns up again: a little less than a day, so a daily visit finds
## it.
const COOLDOWN_S := 20 * 3600
## The deepest zone the chest lies in: beyond it the water is too dark to see it.
const MAX_ZONE_ORDER := 4
## The chest keeps this far from the zone's edges (ground units).
const EDGE_MARGIN := 150.0


## True when the location's chest is waiting to be found.
static func is_ready(state: PlayerState, location_id: String, now_unix: int) -> bool:
	if not Tutorial.is_done(state):
		return false
	return not state.chest_found_at.has(location_id) or now_unix >= state.chest_found_at[location_id] + COOLDOWN_S


## The zone of a location the chest lies in with the gear: the deepest open one, at most
## MAX_ZONE_ORDER; null if none is open.
static func zone(location_id: String, gear_level: int) -> ZoneDef:
	var deepest: ZoneDef = null
	for candidate in DataRegistry.zones_in(location_id):
		if candidate.gear_level <= gear_level and candidate.order <= MAX_ZONE_ORDER:
			deepest = candidate
	return deepest


## Where the chest lies in the zone's area: the same spot until it is found, a new one after.
static func spot(state: PlayerState, location_id: String, zone: ZoneDef, area: PlayArea) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([location_id, zone.id, int(state.stats.get("chests_found", 0))])
	return area.random_point(rng, EDGE_MARGIN)


## Coins in the chest of a location: the same every time, whatever the zone or the business.
static func reward(location_id: String) -> float:
	return DataRegistry.location(location_id).treasure


## Records the chest of a location as found now.
static func record_find(state: PlayerState, location_id: String, now_unix: int) -> void:
	state.chest_found_at[location_id] = now_unix
	state.increment_stat("chests_found")
