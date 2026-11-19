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


## Simulates `seconds` with the wader far away; returns the highest leap seen and the splashes.
func _leaps(fish: SwimmingFish, seconds: float) -> Dictionary:
	var result := {"peak": 0.0, "splashes": 0, "air_layer": false}
	fish.splashed.connect(func(_f: SwimmingFish) -> void: result.splashes += 1)
	var school: Array[SwimmingFish] = []
	for i in int(seconds * 30.0):
		fish.simulate(1.0 / 30.0, Vector2(0.0, -9000.0), 1.0, school)
		result.peak = maxf(result.peak, fish.leap_lift())
		if fish.is_leaping() and fish.z_index == Layers.SURFACE:
			result.air_layer = true
	return result


func test_dolphins_leap_out_of_the_water_and_dive_back_in() -> void:
	var fish: SwimmingFish = autofree(SwimmingFish.new())
	fish.setup(FishArt.for_species(DataRegistry.species["common_bottlenose_dolphin"]), DataRegistry.zones[0], PlayArea.new(AREA), Vector2(0.0, 1000.0), 0.0)
	var seen := _leaps(fish, SwimmingFish.LEAP_PAUSE_MAX + SwimmingFish.LEAP_SECONDS + 0.5)
	assert_gt(seen.peak, fish.body_length * 0.5, "it rises well over the water")
	assert_gte(seen.splashes, 2, "a splash going out and one coming back in")
	assert_true(seen.air_layer, "drawn over the surface while in the air")


func test_fish_stay_in_the_water() -> void:
	var seen := _leaps(_fish(0.0, Vector2.ZERO), SwimmingFish.LEAP_PAUSE_MAX * 2.0)
	assert_eq(seen.peak, 0.0)
	assert_eq(seen.splashes, 0)
