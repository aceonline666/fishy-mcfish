extends GutTest
## The deep sea horror (DarkThings): on its own timer, along the far edge only.

var _dark: DarkThings


func before_each() -> void:
	_dark = DarkThings.new()
	_dark.spot_width = 2160.0
	_dark.horror_edge = 7680.0
	add_child_autofree(_dark)


func test_the_horror_comes_when_due_wherever_the_wader_is() -> void:
	_dark.wader_ground = Vector2(1080.0, 300.0)
	_dark._horror_wait = 0.01
	_dark._update_horror(0.1)
	assert_true(_dark.horror_passing(), "it does not wait for the wader")
	assert_between(_dark._horror_wait, DarkThings.HORROR_INTERVAL.x, DarkThings.HORROR_INTERVAL.y)


func test_the_horror_swims_along_the_far_edge_beyond_the_water() -> void:
	_dark.send_horror()
	var start := _dark._horror_at
	assert_true(start.y >= 7680.0 + DarkThings.HORROR_BEYOND.x, "beyond the far edge")
	assert_true(start.x < 0.0 or start.x > 2160.0, "starts beyond a side of the spot")
	_dark._update_horror(1.0)
	assert_eq(_dark._horror_at.y, start.y, "keeps to the edge")
	assert_almost_eq(absf(_dark._horror_at.x - start.x), DarkThings.HORROR_SPEED, 0.01)


func test_the_horror_is_gone_once_past_the_other_side() -> void:
	_dark.send_horror()
	for i in 80:
		_dark._update_horror(1.0)
	assert_false(_dark.horror_passing())


func test_no_horror_without_a_far_edge() -> void:
	_dark.horror_edge = INF
	_dark.send_horror()
	assert_false(_dark.horror_passing())
