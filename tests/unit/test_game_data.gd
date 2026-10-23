extends GutTest
## Checks the shipped CSV data and the validation that guards it.

const REGISTRY_SCRIPT := preload("res://src/autoload/data_registry.gd")
const BAD_DIR := "user://test_data"

const HEADER := "id,common_name,scientific_name,rarity,base_value,length_cm,body_aspect,space_l,min_tank_l,bioload,food,env,growth_time_s,placeholder_color,fun_fact"


func _new_registry() -> Node:
	var registry: Node = REGISTRY_SCRIPT.new()
	autofree(registry)
	return registry


func test_shipped_data_is_valid() -> void:
	var registry := _new_registry()
	registry.load_all("res://data")
	assert_eq(registry.errors, PackedStringArray(), "data errors")
	assert_gt(registry.species.size(), 0)


func test_shipped_level_tables_grow() -> void:
	var registry := _new_registry()
	registry.load_all("res://data")
	for levels: Array[LevelDef] in [registry.tank_levels, registry.backpack_levels]:
		assert_gt(levels.size(), 1)
		for i in range(1, levels.size()):
			assert_gt(levels[i].capacity, levels[i - 1].capacity)
			assert_gt(levels[i].cost, levels[i - 1].cost)
	assert_eq(registry.tank_slots[0].cost, 0.0, "the first tank is free")


func test_shipped_species_are_parsed() -> void:
	var registry := _new_registry()
	registry.load_all("res://data")
	var sprat: SpeciesDef = registry.species["european_sprat"]
	assert_eq(sprat.scientific_name, "Sprattus sprattus")
	assert_eq(sprat.rarity, SpeciesDef.Rarity.COMMON)
	assert_eq(sprat.env, SpeciesDef.Env.TEMPERATE)
	assert_eq(sprat.base_value, 5.0)


func test_invalid_rows_are_reported_and_skipped() -> void:
	DirAccess.make_dir_recursive_absolute(BAD_DIR)
	var file := FileAccess.open(BAD_DIR.path_join("species.csv"), FileAccess.WRITE)
	file.store_string("\n".join([
		HEADER,
		"good_fish,Good,Bonus bonus,common,5,10,0.2,2,20,1,flakes,temperate,60,#ffffff,Fine.",
		"good_fish,Dupe,Bonus bonus,common,5,10,0.2,2,20,1,flakes,temperate,60,#ffffff,Duplicate id.",
		"bad_rarity,Bad,Bonus bonus,mythic,5,10,0.2,2,20,1,flakes,temperate,60,#ffffff,Unknown rarity.",
		"bad_number,Bad,Bonus bonus,common,lots,10,0.2,2,20,1,flakes,temperate,60,#ffffff,Not a number.",
		"too_short,Bad,Bonus bonus",
	]))
	file.close()

	var registry := _new_registry()
	registry.load_all(BAD_DIR)

	assert_eq(registry.species.keys(), ["good_fish"])
	# The fixture folder has no level tables; only count the species errors.
	var species_errors := Array(registry.errors).filter(func(e: String) -> bool: return e.contains("species.csv"))
	assert_eq(species_errors.size(), 4, "\n".join(species_errors))
