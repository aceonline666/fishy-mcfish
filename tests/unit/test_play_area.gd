extends GutTest

var _area := PlayArea.new(Rect2(0.0, 40.0, 1100.0, 760.0))


func test_contains_respects_the_margin() -> void:
	assert_true(_area.contains(Vector2(500.0, 400.0)))
	assert_true(_area.contains(Vector2(5.0, 400.0)))
	assert_false(_area.contains(Vector2(5.0, 400.0), 20.0))
	assert_false(_area.contains(Vector2(500.0, 0.0)))


func test_clamp_moves_points_inside() -> void:
	for point: Vector2 in [Vector2(-300.0, 900.0), Vector2(5000.0, -100.0), Vector2(500.0, 400.0)]:
		assert_true(_area.contains(_area.clamp_point(point, 20.0), 19.9), "clamped %s" % point)


func test_center_and_random_points_are_inside() -> void:
	assert_true(_area.contains(_area.center(), 100.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 30:
		assert_true(_area.contains(_area.random_point(rng, 60.0), 59.9))
