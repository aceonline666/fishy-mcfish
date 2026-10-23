extends GutTest


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_same_seed_gives_same_sequence() -> void:
	var table := SpawnTable.new({"a": 1.0, "b": 1.0, "c": 1.0})
	var first := _rng(42)
	var second := _rng(42)
	for i in 50:
		assert_eq(table.pick(first), table.pick(second))


func test_picks_follow_weights() -> void:
	var table := SpawnTable.new({"common": 90.0, "rare": 10.0})
	var rng := _rng(1)
	var rare_count := 0
	for i in 10000:
		if table.pick(rng) == "rare":
			rare_count += 1
	assert_between(rare_count, 850, 1150)


func test_single_entry_is_always_picked() -> void:
	var table := SpawnTable.new({"only": 3.0})
	assert_eq(table.pick(_rng(5)), "only")
	assert_eq(table.total_weight, 3.0)
