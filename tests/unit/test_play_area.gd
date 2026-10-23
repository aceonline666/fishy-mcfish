extends GutTest

const SHORE_Y := -150.0

var _area := PlayArea.new(Rect2(0.0, 170.0, 1080.0, 1350.0), SHORE_Y)


func test_beach_is_not_water() -> void:
	# Top-right corner of the screen is beyond the shoreline.
	assert_false(_area.contains(Iso.to_ground(Vector2(1050.0, 200.0))))
	assert_true(_area.contains(Iso.to_ground(Vector2(300.0, 1000.0))))


func test_points_off_screen_are_not_water() -> void:
	assert_false(_area.contains(Iso.to_ground(Vector2(-50.0, 900.0))))
	assert_false(_area.contains(Iso.to_ground(Vector2(500.0, 1600.0))))


func test_clamp_moves_points_into_the_water() -> void:
	for screen: Vector2 in [Vector2(1200.0, 100.0), Vector2(-300.0, 900.0), Vector2(500.0, 3000.0)]:
		var clamped := _area.clamp_point(Iso.to_ground(screen), 20.0)
		assert_true(_area.contains(clamped, 19.0), "clamped %s" % screen)


func test_center_and_random_points_are_in_open_water() -> void:
	assert_true(_area.contains(_area.center(), 100.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 30:
		assert_true(_area.contains(_area.random_point(rng, 60.0), 60.0))
