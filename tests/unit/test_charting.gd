extends GutTest
## Depth zones and charting.


func _zone(zone_id: String) -> ZoneDef:
	for zone in DataRegistry.zones:
		if zone.id == zone_id:
			return zone
	return null


func test_zones_line_up_from_the_shore() -> void:
	assert_gt(DataRegistry.zones.size(), 1)
	assert_eq(DataRegistry.zones[0].depth_start, 0.0)
	assert_eq(Charting.zone_at(10.0), DataRegistry.zones[0])
	assert_eq(Charting.zone_at(DataRegistry.zones[1].depth_start + 1.0), DataRegistry.zones[1])
	assert_null(Charting.zone_at(-50.0), "the beach is not a zone")


func test_better_gear_opens_deeper_zones() -> void:
	assert_eq(Charting.deepest_open_zone(1), DataRegistry.zones[0])
	assert_eq(Charting.deepest_open_zone(DataRegistry.gear_levels.size()), DataRegistry.zones[-1])


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
