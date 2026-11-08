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
