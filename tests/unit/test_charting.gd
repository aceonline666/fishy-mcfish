extends GutTest
## Depth zones and charting.

const HOME := "north_sea"


func _zone(zone_id: String) -> ZoneDef:
	for zone in DataRegistry.zones:
		if zone.id == zone_id:
			return zone
	return null


func test_zones_line_up_from_the_shore_in_each_location() -> void:
	for location in DataRegistry.locations:
		var zones := DataRegistry.zones_in(location.id)
		assert_gt(zones.size(), 1, location.id)
		assert_eq(zones[0].depth_start, 0.0)
		assert_eq(Charting.zone_at(location.id, 10.0), zones[0])
		assert_eq(Charting.zone_at(location.id, zones[1].depth_start + 1.0), zones[1])
		assert_null(Charting.zone_at(location.id, -50.0), "the beach is not a zone")


func test_better_gear_opens_deeper_zones() -> void:
	var zones := DataRegistry.zones_in(HOME)
	assert_eq(Charting.deepest_open_zone(HOME, 1), zones[0])
	assert_eq(Charting.deepest_open_zone(HOME, DataRegistry.gear_levels.size()), zones[-1])


func test_charting_needs_catches_and_every_common_species() -> void:
	var zone := _zone("pier_shallows")
	var state := PlayerState.new_game()
	for i in Charting.CATCHES_TO_CHART:
		state.record_catch("european_sprat", zone.id)
	assert_false(Charting.is_charted(state, zone), "still missing species")
	for id in Charting.required_species(zone):
		state.record_catch(id, zone.id)
	assert_true(Charting.is_charted(state, zone))
	assert_eq(Charting.progress_text(state, zone), "charted")


func test_rare_species_are_not_required() -> void:
	var required := Charting.required_species(_zone("pier_shallows"))
	assert_has(required, "european_sprat")
	assert_has(required, "atlantic_mackerel", "uncommon counts")
	assert_does_not_have(Charting.required_species(_zone("wreck")), "conger_eel")
