class_name Night
extends Node2D
## The time of day over a fishing spot (DayCycle): `shade` is a full-screen rect over the world
## and below the HUD that multiplies everything with the day's tint (night.gdshader), and lights
## pools on the ground around the lamps. This node, in the world, draws the lamps' glow on top,
## so it shines through the night. Both fade in as it gets dark.

const SHADER := preload("res://src/shaders/night.gdshader")
## As many pools as night.gdshader takes.
const MAX_LIGHTS := 16
## Warm lamplight and the tank's water lit from inside.
const LAMP_COLOR := Color(1.0, 0.86, 0.62)
const TANK_COLOR := Color(0.62, 0.95, 1.0)
## The blue-green glow of the sea where it is stirred at night (bioluminescent plankton): the
## wake and the splashes (Juice.glow_ripple), and the breaking waves of GlowingShore.
const SEA_SPARKLE := Color(0.3, 0.85, 1.0)
const SPARKLE_STRENGTH := 0.12
## How strongly a lamp's glow shines through the night (its alpha).
const GLOW_STRENGTH := 0.55


## A pool of light on the ground (none if its radius is 0) and, if `glow_radius` > 0, a glow at
## `glow_at` (in the world's screen units): a painted lamp or window that shines.
class Lamp:
	var ground: Vector2
	var radius: float
	var strength: float
	var color: Color
	var glow_at: Vector2
	var glow_radius: float

	func _init(at: Vector2, pool_radius: float, pool_strength: float, light_color: Color, glow_point: Vector2 = Vector2.ZERO, glow: float = 0.0) -> void:
		ground = at
		radius = pool_radius
		strength = pool_strength
		color = light_color
		glow_at = glow_point
		glow_radius = glow


var shade := ColorRect.new()
var darkness := 0.0
var _lamps: Array[Lamp] = []


func _init() -> void:
	material = Glow.material()
	Layers.put(self, Layers.NIGHT_LIGHTS)
	var shade_material := ShaderMaterial.new()
	shade_material.shader = SHADER
	shade.material = shade_material
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	Layers.put(shade, Layers.NIGHT)


## Shows the time of day: `tint` over a world at `world_origin` (screen) and `zoom` in a rect of
## `rect_size`, lamps lit by `dark` (0 to 1). The spotlight's cone lights the night as it lights
## the deep sea (spotlight.gdshaderinc).
func show_time(tint: Color, dark: float, lamps: Array[Lamp], rect_size: Vector2, world_origin: Vector2, zoom: float) -> void:
	darkness = dark
	_lamps = lamps
	shade.visible = tint != Color.WHITE
	visible = dark > 0.0
	var params := shade.material as ShaderMaterial
	params.set_shader_parameter("tint", tint)
	params.set_shader_parameter("darkness", dark)
	params.set_shader_parameter("rect_size", rect_size)
	params.set_shader_parameter("world_origin", world_origin)
	params.set_shader_parameter("zoom", zoom)
	params.set_shader_parameter("abyss_start", SeaDepth.ABYSS_START)
	params.set_shader_parameter("abyss_end", SeaDepth.ABYSS_END)
	var pools: Array[Vector4] = []
	var colors: Array[Color] = []
	for lamp: Lamp in lamps:
		if lamp.radius <= 0.0 or pools.size() == MAX_LIGHTS:
			continue
		pools.append(Vector4(lamp.ground.x, lamp.ground.y, lamp.radius, lamp.strength))
		colors.append(lamp.color)
	params.set_shader_parameter("light_count", pools.size())
	# The arrays must have their full size.
	while pools.size() < MAX_LIGHTS:
		pools.append(Vector4.ZERO)
		colors.append(Color.BLACK)
	params.set_shader_parameter("lights", pools)
	params.set_shader_parameter("light_colors", colors)
	queue_redraw()


## The spotlight of the submarine or the hard-hat helmet, as passed to the water.
func show_spotlight(origin: Vector2, direction: Vector2, on: float) -> void:
	var params := shade.material as ShaderMaterial
	params.set_shader_parameter("light_origin", origin)
	params.set_shader_parameter("light_dir", direction)
	params.set_shader_parameter("light_on", on)


func _draw() -> void:
	for lamp in _lamps:
		if lamp.glow_radius > 0.0:
			var color := lamp.color
			color.a = GLOW_STRENGTH * darkness
			Glow.draw(self, lamp.glow_at, lamp.glow_radius, color)
