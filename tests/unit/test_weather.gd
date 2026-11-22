extends GutTest


func test_sunny_has_no_clouds_rain_or_wind() -> void:
	var sunny := Weather.target(Weather.Kind.SUNNY, false)
	assert_eq(sunny.overcast, 0.0)
	assert_eq(sunny.rain, 0.0)
	assert_eq(sunny.wind, 0.0)
	assert_eq(sunny.storm, 0.0)
	assert_eq(Weather.tint(sunny), Color.WHITE)


func test_a_storm_is_darker_and_wetter_than_rain() -> void:
	var rain := Weather.target(Weather.Kind.RAIN, false)
	var storm := Weather.target(Weather.Kind.STORM, false)
	assert_gt(rain.rain, 0.0)
	assert_gt(storm.rain, rain.rain)
	assert_gt(storm.wind, rain.wind)
	assert_gt(storm.overcast, rain.overcast)
	assert_lt(Weather.tint(rain).v, 1.0)
	assert_lt(Weather.tint(storm).v, Weather.tint(rain).v)


func test_lightning_only_in_a_storm_or_a_blizzard() -> void:
	assert_false(Weather.lightning(Weather.target(Weather.Kind.RAIN, false)))
	assert_true(Weather.lightning(Weather.target(Weather.Kind.STORM, false)))
	var blizzard := Weather.target(Weather.Kind.STORM, true)
	assert_eq(blizzard.snow, 1.0)
	assert_true(Weather.lightning(blizzard))
	assert_false(Weather.lightning(Weather.target(Weather.Kind.RAIN, true)))


func test_approach_eases_without_overshooting() -> void:
	var state := Weather.target(Weather.Kind.SUNNY, false)
	var goal := Weather.target(Weather.Kind.STORM, false)
	state = Weather.approach(state, goal, Weather.BLEND_S * 0.25)
	assert_almost_eq(state.rain, 0.25, 0.001)
	for i in 10:
		state = Weather.approach(state, goal, Weather.BLEND_S * 0.25)
	assert_eq(state.rain, goal.rain)
	assert_eq(state.wind, goal.wind)
	assert_eq(state.overcast, goal.overcast)


func test_snow_switches_at_once() -> void:
	var state := Weather.approach(Weather.State.new(), Weather.target(Weather.Kind.SUNNY, true), 0.01)
	assert_eq(state.snow, 1.0)


func test_spells_follow_each_other_and_a_storm_only_comes_out_of_rain() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var storms := 0
	for i in 200:
		assert_eq(Weather.next(rng, Weather.Kind.SUNNY)[0], Weather.Kind.RAIN)
		assert_eq(Weather.next(rng, Weather.Kind.STORM)[0], Weather.Kind.RAIN)
		var after_rain: Array = Weather.next(rng, Weather.Kind.RAIN)
		assert_ne(after_rain[0], Weather.Kind.RAIN)
		if after_rain[0] == Weather.Kind.STORM:
			storms += 1
		var spell: Vector2 = Weather.SPELLS[after_rain[0]]
		assert_between(after_rain[1], spell.x, spell.y)
	assert_between(storms, 40, 100)


func test_lightning_flickers_and_ends() -> void:
	assert_gt(Lightning.brightness(0.02), 0.0)
	assert_eq(Lightning.brightness(0.11), 0.0)
	assert_eq(Lightning.brightness(Lightning.DURATION + 0.1), 0.0)
