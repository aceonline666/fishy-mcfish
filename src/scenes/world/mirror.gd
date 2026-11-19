class_name Mirror
extends ColorRect
## The sun or the moon mirrored on the water (mirror.gdshader, DayClock.glint): it lies out on the
## sea in front of the beach, where the light stands, and drifts only a little with the view. On
## the water's surface: over the fish, and over the wader while it swims; below it while it wades.
## The rect covers just the mirrored light and its glints. Night lets it shine through its tint.

const SHADER := preload("res://src/shaders/mirror.gdshader")
## Where the light is mirrored before it moves with the time of day (ground, from the middle of
## the spot's waterline), how far out towards the light it lies with the light low and high
## (ground units), and how much it drifts with the middle of the view (0: fixed, 1: with it).
const ANCHOR_OUT := 700.0
const REACH_LOW := 1300.0
const REACH_HIGH := 350.0
const FOLLOW := 0.3
## The light's radius (ground units), low and high, and how far its glints reach (in radii).
const RADIUS_LOW := 150.0
const RADIUS_HIGH := 110.0
const GLINT_REACH := 5.0


func _init() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	material = shader_material
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Layers.put(self, Layers.SURFACE)


## Where `glint` is mirrored (ground) on a spot `spot_width` wide with its waterline at `shore_y`,
## seen with the middle of the view at `view` (ground).
static func place(glint: DayClock.Glint, spot_width: float, shore_y: float, view: Vector2) -> Vector2:
	var anchor := Vector2(spot_width * 0.5, shore_y + ANCHOR_OUT)
	return anchor.lerp(view, FOLLOW) + glint.direction * lerpf(REACH_LOW, REACH_HIGH, glint.height)


static func radius(glint: DayClock.Glint) -> float:
	return lerpf(RADIUS_LOW, RADIUS_HIGH, glint.height)


## Shows `glint` mirrored at `at` (ground) over a world at `world_origin` (screen) and `zoom` in
## a view of `view_size`, above the wader if it `over_wader`. Passes the same to `night`'s shade.
func show_light(glint: DayClock.Glint, at: Vector2, shore_y: float, view_size: Vector2, world_origin: Vector2, zoom: float, over_wader: bool, night: ShaderMaterial) -> void:
	var r := radius(glint)
	for target: ShaderMaterial in [material, night]:
		target.set_shader_parameter("glint_color", glint.color)
		target.set_shader_parameter("glint_height", glint.height)
		target.set_shader_parameter("mirror_at", at)
		target.set_shader_parameter("mirror_radius", r)
	# The light and its glints, drawn out long with the light low (reflection_point).
	var half := Vector2(1.0, lerpf(1.8, 1.0, glint.height) * 0.5) * r * 0.70710678 * GLINT_REACH * zoom
	var centre := world_origin + Iso.to_screen(at) * zoom
	var bounds := Rect2(centre - half, half * 2.0).intersection(Rect2(Vector2.ZERO, view_size))
	visible = glint.color.a > 0.0 and bounds.has_area()
	if not visible:
		return
	z_index = Layers.SURFACE if over_wader else Layers.PADS
	position = bounds.position
	size = bounds.size
	var params := material as ShaderMaterial
	params.set_shader_parameter("rect_pos", bounds.position)
	params.set_shader_parameter("rect_size", bounds.size)
	params.set_shader_parameter("world_origin", world_origin)
	params.set_shader_parameter("zoom", zoom)
	params.set_shader_parameter("shore_y", shore_y)
	params.set_shader_parameter("abyss_start", SeaDepth.ABYSS_START)
	params.set_shader_parameter("abyss_end", SeaDepth.ABYSS_END)
