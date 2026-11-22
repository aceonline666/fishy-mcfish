class_name Rain
extends MultiMeshInstance2D
## Rain or snow falling over the screen (rain.gdshader, Weather): a MultiMesh of MAX_DROPS quads
## whose shader moves them, so a drop costs the CPU nothing. The weather sets how many show. In
## screen coordinates, under the time of day's tint.

const SHADER := preload("res://src/shaders/rain.gdshader")
## Drops in a storm (all of them) and flakes in a blizzard.
const MAX_DROPS := 320
const MAX_FLAKES := 240


func _init() -> void:
	multimesh = quads(MAX_DROPS)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	material = shader_material
	visible = false


## A MultiMesh of `count` unit quads (UV 0 to 1), none shown yet. The shader places them; the
## instances all stand at the origin, so the bounds cover all of the screen (custom_aabb) to keep
## them from being culled.
static func quads(count: int) -> MultiMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	var quads_mesh := MultiMesh.new()
	quads_mesh.transform_format = MultiMesh.TRANSFORM_2D
	quads_mesh.mesh = mesh
	quads_mesh.instance_count = count
	for i in count:
		quads_mesh.set_instance_transform_2d(i, Transform2D.IDENTITY)
	quads_mesh.visible_instance_count = 0
	quads_mesh.custom_aabb = AABB(Vector3(-1.0e6, -1.0e6, -1.0), Vector3(2.0e6, 2.0e6, 2.0))
	return quads_mesh


## Shows the rain of `weather` over a view of `view_size` with the world at `world_origin`.
func show_weather(weather: Weather.State, view_size: Vector2, world_origin: Vector2) -> void:
	var count := roundi((MAX_FLAKES if weather.snow > 0.5 else MAX_DROPS) * weather.rain)
	visible = count > 0
	if not visible:
		return
	multimesh.visible_instance_count = count
	var params := material as ShaderMaterial
	params.set_shader_parameter("view_size", view_size)
	params.set_shader_parameter("scroll", world_origin)
	params.set_shader_parameter("wind", weather.wind)
	params.set_shader_parameter("snow", weather.snow)
	# Fades in with the first drops.
	params.set_shader_parameter("strength", clampf(weather.rain * 3.0, 0.0, 1.0))
