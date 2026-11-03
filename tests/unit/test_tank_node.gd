extends GutTest
## The tank on the beach has room for the fish it holds, drawn at their size.


func _tank_node(level: int) -> TankNode:
	var node: TankNode = autofree(TankNode.new())
	var footprint := DataRegistry.tank_levels[level - 1].footprint
	node.setup(TankState.new(level), Rect2(Vector2.ZERO, Vector2(footprint) * Grid.UNIT), Callable())
	return node


func test_every_species_fits_in_the_smallest_tank_that_can_hold_it() -> void:
	for id in DataRegistry.species:
		var def: SpeciesDef = DataRegistry.species[id]
		var needed := Aquarium.tank_needed(def)
		for level in DataRegistry.tank_levels.size():
			if DataRegistry.tank_levels[level].capacity != needed:
				continue
			var room := _tank_node(level + 1).swim_room()
			var length := TankNode.fish_length(def, 1.0)
			assert_lte(length, room.x, "%s: %d px long, tank %d has %d px" % [id, length, level + 1, room.x])
			assert_lte(length * def.body_aspect, room.y,
					"%s: %d px tall, tank %d has %d px" % [id, length * def.body_aspect, level + 1, room.y])


func test_fish_are_as_big_in_every_tank() -> void:
	var def: SpeciesDef = DataRegistry.species["atlantic_mackerel"]
	assert_eq(TankNode.fish_length(def, 1.0), CatchRules.body_length(def) * TankNode.TANK_FISH_SCALE)
