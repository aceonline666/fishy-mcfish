class_name Wader
extends Node2D
## The player character at shallow spots. Wades towards the finger, scoops up fish that come
## within reach of the hand net and carries them as a stack in a backpack basket. Game logic
## uses `ground_position`; the node sits at the feet on screen. Drawn from painted sprites in
## assets/sprites/wader: the figure in the outfit the zone calls for (waders with the basket,
## snorkel, scuba gear, rebreather, hard-hat suit, submersible; tools/extract_diver.py) in the
## view of its walking direction, its legs swinging in step while walking, with the catch stacked
## on its back and the landing net of its net level (tools/extract_wader.py).

const WALK_SPEED := 450.0
const ACCELERATION := 2400.0
## Share of the speed kept when the finger lifts.
const STOP_KEEP_SPEED := 0.2
const ARRIVE_DISTANCE := 10.0
## Starts slowing down this close to the target, so arrival feels soft.
const SLOWDOWN_DISTANCE := 70.0
## Distance from the feet to the centre of the net hoop, in ground units.
const REACH := 95.0
## Net radius with the hand net; better nets are a little wider.
const SCOOP_RADIUS := 55.0
## Screen height of the water surface at the legs (knee-deep), and at the chest when swimming.
const WATERLINE_Y := -26.0
const SWIM_WATERLINE_Y := -96.0

const WADER_DIR := "res://assets/sprites/wader/"
## Walking more sideways than this (share of the screen direction) shows a three-quarter view,
## and nearly straight across the screen (less up or down than SIDE_VIEW) the profile. These views
## are painted looking screen-left; they are mirrored when walking to the right.
const DIAGONAL_VIEW := 0.35
const SIDE_VIEW := 0.5
## Share of the figures' height (from the top) at the hips, where the legs swing from.
const FIGURE_HIP := 0.622
## Outfits by gear level.
const OUTFITS: Array[String] = ["wader", "snorkel", "scuba", "rebreather", "hardhat", "sub"]
## The submersible floats this high above the ground.
const SUB_FLOAT := 40.0
## The catch stack rises from the basket rim.
const STACK_BASE := Vector2(0.0, -136.0)
const STACK_STEP := 12.0
const STACK_FISH_LENGTH := 50.0
## Shoulder of the net arm, for side = +1 (net on the right).
const NET_SHOULDER := Vector2(27.0, -112.0)
## Landing nets by net level (assets/sprites/wader/net_N): the hoop lies on the water at the catch
## point, and the painted handle runs from it to the hand, stretched along its own length as far
## as needed (the hoop keeps its shape). In the sprites: the hoop centre, the handle's tip and the
## hoop's width as shares of the sprite, and where the handle starts (share of the width, measured
## from the hoop centre along the handle).
const NET_HOOP := Vector2(0.40, 0.29)
const NET_TIPS: Array[Vector2] = [
	Vector2(0.927, 0.565), Vector2(0.915, 0.776), Vector2(0.94, 0.623), Vector2(0.94, 0.55), Vector2(0.925, 0.115),
	Vector2(0.931, 0.551),
]
const NET_HOOP_WIDTH := 0.68
const NET_HANDLE_START := 0.36
## Screen width of the hoop with the first net; better nets are a little bigger.
const NET_HOOP_SCREEN := 64.0
const NET_GROWTH := 0.08

const OUTLINE := Color(0.07, 0.09, 0.15)
## The ring on the water that shows where the net catches.
const CATCH_RING := Color(1.0, 1.0, 1.0, 0.45)
const HOOP_FULL := Color(1.0, 0.45, 0.3)
const WATER_TINT := Color(0.18, 0.55, 0.72, 0.6)
const SHADOW := Color(0.0, 0.06, 0.14, 0.25)
const PROGRESS := Color(1.0, 0.85, 0.2)

var ground_position := Vector2.ZERO
var ground_velocity := Vector2.ZERO
## Ground direction the wader faces; starts facing the camera.
var facing := Vector2(1.0, 1.0).normalized()
## How close the furthest-along struggling fish is to being caught, 0..1.
var struggle_progress := 0.0
## True when the backpack is full; shown above the stack.
var full := false
## The fish in the backpack, bottom first.
var carried: Array[FishArt] = []
## False on the beach: no water around the legs.
var in_water := true
## Colour of the water around the body; darker in the deep sea.
var water_tint := WATER_TINT
## True in deeper zones: the water comes up to the chest.
var swimming := false
## Diving gear bought: the gear for the current zone is worn, up to this level.
var gear_level := 1
## Order of the depth zone the wader is in; 0 on the beach.
var zone_order := 0
## Index + 1 into the net levels; picks the landing net.
var net_level := 1
## Current net radius (grows with the net level).
var scoop_radius := SCOOP_RADIUS
## Walking speed factor: faster on the sand than in the water.
var speed_multiplier := 1.0

var _target := Vector2.ZERO
var _has_target := false
var _walk_phase := 0.0
var _time := 0.0
var _dip := 0.0
var _stack_bounce := 0.0
## Loaded sprites by name.
var _textures: Dictionary[String, Texture2D] = {}


func walk_to(ground_target: Vector2) -> void:
	_target = ground_target
	_has_target = true


## Stops walking, braking hard so it only takes a short step.
func stop() -> void:
	_has_target = false
	ground_velocity *= STOP_KEEP_SPEED


func is_walking() -> bool:
	return ground_velocity.length() > 20.0


## Ground centre of the net hoop, where fish are scooped up.
func scoop_center() -> Vector2:
	return ground_position + facing * REACH


func hoop_screen_position() -> Vector2:
	return position + _hoop_offset()


## Screen position of the top of the catch stack.
func stack_top_position() -> Vector2:
	return position + STACK_BASE + Vector2(0.0, -STACK_STEP * maxi(carried.size() - 1, 0))


## Puts a caught fish on top of the stack, with a short dip of the net.
func add_to_stack(art: FishArt) -> void:
	carried.append(art)
	_dip = 1.0
	_stack_bounce = 1.0


## Takes the top fish off the stack.
func take_from_stack() -> FishArt:
	return take_from_stack_at(carried.size() - 1)


## Takes a fish out of the stack; the ones above it drop down.
func take_from_stack_at(index: int) -> FishArt:
	_stack_bounce = 0.6
	var art := carried[index]
	carried.remove_at(index)
	return art


func simulate(delta: float, area: PlayArea) -> void:
	_time += delta
	_dip = maxf(_dip - delta * 5.0, 0.0)
	_stack_bounce = maxf(_stack_bounce - delta * 4.0, 0.0)
	var desired := Vector2.ZERO
	if _has_target:
		var to_target := _target - ground_position
		var distance := to_target.length()
		if distance > ARRIVE_DISTANCE:
			desired = to_target / distance * WALK_SPEED * speed_multiplier * minf(distance / SLOWDOWN_DISTANCE, 1.0)
		else:
			_has_target = false
	ground_velocity = ground_velocity.move_toward(desired, ACCELERATION * delta)
	ground_position = area.clamp_point(ground_position + ground_velocity * delta, 20.0)
	if is_walking():
		facing = facing.slerp(ground_velocity.normalized(), clampf(10.0 * delta, 0.0, 1.0)).normalized()
	_walk_phase += delta * ground_velocity.length() / 42.0
	position = Iso.to_screen(ground_position)
	queue_redraw()


func _hoop_offset() -> Vector2:
	return Iso.to_screen(facing * REACH) + Vector2(0.0, 6.0 * _dip)


#region Drawing

func _draw() -> void:
	var screen_facing := Iso.to_screen(facing)
	var side := -1.0 if screen_facing.x < 0.0 else 1.0
	var bob := absf(sin(_walk_phase)) * 5.0 if is_walking() else sin(_time * 2.0) * 1.5
	var hoop := _hoop_offset()
	# Each zone calls for its gear: snorkel in the second, scuba in the third, and so on.
	var gear := mini(gear_level, zone_order) if swimming else 1
	var view := _view(screen_facing.normalized())
	var view_name: String = view[0]
	var from_behind := view_name == "back" or view_name == "away"

	draw_colored_polygon(Iso.ellipse(Vector2.ZERO, 30.0), SHADOW)
	# Facing the camera, the catch on the back is hidden behind the body and the net is in front.
	if from_behind:
		_draw_net(hoop, side, bob)
	else:
		_draw_stack(bob)
	_draw_body(view, bob, gear)
	if in_water and not swimming:
		_draw_water_around(WATERLINE_Y, 32.0)
	if swimming:
		_draw_water_around(SWIM_WATERLINE_Y, 46.0)
	if from_behind:
		_draw_stack(bob)
	else:
		_draw_net(hoop, side, bob)
	if full:
		_draw_label(tr("Backpack full!"), stack_top_position() - position + Vector2(0.0, -40.0 - bob))


## The outfit the gear calls for, in the view of the walking direction, its legs swinging in
## step while walking. The submersible just floats.
func _draw_body(view: Array, bob: float, gear: int) -> void:
	var outfit := OUTFITS[clampi(gear, 1, OUTFITS.size()) - 1]
	var texture := _texture("%s_%s" % [outfit, view[0]])
	var size := texture.get_size()
	if outfit == "sub":
		draw_set_transform(Vector2(0.0, -bob - SUB_FLOAT), 0.0, Vector2(view[1], 1.0))
		draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), false)
		draw_set_transform(Vector2.ZERO)
		return
	var stride := clampf(ground_velocity.length() / WALK_SPEED, 0.0, 1.0)
	var base := Transform2D(sin(_walk_phase) * 0.02 * stride, Vector2(view[1], 1.0), 0.0, Vector2.ZERO)
	WalkDraw.figure(self, base, texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), _walk_phase, stride, bob, FIGURE_HIP)
	draw_set_transform(Vector2.ZERO)


## The view for a screen direction, as [view name, mirror].
func _view(screen_facing: Vector2) -> Array:
	var away := screen_facing.y < 0.0
	if absf(screen_facing.x) <= DIAGONAL_VIEW:
		return ["back" if away else "front", 1.0]
	var name := "side" if absf(screen_facing.y) < SIDE_VIEW else ("away" if away else "towards")
	return [name, -1.0 if screen_facing.x > 0.0 else 1.0]


func _texture(sprite: String) -> Texture2D:
	if not _textures.has(sprite):
		_textures[sprite] = load(WADER_DIR + sprite + ".png")
	return _textures[sprite]


## Tints everything below the water surface and draws a ring where the surface meets the body.
func _draw_water_around(waterline: float, radius: float) -> void:
	draw_rect(Rect2(-radius, waterline, radius * 2.0, -waterline + 2.0), water_tint)
	draw_polyline(Iso.ellipse(Vector2(0.0, waterline), radius), Color(1.0, 1.0, 1.0, 0.7), 3.0, true)


## The stack of caught fish on the back, which sways while walking and leans back against the
## walking direction.
func _draw_stack(bob: float) -> void:
	var lean := -Iso.to_screen(ground_velocity).x * 0.004
	var squash := 1.0 - 0.08 * sin(_stack_bounce * PI)
	for i in carried.size():
		var sway := sin(_walk_phase * 0.5 + i * 0.4) * 0.5 * i if is_walking() else 0.0
		var offset_x := (3.0 if i % 2 == 0 else -3.0) + sway + lean * i
		var at := STACK_BASE + Vector2(offset_x, -bob - STACK_STEP * i * squash)
		var mirror := 1.0 if i % 2 == 0 else -1.0
		carried[i].draw(self, Transform2D(Vector2(mirror, 0.0), Vector2(0.0, 1.0), at), STACK_FISH_LENGTH)


## The landing net of the net level, its hoop lying on the water at the catch point and its handle
## reaching up to the hand; the ring shows where the net catches, and the struggle meter fills
## around it.
func _draw_net(hoop: Vector2, side: float, bob: float) -> void:
	var shoulder := Vector2(NET_SHOULDER.x * side, NET_SHOULDER.y - bob)
	var hand := shoulder + shoulder.direction_to(hoop) * 30.0
	var ring := Iso.ellipse(hoop, scoop_radius, 32)
	draw_polyline(ring, HOOP_FULL if full else CATCH_RING, 3.0, true)

	var level := clampi(net_level, 1, NET_TIPS.size())
	var texture := _texture("net_%d" % level)
	var size := texture.get_size()
	var center := NET_HOOP * size
	var along := NET_TIPS[level - 1] * size - center
	var tip_distance := along.length()
	var u := along / tip_distance
	var v := u.orthogonal()
	var handle_start := NET_HANDLE_START * size.x
	var scale_factor := NET_HOOP_SCREEN * (1.0 + NET_GROWTH * (level - 1)) / (size.x * NET_HOOP_WIDTH)
	var reach := hand - hoop
	var stretch := maxf((reach.length() / scale_factor - handle_start) / (tip_distance - handle_start), 0.2)
	var turn := reach.angle() - u.angle()
	# Mirror the sprite across the handle if needed, so the bag hangs below the hoop on screen.
	var flip := 1.0 if v.rotated(turn).y * v.y >= 0.0 else -1.0
	var big := size.length()
	var handle_half := size.y * 0.25
	for part: Array in [[-big, handle_start, -big, big], [handle_start, tip_distance + 8.0, -handle_half, handle_half]]:
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for corner: Vector2 in [Vector2(part[0], part[2]), Vector2(part[1], part[2]), Vector2(part[1], part[3]), Vector2(part[0], part[3])]:
			uvs.append((center + u * corner.x + v * corner.y) / size)
			var a := corner.x if corner.x <= handle_start else handle_start + (corner.x - handle_start) * stretch
			points.append(hoop + (u * a + v * corner.y * flip).rotated(turn) * scale_factor)
		draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, texture)

	if struggle_progress > 0.0:
		var arc := Iso.ellipse_arc(hoop, scoop_radius + 16.0, -PI * 0.5, -PI * 0.5 + TAU * struggle_progress, 28)
		draw_polyline(arc, OUTLINE, 12.0, true)
		draw_polyline(arc, PROGRESS, 7.0, true)


func _draw_label(text: String, at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var width := 320.0
	var origin := at - Vector2(width * 0.5, 0.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, 34, 10, OUTLINE)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, 34, HOOP_FULL)

#endregion
