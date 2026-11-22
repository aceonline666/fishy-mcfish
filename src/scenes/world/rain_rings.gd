class_name RainRings
extends MultiMeshInstance2D
## Raindrops hitting the water: small rings spreading on the surface (rain_rings.gdshader), a
## MultiMesh of quads the shader moves, so they cost the CPU nothing. In the world, on the water's
## surface; none in snow.

const SHADER := preload("res://src/shaders/rain_rings.gdshader")
## Rings at once in a storm (each lives rain_rings.gdshader's LIFE).
const MAX_RINGS := 110


func _init() -> void:
	multimesh = Rain.quads(MAX_RINGS)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	material = shader_material
	visible = false
	Layers.put(self, Layers.SURFACE)


## Shows the rings of `weather` in `view` (world coordinates) on water whose waterline is at
## ground y `shore_y`.
func show_weather(weather: Weather.State, view: Rect2, shore_y: float) -> void:
	var count := 0 if weather.snow > 0.5 else roundi(MAX_RINGS * weather.rain)
	visible = count > 0
	if not visible:
		return
	multimesh.visible_instance_count = count
	var params := material as ShaderMaterial
	params.set_shader_parameter("view_pos", view.position)
	params.set_shader_parameter("view_size", view.size)
	params.set_shader_parameter("shore_y", shore_y)
	params.set_shader_parameter("strength", clampf(weather.rain * 3.0, 0.0, 1.0))
