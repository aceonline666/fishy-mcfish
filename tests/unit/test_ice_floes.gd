extends GutTest
## Ice floes on the surface: where they lie and what they hide.

const AREA := Rect2(0.0, 1920.0, 2160.0, 960.0)


func test_floes_cover_part_of_their_zone() -> void:
	var floes: IceFloes = autofree(IceFloes.new())
	floes.setup(AREA, 11)
	assert_false(floes.hides(Rect2(Iso.to_screen(Vector2(1080.0, 500.0)), Vector2(100.0, 100.0))), "nothing in the shallows")
	var hidden := 0
	for x in range(0, 2160, 60):
		for y in range(1920, 2880, 60):
			if floes.hides(Rect2(Iso.to_screen(Vector2(x, y)), Vector2(4.0, 4.0))):
				hidden += 1
	assert_gt(hidden, 0, "some of the zone is under ice")
	assert_lt(hidden, 16 * 36 / 2, "most of the zone is open water")


func test_floes_never_touch_while_drifting() -> void:
	for seed_value: int in [5, 6, 7, 8]:
		var floes: IceFloes = autofree(IceFloes.new())
		floes.setup(AREA, 11, seed_value)
		assert_eq(floes._floes.size(), 11, "every floe finds a place (seed %d)" % seed_value)
		var nearest := INF
		for floe: IceFloes.Floe in floes._floes:
			var closest := INF
			for other: IceFloes.Floe in floes._floes:
				if other == floe:
					continue
				closest = minf(closest, floe.center.distance_to(other.center) - floe.radius - other.radius)
				for step in 300:
					var time := step * 3.0
					var gap := IceFloes.drifted(floe, time).distance_to(IceFloes.drifted(other, time)) - floe.radius - other.radius
					assert_true(gap >= IceFloes.GAP - 0.01, "floes keep open water between them (seed %d)" % seed_value)
					if gap < IceFloes.GAP - 0.01:
						return
			nearest = minf(nearest, closest)
		# Floes drifting in step may lie closer than a fixed worst-case drift buffer would allow,
		# so they do not spread out evenly like a grid.
		assert_lt(nearest, IceFloes.GAP + 2.0 * IceFloes.DRIFT.length(), "some floes lie close together (seed %d)" % seed_value)
