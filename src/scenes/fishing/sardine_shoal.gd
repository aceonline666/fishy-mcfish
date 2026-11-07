class_name SardineShoal
extends Node2D
## A shoal of sardines circling in the water at the height the fish swim at, with its shadow on
## the seabed (art_source/ground/seabed_props_currents_prompt.md, cut by tools/cut_sardine_shoal.py).
## SeabedDecor picks where they swim; the scene puts them among the fish and objects. The node sits
## at the shoal's front edge on the ground, so it is sorted in front of everything inside it: the
## wader swimming into it is behind it (`cover()`) and shows see-through, as behind the gear shop.

const TEXTURE := preload("res://assets/sprites/seabed/sardine_shoal.png")
const WATER_SHADER := preload("res://src/shaders/fish_water.gdshader")
## Radians per second, clockwise on screen: the way its fish swim.
const SPIN := 0.25
## How far above the seabed the shoal's middle swims, in screen pixels: as high as the fish.
const LIFT := SwimmingFish.SHADOW_DROP
const SHADOW_COLOR := Color(0.0, 0.06, 0.14, 0.22)

var ground_position := Vector2.ZERO
## Screen size of the sprite.
var _size := Vector2.ZERO
## Screen half width of what the turning sprite can cover (its half height is half of it).
var _reach := 0.0
var _angle := 0.0


## `width` is the shoal's screen width, `angle` where it starts its turn.
func setup(ground: Vector2, width: float, angle: float) -> void:
	ground_position = ground
	_size = TEXTURE.get_size() * (width / TEXTURE.get_width())
	# The sprite is an ellipse in the 2:1 view; turned on the ground it reaches out as far as its
	# longer ground axis (the half width, or twice the half height).
	_reach = maxf(_size.x * 0.5, _size.y)
	_angle = angle
	position = Iso.to_screen(ground) + Vector2(0.0, _reach * 0.5)


## Fish-like: half of the seabed's tint for its depth (src/shaders/fish_water.gdshader).
func set_water_colors(shallow: Color, deep: Color, clarity: float) -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = WATER_SHADER
	shader_material.set_shader_parameter("shallow_color", shallow)
	shader_material.set_shader_parameter("deep_color", deep)
	shader_material.set_shader_parameter("clarity", clarity)
	shader_material.set_shader_parameter("depth", SeaDepth.depth(ground_position.y))
	shader_material.set_shader_parameter("abyss", SeaDepth.abyss(ground_position.y))
	material = shader_material


## What the wader can swim behind: the screen rectangle the turning shoal covers.
func cover() -> Layers.Cover:
	var middle := _middle()
	return Layers.cover(self, Rect2(middle - Vector2(_reach, _reach * 0.5), Vector2(_reach * 2.0, _reach)))


func _process(delta: float) -> void:
	_angle = fmod(_angle + SPIN * delta, TAU)
	queue_redraw()


func _draw() -> void:
	var ground := Vector2(0.0, -_reach * 0.5)
	draw_colored_polygon(Iso.ellipse(ground, _reach * 0.75, 24), SHADOW_COLOR)
	# Turned on the ground, then squashed into the 2:1 view, about its middle.
	var squash := Transform2D(Vector2(1.0, 0.0), Vector2(0.0, 0.5), Vector2.ZERO)
	draw_set_transform_matrix(Transform2D(0.0, _middle()) * squash * Transform2D(_angle, Vector2.ZERO) * squash.affine_inverse())
	draw_texture_rect(TEXTURE, Rect2(-_size * 0.5, _size), false)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## The shoal's middle, relative to the node: above its ground middle by LIFT.
func _middle() -> Vector2:
	return Vector2(0.0, -_reach * 0.5 - LIFT)
