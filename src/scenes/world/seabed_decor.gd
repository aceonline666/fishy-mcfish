class_name SeabedDecor
extends Node2D
## Painted props on the seabed (assets/sprites/seabed, tools/extract_seabed.py), so the isometric
## ground reads clearly; sits below the fish and the wader. Temperate water has rocks, swaying
## kelp, mussels, starfish, anemones and a little sunken junk; tropical water has corals, sponges,
## seagrass, a giant clam, sea urchins and a treasure chest.

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
		["treasure_chest", 110.0, 1],
	],
}
const SWAY: Array[String] = ["kelp_small", "kelp", "kelp_tall", "sea_lettuce", "seagrass", "reef_anemone", "sea_fan"]
const WRECK_WIDTH := 460.0
## Props keep at least this far apart (ground units).
const PROP_SPACING := 150.0
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


## Places a sunken ship (a prop sprite) on the seabed at a ground position.
func add_wreck(prop_name: String, ground: Vector2) -> void:
	_props.append(_make_prop(prop_name, ground, WRECK_WIDTH, 0.0))
	_sort_props()
	queue_redraw()


func _crowded(ground: Vector2, taken: PackedVector2Array) -> bool:
	for other in taken:
		if ground.distance_to(other) < PROP_SPACING:
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
