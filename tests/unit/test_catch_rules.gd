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


func test_body_size_is_capped_for_giants() -> void:
	assert_eq(CatchRules.body_length_px(_species(1200.0)), CatchRules.MAX_BODY_PX)


func test_only_small_fish_school() -> void:
	var rng := RandomNumberGenerator.new()
	assert_between(CatchRules.school_size(_species(12.0), rng), 3, 5)
	assert_eq(CatchRules.school_size(_species(60.0), rng), 1)


func test_combo_names() -> void:
	assert_eq(CatchRules.combo_name(1), "")
	assert_eq(CatchRules.combo_name(2), "Double!")
	assert_eq(CatchRules.combo_name(4), "Quad!")
	assert_eq(CatchRules.combo_name(9), CatchRules.MEGA_COMBO_NAME)
