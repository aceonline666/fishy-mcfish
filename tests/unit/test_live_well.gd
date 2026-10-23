extends GutTest


func test_accepts_fish_until_full() -> void:
	var well := LiveWell.new(2)
	assert_true(well.add("a"))
	assert_true(well.add("b"))
	assert_true(well.is_full())
	assert_false(well.add("c"))
	assert_eq(well.count(), 2)
	assert_eq(well.free_space(), 0)


func test_take_last_returns_the_newest_fish() -> void:
	var well := LiveWell.new(5)
	well.add("a")
	well.add("b")
	assert_eq(well.take_last(), "b")
	assert_eq(well.count(), 1)


func test_take_all_empties_the_well() -> void:
	var well := LiveWell.new(5)
	well.add("a")
	well.add("b")
	var taken := well.take_all()
	assert_eq(taken, ["a", "b"] as Array[String])
	assert_eq(well.count(), 0)
	assert_eq(well.free_space(), 5)
