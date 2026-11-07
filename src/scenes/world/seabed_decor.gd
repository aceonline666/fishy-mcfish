class_name SeabedDecor
extends Node2D
## Painted props on the seabed (assets/sprites/seabed, tools/extract_seabed.py), so the isometric
## ground reads clearly; sits below the fish and the wader. Temperate water has rocks, swaying
## kelp, mussels, starfish, anemones and a little sunken junk; tropical water has corals, sponges,
## seagrass, a giant clam and sea urchins. The treasure chest is a TreasureChest of its own.

const PROPS_DIR := "res://assets/sprites/seabed/"
## Props per water: sprite, screen width and how many are scattered. Swaying ones are in SWAY.
const PROPS: Dictionary[String, Array] = {
	"temperate": [
		["stones", 70.0, 4], ["rock", 90.0, 3], ["boulder", 120.0, 2],
		["kelp_small", 60.0, 4], ["kelp", 75.0, 4], ["kelp_tall", 90.0, 3], ["sea_lettuce", 90.0, 3],
		["mussels", 90.0, 2], ["starfish", 70.0, 2], ["anemones", 100.0, 2],
		["anchor", 110.0, 1], ["barrels", 110.0, 1], ["crate", 100.0, 1], ["lobster_pot", 110.0, 1], ["rowboat", 200.0, 1],
	],
	"tropical": [
		["coral_stones", 90.0, 4], ["coral_rock", 120.0, 2], ["brain_coral", 100.0, 3], ["branch_coral", 95.0, 3],
		["table_coral", 105.0, 2], ["sea_fan", 95.0, 3], ["tube_sponge", 80.0, 3], ["reef_anemone", 85.0, 3],
		["seagrass", 75.0, 4], ["giant_clam", 95.0, 1], ["blue_starfish", 70.0, 2], ["sea_urchin", 55.0, 2],
	],
}
## Zones named after what grows or lies there show it: extra props scattered in their depth band,
## per zone id, as in PROPS (sprite, screen width, how many).
const ZONE_PROPS: Dictionary[String, Array] = {
	"pier_shallows": [["lost_lure", 110.0, 2], ["hermit_crab", 90.0, 3], ["razor_clams", 100.0, 3]],
	"sandbanks": [["sand_dollars", 110.0, 6], ["razor_clams", 100.0, 5]],
	"open_sea": [["sea_cucumbers", 100.0, 4]],
	"drop_off": [["wall_sponges", 110.0, 5], ["sea_fan", 95.0, 3]],
	"open_ocean": [["sea_cucumbers", 100.0, 4]],
	"southern_ocean": [["sea_cucumbers", 100.0, 4], ["brittle_stars", 120.0, 4]],
	"sagami_bay": [["sea_cucumbers", 100.0, 4], ["glass_sponge", 110.0, 3]],
	"seagrass_bay": [["seagrass", 80.0, 26], ["blue_starfish", 60.0, 2]],
	"lagoon": [["seagrass", 75.0, 12], ["giant_clam", 90.0, 1]],
	"reef_crest": [["branch_coral", 95.0, 4], ["brain_coral", 100.0, 3], ["table_coral", 105.0, 3]],
	"kelp_forest_au": [["kelp_tall", 95.0, 13], ["kelp", 80.0, 8]],
	"cape_kelp": [["kelp_tall", 95.0, 13], ["kelp", 80.0, 8]],
	"seaweed_bed": [["sea_lettuce", 90.0, 11], ["kelp_small", 65.0, 11]],
	"rocky_reef": [["boulder", 130.0, 5], ["rock", 100.0, 5], ["stones", 80.0, 4]],
	"rocky_shore": [["boulder", 125.0, 4], ["rock", 95.0, 5], ["stones", 75.0, 5], ["mussels", 85.0, 3]],
	"kuroshio": [["sea_whips", 95.0, 7]],
	"shark_alley": [["whale_bones", 220.0, 1], ["shark_cage", 160.0, 1], ["red_bait", 100.0, 5], ["boulder", 125.0, 3]],
	"agulhas_current": [["sea_whips", 95.0, 7]],
	"norwegian_trench": [["brittle_stars", 120.0, 6], ["sea_pens", 90.0, 5]],
	"deep_sea": [["whale_fall", 260.0, 1], ["glass_sponge", 110.0, 4], ["brittle_stars", 120.0, 5]],
	"twilight_zone": [["sea_pens", 90.0, 6], ["glass_sponge", 110.0, 3]],
	"trench": [["black_smoker", 150.0, 2], ["tube_worms", 110.0, 4], ["brittle_stars", 120.0, 4]],
	"continental_slope": [["glass_sponge", 110.0, 4], ["sea_pens", 90.0, 5]],
	"abyss_au": [["whale_fall", 260.0, 1], ["brittle_stars", 120.0, 6]],
	"deep_slope_jp": [["glass_sponge", 110.0, 4], ["brittle_stars", 120.0, 4]],
	"japan_trench": [["black_smoker", 150.0, 2], ["tube_worms", 110.0, 5]],
	"cape_canyon": [["sea_pens", 90.0, 6], ["brittle_stars", 120.0, 4]],
	"abyssal_plain": [["whale_fall", 260.0, 1], ["brittle_stars", 120.0, 6], ["glass_sponge", 110.0, 2]],
}
## Rocks lined up along the spot's west and east edges, so the water ends at a reef wall rather
## than an invisible one: per water, the sprites taken in turn and their screen widths.
const EDGE_PROPS: Dictionary[String, Array] = {
	"temperate": [["boulder", 150.0], ["rock", 115.0], ["stones", 95.0], ["boulder", 135.0], ["rock", 125.0]],
	"tropical": [["coral_rock", 150.0], ["brain_coral", 115.0], ["coral_stones", 105.0], ["coral_rock", 135.0], ["table_coral", 120.0]],
}
## Ground distance between edge rocks along the edge, and how far outside the edge they lie
## (between the two values).
const EDGE_SPACING := 95.0
const EDGE_OFFSET := Vector2(15.0, 70.0)
const SWAY: Array[String] = ["kelp_small", "kelp", "kelp_tall", "sea_lettuce", "seagrass", "reef_anemone", "sea_fan", "sea_whips", "sea_pens"]
const WRECK_WIDTH := 460.0
## Props keep at least this far apart (ground units); a zone's own props, which grow in beds,
## closer.
const PROP_SPACING := 150.0
const ZONE_PROP_SPACING := 90.0
## Share of the sprite height below the prop's ground point (the sand patch it stands on).
const PROP_BASE := 0.12
## Props fade into the water colour with depth like the seabed (SeaDepth,
## src/shaders/seabed_props.gdshader).
const PROPS_SHADER := preload("res://src/shaders/seabed_props.gdshader")

## Set before generate(): "tropical" for corals, anything else for temperate props.
var water := "temperate"

## Painted props, nearest last.
var _props: Array[Prop] = []
var _time := 0.0


func _ready() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = PROPS_SHADER
	material = shader_material


## The water colours of the location, which the props fade into with depth.
func set_water_colors(shallow: Color, deep: Color, clarity: float) -> void:
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("shallow_color", shallow)
	shader_material.set_shader_parameter("deep_color", deep)
	shader_material.set_shader_parameter("clarity", clarity)


func generate(area: PlayArea, seed_value: int = 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_props.clear()
	var taken := PackedVector2Array()
	for entry: Array in PROPS.get(water, PROPS["temperate"]):
		for i in int(entry[2]):
			var ground := area.random_point(rng, 80.0)
			for attempt in 20:
				if not _crowded(ground, taken):
					break
				ground = area.random_point(rng, 80.0)
			taken.append(ground)
			_props.append(_make_prop(entry[0], ground, float(entry[1]) * rng.randf_range(0.85, 1.15), rng.randf() * TAU))
	_sort_props()
	queue_redraw()


## Scatters the zone's own props (ZONE_PROPS) in its area, if it has any.
func add_zone(zone_id: String, area: PlayArea, seed_value: int = 3) -> void:
	if not ZONE_PROPS.has(zone_id):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + zone_id.hash()
	var taken := PackedVector2Array()
	for entry: Array in ZONE_PROPS[zone_id]:
		for i in int(entry[2]):
			var ground := area.random_point(rng, 80.0)
			for attempt in 20:
				if not _crowded(ground, taken, ZONE_PROP_SPACING):
					break
				ground = area.random_point(rng, 80.0)
			taken.append(ground)
			_props.append(_make_prop(entry[0], ground, float(entry[1]) * rng.randf_range(0.85, 1.15), rng.randf() * TAU))
	_sort_props()
	queue_redraw()


## Lines the area's west and east edges with rocks, from its top down to its bottom.
func add_edges(area: PlayArea, seed_value: int = 2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var props: Array = EDGE_PROPS.get(water, EDGE_PROPS["temperate"])
	var index := 0
	for side: float in [-1.0, 1.0]:
		var edge_x := area.rect.position.x if side < 0.0 else area.rect.end.x
		var y := area.rect.position.y + rng.randf_range(0.0, EDGE_SPACING)
		while y < area.rect.end.y:
			var entry: Array = props[index % props.size()]
			index += 1
			var ground := Vector2(edge_x + side * rng.randf_range(EDGE_OFFSET.x, EDGE_OFFSET.y), y)
			_props.append(_make_prop(entry[0], ground, float(entry[1]) * rng.randf_range(0.85, 1.15), 0.0))
			y += EDGE_SPACING * rng.randf_range(0.8, 1.2)
	_sort_props()
	queue_redraw()


## Places a sunken ship (a prop sprite) on the seabed at a ground position.
func add_wreck(prop_name: String, ground: Vector2) -> void:
	_props.append(_make_prop(prop_name, ground, WRECK_WIDTH, 0.0))
	_sort_props()
	queue_redraw()


func _crowded(ground: Vector2, taken: PackedVector2Array, spacing: float = PROP_SPACING) -> bool:
	for other in taken:
		if ground.distance_to(other) < spacing:
			return true
	return false


func _make_prop(prop_name: String, ground: Vector2, width: float, phase: float) -> Prop:
	var prop := Prop.new()
	prop.texture = load(PROPS_DIR + prop_name + ".png")
	prop.at = Iso.to_screen(ground)
	prop.size = prop.texture.get_size() * (width / prop.texture.get_width())
	prop.sways = SWAY.has(prop_name)
	prop.phase = phase
	# The shader reads the depth from the colour (the waterline is at ground y 0).
	prop.tint = Color(SeaDepth.depth(ground.y), SeaDepth.abyss(ground.y), 0.0)
	return prop


func _sort_props() -> void:
	_props.sort_custom(func(a: Prop, b: Prop) -> bool: return a.at.y < b.at.y)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for prop in _props:
		# Swaying props lean from their base.
		var lean := sin(_time * 1.3 + prop.phase) * 0.12 if prop.sways else 0.0
		draw_set_transform_matrix(Transform2D(Vector2(1.0, 0.0), Vector2(lean, 1.0), prop.at))
		draw_texture_rect(prop.texture, Rect2(Vector2(-prop.size.x * 0.5, -prop.size.y * (1.0 - PROP_BASE)), prop.size), false, prop.tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)


class Prop extends RefCounted:
	var texture: Texture2D
	var at := Vector2.ZERO
	var size := Vector2.ZERO
	var sways := false
	var phase := 0.0
	var tint := Color.WHITE

