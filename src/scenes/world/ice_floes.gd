class_name IceFloes
extends Node2D
## Ice floes drifting on the surface of a zone (the Antarctic pack ice): painted sprites
## (`assets/sprites/props/ice_floe_<n>.png`, prompt in art_source/props/ice_floes_sprite_prompt.md),
## all drawn at the same scale (so their outlines match) and some mirrored, over a pale shimmer of the ice under the water. They
## lie on the surface layer (Layers.SURFACE), above the fish and the swimming wader; the wader shows
## through them see-through (Wader.surface_hides()). They bob and drift a little around their
## place, but stay where they are.

const SPRITES := 6
const SUBMERGED := Color(0.75, 0.93, 1.0, 0.25)
## Scale of every floe sprite. A floe's ground radius is half its sprite's width (Iso squashes a
## ground circle to an ellipse 2r wide and r high).
const SCALE := 1.0
## Open water between two floes even when they have drifted towards each other (ground units),
## and how far they stay inside the area's edges. A floe with no free place left is left out.
const GAP := 40.0
const MARGIN := 60.0
## Share of the sprite's height (from its bottom) taken by the side band below the top surface.
const SIDE := 0.17
## Share of the floe's radius that hides the wader (the painted outlines are irregular).
const SOLID := 0.85
## How far a floe drifts around its place (ground units).
const DRIFT := Vector2(35.0, 18.0)
## Drift speeds (radians per second) across and along the zone; the y phase runs Y_PHASE times faster.
const DRIFT_SPEED := Vector2(0.07, 0.05)
const Y_PHASE := 1.3
## Chance that a floe drifts in step with one already placed (a small raft drifting together, so
## the two may lie close), and how far its phase strays from that one's.
const RAFT := 0.5
const RAFT_JITTER := 0.35

var _textures: Array[Texture2D] = []

var _floes: Array[Floe] = []
var _time := 0.0


## Scatters `count` floes over the ground rectangle `area`.
func setup(area: Rect2, count: int, seed_value: int = 5) -> void:
	_load_textures()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_floes.clear()
	var first := rng.randi() % _textures.size()
	for i in count:
		var floe := Floe.new()
		floe.texture = _textures[(first + i) % _textures.size()]
		floe.radius = floe.texture.get_width() * SCALE * 0.5
		var placed := false
		for attempt in 80:
			var inner := area.grow(-MARGIN - floe.radius)
			floe.center = inner.position + Vector2(rng.randf(), rng.randf()) * inner.size
			# Uneven open water: a floe may lie next to one it drifts in step with.
			if not _floes.is_empty() and rng.randf() < RAFT:
				floe.phase = _floes[rng.randi() % _floes.size()].phase + rng.randf_range(-RAFT_JITTER, RAFT_JITTER)
			else:
				floe.phase = rng.randf() * TAU
			if not _crowded(floe):
				placed = true
				break
		floe.flip = rng.randf() < 0.5
		if placed:
			_floes.append(floe)
	_place()


func _load_textures() -> void:
	if not _textures.is_empty():
		return
	for i in SPRITES:
		_textures.append(load("res://assets/sprites/props/ice_floe_%d.png" % (i + 1)) as Texture2D)


## True when the screen rectangle `rect` (in this node's parent's coordinates) overlaps a floe.
func hides(rect: Rect2) -> bool:
	var box := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	for floe in _floes:
		if floe.rect.intersects(rect) and not Geometry2D.intersect_polygons(box, floe.top).is_empty():
			return true
	return false


## True when `floe` would come closer than GAP to a placed floe at some time. Two floes' drifts
## differ by at most 2·DRIFT·|sin(Δphase/2)| on each axis, so floes drifting in step may lie close.
func _crowded(floe: Floe) -> bool:
	for other in _floes:
		var apart := floe.phase - other.phase
		var sway := Vector2(2.0 * DRIFT.x * absf(sin(apart * 0.5)), 2.0 * DRIFT.y * absf(sin(apart * Y_PHASE * 0.5)))
		if floe.center.distance_to(other.center) < floe.radius + other.radius + GAP + sway.length():
			return true
	return false


## Where the centre of `floe` has drifted to at time `time` (ground units).
static func drifted(floe: Floe, time: float) -> Vector2:
	return floe.center + Vector2(sin(time * DRIFT_SPEED.x + floe.phase) * DRIFT.x, cos(time * DRIFT_SPEED.y + floe.phase * Y_PHASE) * DRIFT.y)


func _process(delta: float) -> void:
	if _floes.is_empty():
		return
	_time += delta
	_place()
	queue_redraw()


## Moves the floes to where they have drifted at this time: the sprite's rectangle on screen and
## the outline of its top, which hides the wader.
func _place() -> void:
	for floe in _floes:
		var drift := drifted(floe, _time) - floe.center
		var bob := sin(_time * 0.9 + floe.phase) * 1.5
		var size := floe.texture.get_size() * SCALE
		var waterline := Iso.to_screen(floe.center + drift) + Vector2(0.0, bob)
		# The sprite stands on the floe's front edge at the waterline; its top lies above the
		# side band.
		floe.rect = Rect2(waterline.x - size.x * 0.5, waterline.y + floe.radius * 0.5 - size.y, size.x, size.y)
		floe.below = _moved(Iso.ellipse(Iso.to_screen(floe.center + drift), floe.radius * 1.08), Vector2(0.0, bob))
		floe.top = _moved(Iso.ellipse(Iso.to_screen(floe.center + drift), floe.radius * SOLID), Vector2(0.0, bob - size.y * SIDE))
	_floes.sort_custom(func(a: Floe, b: Floe) -> bool: return a.rect.end.y < b.rect.end.y)


func _draw() -> void:
	var view := get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	for floe in _floes:
		if not view.grow(40.0).intersects(floe.rect):
			continue
		# The ice under the water reaches a little further out, paler.
		draw_colored_polygon(floe.below, SUBMERGED)
		if floe.flip:
			# Mirrored around the floe's centre line.
			var mid := floe.rect.get_center().x
			draw_set_transform(Vector2(2.0 * mid, 0.0), 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect(floe.texture, floe.rect, false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect(floe.texture, floe.rect, false)


static func _moved(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		out.append(point + by)
	return out


class Floe extends RefCounted:
	## Ground position and size, the sprite (mirrored or not), the swaying phase.
	var center := Vector2.ZERO
	var radius := 100.0
	var texture: Texture2D
	var flip := false
	var phase := 0.0
	## Where it is now: the sprite's rectangle on screen, the outline of its top and of the ice
	## under the water around it.
	var rect := Rect2()
	var top := PackedVector2Array()
	var below := PackedVector2Array()
