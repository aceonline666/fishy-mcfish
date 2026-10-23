class_name Charting
extends RefCounted
## Exploring depth zones. A zone is charted once the player has caught enough fish there and
## every common and uncommon species of the zone. Only charted zones can be automated.

const CATCHES_TO_CHART := 25


## The deepest zone of a location the player's gear allows, or null if none.
static func deepest_open_zone(location_id: String, gear_level: int) -> ZoneDef:
	var deepest: ZoneDef = null
	for zone in DataRegistry.zones_in(location_id):
		if zone.gear_level <= gear_level:
			deepest = zone
	return deepest


## The zone of a location covering a ground y in the water, or null on the beach or beyond
## the last zone.
static func zone_at(location_id: String, ground_y: float) -> ZoneDef:
	for zone in DataRegistry.zones_in(location_id):
		if ground_y >= zone.depth_start and ground_y < zone.depth_end:
			return zone
	return null


## Species of the zone that must be caught to chart it (common and uncommon ones).
static func required_species(zone: ZoneDef) -> Array[String]:
	var required: Array[String] = []
	for id in zone.spawns:
		if DataRegistry.species[id].rarity <= SpeciesDef.Rarity.UNCOMMON:
			required.append(id)
	return required


static func is_charted(state: PlayerState, zone: ZoneDef) -> bool:
	if int(state.zone_catches.get(zone.id, 0)) < CATCHES_TO_CHART:
		return false
	for id in required_species(zone):
		if not state.species_caught.has(id):
			return false
	return true


## Charted zones of all locations, deepest first (drones prefer the most valuable water).
static func charted_zones(state: PlayerState) -> Array[ZoneDef]:
	var charted: Array[ZoneDef] = []
	for zone in DataRegistry.zones:
		if is_charted(state, zone):
			charted.append(zone)
	charted.sort_custom(func(a: ZoneDef, b: ZoneDef) -> bool: return a.order > b.order)
	return charted


## Short progress text, e.g. "charted" or "12/25 fish · 2/3 species".
static func progress_text(state: PlayerState, zone: ZoneDef) -> String:
	if is_charted(state, zone):
		return "charted"
	var required := required_species(zone)
	var found := required.filter(func(id: String) -> bool: return state.species_caught.has(id)).size()
	return "%d/%d fish · %d/%d species" % [
		mini(int(state.zone_catches.get(zone.id, 0)), CATCHES_TO_CHART), CATCHES_TO_CHART, found, required.size()]
