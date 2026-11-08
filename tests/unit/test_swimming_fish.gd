extends GutTest
## Swimming fish in a current.

const AREA := Rect2(-5000.0, 0.0, 10000.0, 2000.0)


func _fish(heading: float, current: Vector2) -> SwimmingFish:
	var fish: SwimmingFish = autofree(SwimmingFish.new())
	var zone := DataRegistry.zones[0]
	fish.setup(FishArt.for_species(DataRegistry.species["atlantic_mackerel"]), zone, PlayArea.new(AREA), Vector2(0.0, 1000.0), heading)
	fish.current = current
	return fish


## Ground distance covered along x in `seconds`, the wader far away.
func _travel(fish: SwimmingFish, seconds: float) -> float:
	var start := fish.ground_position.x
	var school: Array[SwimmingFish] = []
	for i in int(seconds * 30.0):
		fish.simulate(1.0 / 30.0, Vector2(0.0, -9000.0), 1.0, school)
	return fish.ground_position.x - start


func test_current_carries_fish_with_it_faster_than_against_it() -> void:
	seed(1)
	var with_current := _travel(_fish(0.0, Vector2(108.0, 0.0)), 1.0)
	seed(1)
	var still := _travel(_fish(0.0, Vector2.ZERO), 1.0)
	seed(1)
	var against := -_travel(_fish(PI, Vector2(108.0, 0.0)), 1.0)
	assert_gt(with_current, still)
	assert_gt(still, against)
	assert_gt(against, 0.0, "it still makes headway against the current")
