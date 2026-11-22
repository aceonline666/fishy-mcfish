class_name GlowingShore
extends Node2D
## A glowing beach at night: where the sea is full of bioluminescent plankton, every wave that
## breaks on the sand lights up blue, and sparks are left on the wet sand as it runs back (like
## the "Sea of Stars" on Vaadhoo in the Maldives). A strip along the waterline in the world,
## drawn additively over the time of day's tint (glowing_shore.gdshader); only the strip's pixels
## cost anything, and nothing by day.

const SHADER := preload("res://src/shaders/glowing_shore.gdshader")
## The locations whose beach glows at night.
const LOCATIONS: Array[String] = ["coral_reef"]
## How far the strip reaches up the beach and out into the water from the waterline (ground units).
const BEACH_SIDE := 110.0
const WATER_SIDE := 150.0

var _strip := PackedVector2Array()


func _init() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	material = shader_material
	visible = false
	Layers.put(self, Layers.NIGHT_LIGHTS)


## Shows the glow at `dark` (0 by day to 1 at night) along the waterline at ground y `shore_y`,
## over the part of the world in `view` (world coordinates), but not under the pier (`pier`, its
## ground rect) nor over the wader's figure (`figure`, world rect).
func show_night(dark: float, view: Rect2, shore_y: float, pier: Rect2, figure: Rect2) -> void:
	visible = dark > 0.0
	if not visible:
		return
	var params := material as ShaderMaterial
	params.set_shader_parameter("shore_y", shore_y)
	params.set_shader_parameter("strength", dark)
	params.set_shader_parameter("pier", Vector2(pier.position.x, pier.end.x))
	params.set_shader_parameter("hole", Vector4(figure.position.x, figure.position.y, figure.size.x, figure.size.y))
	# The waterline's ground x across the view: from its corners.
	var low := INF
	var high := -INF
	for corner: Vector2 in [view.position, view.position + Vector2(view.size.x, 0.0), view.end, view.position + Vector2(0.0, view.size.y)]:
		var x := Iso.to_ground(corner).x
		low = minf(low, x)
		high = maxf(high, x)
	var top := shore_y - BEACH_SIDE
	var bottom := shore_y + WATER_SIDE
	_strip = PackedVector2Array([
		Iso.to_screen(Vector2(low, top)), Iso.to_screen(Vector2(high, top)),
		Iso.to_screen(Vector2(high, bottom)), Iso.to_screen(Vector2(low, bottom)),
	])
	queue_redraw()


func _draw() -> void:
	if _strip.size() == 4:
		draw_colored_polygon(_strip, Color.WHITE)
