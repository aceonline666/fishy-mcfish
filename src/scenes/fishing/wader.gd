class_name Wader
extends Node2D
## The player character at shallow spots. Wades towards the finger, scoops up fish that come
## within reach of the hand net and carries them as a stack in a backpack basket. Game logic
## uses `ground_position`; the node sits at the feet on screen. Drawn from painted sprites in
## assets/sprites/wader (tools/extract_wader.py): the figure in the view of its walking direction,
## with painted legs stepping through a walk cycle, the basket of its backpack level, the landing
## net of its net level, and in deeper water the gear that zone calls for: snorkel mask, scuba
## gear, rebreather, hard-hat suit, submersible.

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
## Walking more sideways than this (share of the screen direction) shows a three-quarter view.
## Three-quarter views look screen-left towards the camera and screen-right away from it; they
## are mirrored for the other two diagonals.
const DIAGONAL_VIEW := 0.35
## Sprites that look the other way than their view.
const FLIPPED: Array[String] = ["scuba_away", "hardhat_away"]
## Screen height of the figure, from the boots to the top of the head.
const BODY_HEIGHT := 215.0
## Painted legs: frames per walk cycle (stride, passing, stride, passing), and the share of the
## figure's height above which the upper body is drawn over them. A few rows below the cut fade
## out, so no seam shows.
const LEG_FRAMES := 4
const HIP_CUT := 0.62
const SEAM_ROWS := 6
## Height of the eyes (share of the figure) and width of the snorkel mask.
const EYE_HEIGHT := 0.885
const SNORKEL_WIDTH := 54.0
const REBREATHER_HEIGHT := 112.0
const SUBMARINE_WIDTH := 230.0
## Baskets by size; the backpack level picks one. Their tops sit at BASKET_TOP.
const BASKET_WIDTHS: Array[float] = [54.0, 60.0, 66.0, 74.0, 84.0, 96.0]
const BASKET_TOP := -140.0
## The catch stack rises from the basket rim.
const STACK_BASE := Vector2(0.0, -136.0)
const STACK_STEP := 12.0
const STACK_FISH_LENGTH := 50.0
## Shoulder of the net arm, for side = +1 (net on the right).
const NET_SHOULDER := Vector2(27.0, -112.0)
## Landing nets by net level (assets/sprites/wader/net_N), seen from above: the hoop lies on the
## water over the catch ring with the bag below it, the painted handle points towards the wader
## (to the right in the sprite, mirrored when the wader is on the left). Hoop centre and width as
## shares of the sprite.
const NET_HOOP := Vector2(0.38, 0.22)
const NET_HOOP_WIDTH := 0.7
const NET_LEVELS := 6

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
## Index + 1 into the backpack levels; picks the basket.
var backpack_level := 1
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
	# Facing the camera, the backpack and the rebreather are hidden behind the body and the net is
	# in front.
	if from_behind:
		_draw_net(hoop, side, bob)
	else:
		_draw_rebreather(gear, view, bob)
		_draw_backpack(bob)
	_draw_body(view, bob, gear)
	if in_water and not swimming:
		_draw_water_around(WATERLINE_Y, 32.0)
	if gear == 2 or gear == 4:
		_draw_snorkel(view, bob)
	if swimming:
		_draw_water_around(SWIM_WATERLINE_Y, 46.0)
	if from_behind:
		_draw_rebreather(gear, view, bob)
		_draw_backpack(bob)
	else:
		_draw_net(hoop, side, bob)
	if full:
		_draw_label(tr("Backpack full!"), stack_top_position() - position + Vector2(0.0, -40.0 - bob))


## The figure of the outfit the gear calls for, in the view of the walking direction. Walking, the
## painted legs step through their cycle under the upper body (the front view and the hard-hat
## suit bend at the hips instead); the submersible just floats.
func _draw_body(view: Array, bob: float, gear: int) -> void:
	var outfit := _outfit(gear)
	var view_name: String = view[0]
	var sprite := "%s_%s" % [outfit, view_name]
	var texture := _texture(sprite)
	var mirror: float = view[1] * (-1.0 if FLIPPED.has(sprite) else 1.0)
	if outfit == "sub":
		var sub_size := texture.get_size() * (SUBMARINE_WIDTH / texture.get_width())
		draw_set_transform(Vector2(0.0, -bob - 40.0), 0.0, Vector2(mirror, 1.0))
		draw_texture_rect(texture, Rect2(Vector2(-sub_size.x * 0.5, -sub_size.y), sub_size), false)
		draw_set_transform(Vector2.ZERO)
		return
	var scale_factor := BODY_HEIGHT / texture.get_height()
	var size := texture.get_size() * scale_factor
	var rect := Rect2(Vector2(-size.x * 0.5, -size.y), size)
	var stride := clampf(ground_velocity.length() / WALK_SPEED, 0.0, 1.0)
	var base := Transform2D(sin(_walk_phase) * 0.02 * stride, Vector2(mirror, 1.0), 0.0, Vector2.ZERO)
	var has_legs := outfit != "hardhat" and ResourceLoader.exists(WADER_DIR + "legs_%s_1.png" % view_name)
	if stride > 0.05 and has_legs:
		_draw_stepping(texture, view_name, rect, scale_factor, base, bob)
	else:
		WalkDraw.figure(self, base, texture, rect, _walk_phase, stride, bob)
	draw_set_transform(Vector2.ZERO)


## The leg frame of the current step, then the upper body over it, fading out below the cut.
func _draw_stepping(texture: Texture2D, view_name: String, rect: Rect2, scale_factor: float, base: Transform2D, bob: float) -> void:
	draw_set_transform_matrix(base)
	var frame := int(_walk_phase / (PI * 0.5)) % LEG_FRAMES + 1
	var legs := _texture("legs_%s_%d" % [view_name, frame])
	var legs_size := legs.get_size() * scale_factor
	draw_texture_rect(legs, Rect2(Vector2(-legs_size.x * 0.5, -legs_size.y), legs_size), false)
	var source := texture.get_size()
	var cut := source.y * HIP_CUT
	var top := rect.position + Vector2(0.0, -bob)
	draw_texture_rect_region(texture, Rect2(top, Vector2(source.x, cut) * scale_factor), Rect2(0.0, 0.0, source.x, cut))
	for i in SEAM_ROWS:
		var row := Rect2(0.0, cut + i * 2.0, source.x, 2.0)
		var fade := 1.0 - (i + 1.0) / (SEAM_ROWS + 1.0)
		draw_texture_rect_region(texture, Rect2(top + row.position * scale_factor, row.size * scale_factor), row, Color(1.0, 1.0, 1.0, fade))


## The view for a screen direction, as [view name, mirror].
func _view(screen_facing: Vector2) -> Array:
	var away := screen_facing.y < 0.0
	if absf(screen_facing.x) <= DIAGONAL_VIEW:
		return ["back" if away else "front", 1.0]
	return ["away" if away else "towards", -1.0 if (screen_facing.x < 0.0) == away else 1.0]


## The figure worn for a gear level: waders (with snorkel or rebreather drawn on), scuba gear,
## the hard-hat suit or the submersible.
func _outfit(gear: int) -> String:
	match gear:
		3:
			return "scuba"
		5:
			return "hardhat"
		6:
			return "sub"
	return "body"


func _texture(sprite: String) -> Texture2D:
	if not _textures.has(sprite):
		_textures[sprite] = load(WADER_DIR + sprite + ".png")
	return _textures[sprite]


## Tints everything below the water surface and draws a ring where the surface meets the body.
func _draw_water_around(waterline: float, radius: float) -> void:
	draw_rect(Rect2(-radius, waterline, radius * 2.0, -waterline + 2.0), water_tint)
	draw_polyline(Iso.ellipse(Vector2(0.0, waterline), radius), Color(1.0, 1.0, 1.0, 0.7), 3.0, true)


## The snorkel mask over the eyes, in the view of the figure.
func _draw_snorkel(view: Array, bob: float) -> void:
	var view_name: String = view[0]
	var texture := _texture("snorkel_" + ("back" if view_name == "away" else view_name))
	var size := texture.get_size() * (SNORKEL_WIDTH / texture.get_width())
	draw_set_transform(Vector2(0.0, -BODY_HEIGHT * EYE_HEIGHT - bob), 0.0, Vector2(view[1], 1.0))
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y * 0.45), size), false)
	draw_set_transform(Vector2.ZERO)


## The rebreather on the back: seen from behind, or from the side in the three-quarter views.
func _draw_rebreather(gear: int, view: Array, bob: float) -> void:
	if gear != 4:
		return
	var view_name: String = view[0]
	var side_view := view_name == "towards" or view_name == "away"
	var texture := _texture("rebreather_side" if side_view else "rebreather_back")
	var size := texture.get_size() * (REBREATHER_HEIGHT / texture.get_height())
	# In the three-quarter views the back is on the side the figure looks away from.
	var shift := 14.0 * float(view[1]) * (1.0 if view_name == "towards" else -1.0) if side_view else 0.0
	draw_set_transform(Vector2(shift, -BODY_HEIGHT * 0.78 - bob), 0.0, Vector2(view[1], 1.0))
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, 0.0), size), false)
	draw_set_transform(Vector2.ZERO)


## The basket of the backpack level and the stack of caught fish, which sways while walking and leans back
## against the walking direction.
func _draw_backpack(bob: float) -> void:
	var index := clampi(backpack_level, 1, BASKET_WIDTHS.size())
	var basket := _texture("basket_%d" % index)
	var size := basket.get_size() * (BASKET_WIDTHS[index - 1] / basket.get_width())
	draw_texture_rect(basket, Rect2(Vector2(-size.x * 0.5, BASKET_TOP - bob), size), false)
	var lean := -Iso.to_screen(ground_velocity).x * 0.004
	var squash := 1.0 - 0.08 * sin(_stack_bounce * PI)
	for i in carried.size():
		var sway := sin(_walk_phase * 0.5 + i * 0.4) * 0.5 * i if is_walking() else 0.0
		var offset_x := (3.0 if i % 2 == 0 else -3.0) + sway + lean * i
		var at := STACK_BASE + Vector2(offset_x, -bob - STACK_STEP * i * squash)
		var mirror := 1.0 if i % 2 == 0 else -1.0
		carried[i].draw(self, Transform2D(Vector2(mirror, 0.0), Vector2(0.0, 1.0), at), STACK_FISH_LENGTH)


## The landing net of the net level, its hoop lying on the catch ring; the ring shows where the
## net catches, and the struggle meter fills around it.
func _draw_net(hoop: Vector2, side: float, bob: float) -> void:
	var shoulder := Vector2(NET_SHOULDER.x * side, NET_SHOULDER.y - bob)
	var hand := shoulder + shoulder.direction_to(hoop) * 30.0
	var ring := Iso.ellipse(hoop, scoop_radius, 32)
	draw_polyline(ring, HOOP_FULL if full else CATCH_RING, 3.0, true)

	var texture := _texture("net_%d" % clampi(net_level, 1, NET_LEVELS))
	var source := texture.get_size()
	var scale_factor := scoop_radius * 2.0 / (source.x * NET_HOOP_WIDTH)
	var mirror := -1.0 if hand.x < hoop.x else 1.0
	var origin := hoop - Vector2(NET_HOOP.x * source.x * mirror, NET_HOOP.y * source.y) * scale_factor
	draw_set_transform(origin, 0.0, Vector2(mirror, 1.0))
	draw_texture_rect(texture, Rect2(Vector2.ZERO, source * scale_factor), false)
	draw_set_transform(Vector2.ZERO)

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
