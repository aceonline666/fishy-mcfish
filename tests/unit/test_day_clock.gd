extends GutTest


func test_fast_cycle_starts_in_the_morning() -> void:
	assert_almost_eq(DayClock.fast_hour(0.0), DayClock.DAWN.y, 0.001)


func test_fast_cycle_runs_through_day_dusk_night_and_dawn() -> void:
	var day := DayClock.FAST_PARTS[0]
	var dusk := DayClock.FAST_PARTS[1]
	var night := DayClock.FAST_PARTS[2]
	assert_almost_eq(DayClock.fast_hour(day), DayClock.DUSK.x, 0.001)
	assert_almost_eq(DayClock.fast_hour(day + dusk), DayClock.DUSK.y, 0.001)
	# Midnight is half way through the night.
	assert_almost_eq(DayClock.fast_hour(day + dusk + night * 0.5), 1.0, 0.001)
	assert_almost_eq(DayClock.fast_hour(day + dusk + night), DayClock.DAWN.x, 0.001)


func test_fast_cycle_takes_twenty_minutes_and_repeats() -> void:
	var total := 0.0
	for part in DayClock.FAST_PARTS:
		total += part
	assert_eq(total, DayClock.FAST_CYCLE_S)
	assert_eq(DayClock.FAST_CYCLE_S, 1200.0)
	assert_almost_eq(DayClock.fast_hour(1234.0), DayClock.fast_hour(34.0), 0.001)


func test_clock_hour_reads_minutes_and_seconds() -> void:
	assert_almost_eq(DayClock.clock_hour({"hour": 22, "minute": 30, "second": 0}), 22.5, 0.001)


func test_darkness_is_zero_by_day_and_one_at_night() -> void:
	assert_eq(DayClock.darkness(12.0), 0.0)
	assert_eq(DayClock.darkness(23.0), 1.0)
	assert_eq(DayClock.darkness(2.0), 1.0)
	var mid_dusk := DayClock.darkness(20.5)
	assert_between(mid_dusk, 0.01, 0.99)


func test_tint_is_white_by_day_and_blue_at_night() -> void:
	assert_eq(DayClock.tint(12.0), Color.WHITE)
	assert_eq(DayClock.tint(0.5), DayClock.NIGHT_TINT)
	assert_true(DayClock.NIGHT_TINT.b > DayClock.NIGHT_TINT.r, "night is blue")
	# Half way through dusk the sunset gold shows.
	assert_eq(DayClock.tint(lerpf(DayClock.DUSK.x, DayClock.DUSK.y, 0.5)), DayClock.DUSK_TINT)


func test_always_day_and_always_night_hold_the_time() -> void:
	var chosen := Settings.day_cycle
	Settings.day_cycle = Settings.DAY_CYCLE_DAY
	assert_eq(DayCycle.darkness(), 0.0)
	assert_eq(DayCycle.tint(), Color.WHITE)
	Settings.day_cycle = Settings.DAY_CYCLE_NIGHT
	assert_eq(DayCycle.darkness(), 1.0)
	assert_eq(DayCycle.tint(), DayClock.NIGHT_TINT)
	Settings.day_cycle = chosen


func test_tint_has_no_jumps() -> void:
	var previous := DayClock.tint(0.0)
	var largest := 0.0
	for step in range(1, 24 * 60 + 1):
		var current := DayClock.tint(step / 60.0)
		largest = maxf(largest, absf(current.r - previous.r) + absf(current.g - previous.g) + absf(current.b - previous.b))
		previous = current
	assert_lt(largest, 0.05, "largest change from one minute to the next")


func test_sun_glitters_over_the_sea_at_noon() -> void:
	var glint := DayClock.glint(12.0 + 1.0)
	assert_gt(glint.color.a, 0.0)
	assert_gt(glint.height, 0.9)
	# Out over the sea (ground +y), not along the beach.
	assert_gt(glint.direction.y, 0.9)


func test_low_sun_glitters_in_a_long_warm_path() -> void:
	var noon := DayClock.glint(13.0)
	var evening := DayClock.glint(19.5)
	assert_lt(evening.height, 0.4)
	assert_gt(evening.color.a, noon.color.a)
	# Gold: less blue than the noon sun's glints.
	assert_lt(evening.color.b, noon.color.b - 0.2)


func test_sun_rises_and_sets_on_opposite_sides() -> void:
	var morning := DayClock.glint(7.0).direction
	var evening := DayClock.glint(19.0).direction
	# Out over the sea both times, from opposite ends of the beach.
	assert_gt(morning.y, 0.0)
	assert_gt(evening.y, 0.0)
	assert_lt(morning.x * evening.x, 0.0)


func test_moon_glitters_at_night() -> void:
	var glint := DayClock.glint(1.0)
	assert_almost_eq(glint.color.b, DayClock.MOON_GLINT.b, 0.001)
	assert_gt(glint.color.a, 0.5)
	assert_gt(glint.height, 0.5)


func test_glint_direction_is_a_unit_vector() -> void:
	for hour in range(24):
		assert_almost_eq(DayClock.glint(float(hour)).direction.length(), 1.0, 0.001)


func test_a_new_game_starts_in_daylight_and_the_day_runs_on_without_a_jump() -> void:
	var original := GameState.state
	var chosen := Settings.day_cycle
	Settings.day_cycle = Settings.DAY_CYCLE_FAST
	GameState.replace_state(PlayerState.new_game())
	assert_true(GameState.is_discovering())
	assert_almost_eq(DayCycle.hour(), DayClock.DAWN.y, 0.001, "the morning of the first minute")
	for i in int(PlayerState.DISCOVERY_S):
		GameState._count_discovery(1.0)
		assert_eq(DayCycle.darkness(), 0.0, "day all through the first minutes")
	assert_false(GameState.is_discovering())
	assert_almost_eq(DayCycle.hour(), DayClock.fast_hour(PlayerState.DISCOVERY_S), 0.01, "then it runs on from there")
	Settings.day_cycle = chosen
	GameState.replace_state(original)
