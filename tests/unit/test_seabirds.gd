extends GutTest
## Seabirds: now and then a flight crosses the view, from beyond one side to beyond the other.

var _birds: Seabirds


func before_each() -> void:
	_birds = Seabirds.new()
	_birds.location_id = "north_sea"
	_birds.view = Rect2(0.0, 0.0, 720.0, 1280.0)
	add_child_autofree(_birds)


func test_every_location_has_painted_birds() -> void:
	for location in DataRegistry.locations:
		var kinds: Array = Seabirds.KINDS.get(location.id, [])
		assert_false(kinds.is_empty(), "%s has birds" % location.id)
		for kind: Array in kinds:
			assert_true(Seabirds.has_sprites(kind[0]), "%s is painted" % kind[0])


func test_a_flight_comes_when_due() -> void:
	_birds._wait = 0.01
	_birds.update(0.1)
	assert_gt(_birds.flying(), 0)
	assert_between(_birds._wait, Seabirds.INTERVAL.x, Seabirds.INTERVAL.y)


func test_a_flight_crosses_the_view_and_is_gone() -> void:
	_birds._wait = 1000.0
	_birds.send_flock()
	var bird: Seabirds.Bird = _birds._birds[0]
	assert_true(bird.position.x < 0.0 or bird.position.x > 720.0, "starts beyond a side")
	assert_between(bird.position.y, 1280.0 * Seabirds.LANE.x - Seabirds.FLOCK_SPREAD.y, 1280.0 * Seabirds.LANE.y + Seabirds.FLOCK_SPREAD.y)
	var seen := false
	for i in 200:
		_birds.update(0.1)
		if _birds.flying() > 0 and Rect2(0.0, 0.0, 720.0, 1280.0).has_point(_birds._birds[0].position):
			seen = true
	assert_true(seen, "flies through the view")
	assert_eq(_birds.flying(), 0, "gone beyond the other side")


func test_nothing_flies_where_there_are_no_birds() -> void:
	_birds.location_id = "nowhere"
	_birds.send_flock()
	assert_eq(_birds.flying(), 0)


func test_every_call_is_a_known_sound_of_a_flying_kind() -> void:
	var kinds: Array[String] = []
	for location_kinds: Array in Seabirds.KINDS.values():
		for kind: Array in location_kinds:
			kinds.append(kind[0])
	for id: String in Seabirds.CALLS:
		assert_has(kinds, id, "%s flies somewhere" % id)
		for sound: StringName in Seabirds.CALLS[id][0]:
			assert_true(Sfx.has(sound), "%s is a sound" % sound)


func test_a_calling_flight_calls_once_or_twice_while_it_flies_over() -> void:
	_birds._wait = 1000.0
	_birds.send_flock()
	var calls := _birds.calls_left()
	assert_between(calls, 1, mini(Seabirds.CALLS_PER_FLIGHT, _birds.flying()))
	for i in 200:
		_birds.update(0.1)
	assert_eq(_birds.calls_left(), 0, "all calls made")


func test_silent_kinds_do_not_call() -> void:
	_birds.location_id = "antarctica"
	_birds._wait = 1000.0
	_birds.send_flock()
	assert_gt(_birds.flying(), 0)
	assert_eq(_birds.calls_left(), 0)
