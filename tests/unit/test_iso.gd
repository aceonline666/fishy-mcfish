extends GutTest


func test_ground_axes_point_diagonally_on_screen() -> void:
	var x_axis := Iso.to_screen(Vector2(100.0, 0.0))
	var y_axis := Iso.to_screen(Vector2(0.0, 100.0))
	assert_gt(x_axis.x, 0.0)
	assert_gt(x_axis.y, 0.0)
	assert_lt(y_axis.x, 0.0)
	assert_gt(y_axis.y, 0.0)
	# 2:1 isometric: twice as wide as tall.
	assert_almost_eq(x_axis.x / x_axis.y, 2.0, 0.001)


func test_round_trip() -> void:
	for ground: Vector2 in [Vector2(0.0, 0.0), Vector2(123.0, -45.0), Vector2(-800.0, 300.0)]:
		var back := Iso.to_ground(Iso.to_screen(ground))
		assert_almost_eq(back.x, ground.x, 0.01)
		assert_almost_eq(back.y, ground.y, 0.01)


func test_ground_circle_is_a_flat_ellipse() -> void:
	var points := Iso.ellipse(Vector2.ZERO, 50.0, 4)
	assert_almost_eq(points[0].x, 50.0, 0.01)
	assert_almost_eq(points[1].y, 25.0, 0.01)
	# Matches the projection of an actual ground circle.
	assert_almost_eq(Iso.to_screen(Vector2(50.0, 0.0).rotated(-PI / 4.0)).length(), 50.0, 0.01)
