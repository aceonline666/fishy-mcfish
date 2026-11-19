extends GutTest


func _species(length_cm: float, rarity: SpeciesDef.Rarity = SpeciesDef.Rarity.COMMON) -> SpeciesDef:
	var def := SpeciesDef.new()
	def.length_cm = length_cm
	def.rarity = rarity
	return def


func test_small_fish_are_caught_instantly() -> void:
	assert_eq(CatchRules.struggle_seconds(_species(12.0)), 0.0)
	assert_eq(CatchRules.struggle_seconds(_species(24.9)), 0.0)


func test_struggle_grows_with_size_and_is_capped() -> void:
	var medium := CatchRules.struggle_seconds(_species(30.0))
	var large := CatchRules.struggle_seconds(_species(100.0))
	assert_almost_eq(medium, CatchRules.MIN_STRUGGLE_S, 0.1)
	assert_gt(large, medium)
	assert_eq(CatchRules.struggle_seconds(_species(400.0)), CatchRules.MAX_STRUGGLE_S)


func test_rarer_fish_struggle_longer_and_swim_faster() -> void:
	var common := _species(60.0)
	var epic := _species(60.0, SpeciesDef.Rarity.EPIC)
	assert_gt(CatchRules.struggle_seconds(epic), CatchRules.struggle_seconds(common))
	assert_gt(CatchRules.cruise_speed(epic), CatchRules.cruise_speed(common))


func test_better_nets_land_big_fish_faster() -> void:
	var cod := _species(100.0)
	assert_almost_eq(CatchRules.struggle_seconds(cod, 2.0), CatchRules.struggle_seconds(cod) / 2.0, 0.0001)
	assert_eq(CatchRules.struggle_seconds(_species(12.0), 2.0), 0.0)


func test_body_size_is_capped_for_giants() -> void:
	assert_eq(CatchRules.body_length(_species(3000.0)), CatchRules.MAX_BODY_LENGTH)
	assert_lte(CatchRules.cruise_speed(_species(3000.0)), CatchRules.MAX_CRUISE_SPEED, "giants cruise")


func test_jellyfish_and_crabs_move_slower_than_fish_of_their_size() -> void:
	var fish := _species(370.0, SpeciesDef.Rarity.RARE)
	var crab := _species(370.0, SpeciesDef.Rarity.RARE)
	crab.id = "japanese_spider_crab"
	var jelly := _species(30.0)
	jelly.id = "moon_jellyfish"
	assert_lt(CatchRules.cruise_speed(crab), CatchRules.cruise_speed(fish) * 0.5)
	assert_lt(CatchRules.cruise_speed(jelly), CatchRules.cruise_speed(_species(30.0)) * 0.5)


func test_only_small_fish_school() -> void:
	var rng := RandomNumberGenerator.new()
	assert_between(CatchRules.school_size(_species(12.0), rng), 3, 5)
	assert_eq(CatchRules.school_size(_species(60.0), rng), 1)


func test_combo_names() -> void:
	assert_eq(CatchRules.combo_name(1), "")
	assert_eq(CatchRules.combo_name(2), "Double!")
	assert_eq(CatchRules.combo_name(4), "Quad!")
	assert_eq(CatchRules.combo_name(9), "Mega haul!")


func test_giants_grow_in_a_straight_line_past_two_meters() -> void:
	var at_two := CatchRules.body_length(_species(CatchRules.GIANT_FROM_CM))
	assert_almost_eq(CatchRules.body_length(_species(CatchRules.GIANT_FROM_CM + 1.0)), at_two, 1.0, "no jump at the bend")
	var great_white := CatchRules.body_length(_species(450.0))
	var blue_whale := CatchRules.body_length(_species(2500.0))
	assert_gt(blue_whale, great_white * 3.5, "a blue whale dwarfs a great white")
	assert_eq(CatchRules.compact_length(_species(50.0)), CatchRules.body_length(_species(50.0)), "small fish unchanged")
	assert_lte(CatchRules.compact_length(_species(2500.0)), CatchRules.MAX_COMPACT_LENGTH, "tanks keep the gentle curve")


func test_dolphins_come_in_pods_of_at_least_three() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 20:
		assert_between(CatchRules.school_size(DataRegistry.species["common_bottlenose_dolphin"], rng), 3, 5)
