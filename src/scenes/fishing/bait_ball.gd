class_name BaitBall
extends Node2D
## A bait ball: a few dozen small sardines circling tightly together in the water, as in the
## Sardine run. Each is the species' painted sprite (FishArt), drawn small, on its own circle at
## its own height and speed, so the ball churns. Only decoration: they cannot be caught.
##
## The node sits at the ball's front edge on the ground, so it is sorted in front of everything
## inside it: the wader swimming into it is behind it (`cover()`) and shows see-through, as
## behind the gear shop.

const WATER_SHADER := preload("res://src/shaders/fish_water.gdshader")
## Ground radius of the ball; the fish circle between INNER and 1 of it.
const RADIUS := 75.0
const INNER := 0.25
## How high the ball floats above the seabed, in screen pixels (as the fish:
## SwimmingFish.SHADOW_DROP), and how far the fish spread up and down around that.
const LIFT := SwimmingFish.SHADOW_DROP
const SPREAD := 24.0
## Screen length of a fish, and its swimming speed in ground units per second.
const LENGTH := Vector2(22.0, 30.0)
const SPEED := Vector2(70.0, 110.0)
## Radians per second the tail beats.
const BEAT := 14.0
const SHADOW_COLOR := Color(0.0, 0.06, 0.14, 0.14)

var ground_position := Vector2.ZERO
var _art: FishArt
var _fish: Array[Sardine] = []


## `count` fish of `art`'s species around `ground`; `rng` decides where each one swims.
func setup(art: FishArt, ground: Vector2, count: int, rng: RandomNumberGenerator) -> void:
	_art = art
	ground_position = ground
	# The ground circle's front edge is half its radius below its middle on screen.
	position = Iso.to_screen(ground) + Vector2(0.0, RADIUS * 0.5)
	for i in count:
		var sardine := Sardine.new()
		sardine.radius = RADIUS * sqrt(rng.randf_range(INNER * INNER, 1.0))
		sardine.angle = rng.randf() * TAU
		# All circle the same way, the outer ones a little slower round.
		sardine.turn = rng.randf_range(SPEED.x, SPEED.y) / sardine.radius
		sardine.height = rng.randf_range(-SPREAD, SPREAD)
		sardine.bob = rng.randf() * TAU
		sardine.length = rng.randf_range(LENGTH.x, LENGTH.y)
		sardine.phase = rng.randf() * TAU
		_fish.append(sardine)


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


## What the wader can swim behind: the screen rectangle the ball fills.
func cover() -> Layers.Cover:
	var top := -RADIUS - LIFT - SPREAD - LENGTH.y
	return Layers.cover(self, Rect2(Vector2(-RADIUS - LENGTH.y, top), Vector2((RADIUS + LENGTH.y) * 2.0, -top)))


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	for sardine in _fish:
		sardine.angle = fmod(sardine.angle + sardine.turn * delta, TAU)
		sardine.phase += BEAT * delta
		sardine.bob += delta
	queue_redraw()


func _draw() -> void:
	var middle := Vector2(0.0, -RADIUS * 0.5)
	draw_colored_polygon(Iso.ellipse(middle, RADIUS * 0.8, 24), SHADOW_COLOR)
	# Back to front, so the nearer fish are drawn over the farther ones.
	var placed: Array[Array] = []
	for sardine in _fish:
		var around := Vector2.from_angle(sardine.angle)
		var at := middle + Iso.to_screen(around * sardine.radius)
		at.y -= LIFT + sardine.height + sin(sardine.bob * 1.3) * 4.0
		placed.append([at, -around.orthogonal(), sardine])
	placed.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	for entry in placed:
		var sardine: Sardine = entry[2]
		_art.draw(self, Transform2D(0.0, entry[0]) * _view(entry[1]), sardine.length, sardine.phase, 1.0)


## Side-on, like SwimmingFish: back up, mirrored when swimming left, tilted a little with the
## on-screen direction and shortened when swimming towards or away from the camera.
static func _view(ground_direction: Vector2) -> Transform2D:
	var screen_direction := Iso.to_screen(ground_direction).normalized()
	var facing_right := Vector2(absf(screen_direction.x), screen_direction.y)
	var tilt := clampf(facing_right.angle(), -SwimmingFish.MAX_TILT, SwimmingFish.MAX_TILT)
	var foreshorten := lerpf(SwimmingFish.MIN_FORESHORTEN, 1.0, facing_right.x)
	var view := Transform2D(tilt, Vector2.ZERO) * Transform2D(Vector2(foreshorten, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	if screen_direction.x < 0.0:
		view = Transform2D(Vector2(-1.0, 0.0), Vector2(0.0, 1.0), Vector2.ZERO) * view
	return view


class Sardine extends RefCounted:
	var radius := 0.0
	var angle := 0.0
	## Radians per second round the ball.
	var turn := 0.0
	var height := 0.0
	var bob := 0.0
	var length := 0.0
	var phase := 0.0
