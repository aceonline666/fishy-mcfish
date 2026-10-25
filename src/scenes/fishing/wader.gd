class_name Wader
extends Node2D
## The player character at shallow spots. Wades towards the finger, scoops up fish that come
## within reach of the hand net and carries them as a stack in a backpack basket. Game logic
## uses `ground_position`; the node sits at the feet on screen. Drawn from painted sprites
## (assets/sprites/props): the figure in the view of its walking direction, the landing net of
## its net level, and in deeper water the diving gear that zone calls for (snorkel mask, scuba
## tanks, rebreather, hard-hat suit, submersible).

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

## Painted full figure (assets/sprites/props): straight front and back views, and three-quarter
## views towards the camera (facing screen-left) and away from it (facing screen-right), mirrored
## for the other two diagonals.
const FRONT_TEXTURE := preload("res://assets/sprites/props/wader_front.png")
const BACK_TEXTURE := preload("res://assets/sprites/props/wader_back.png")
const TOWARDS_TEXTURE := preload("res://assets/sprites/props/wader_right.png")
const AWAY_TEXTURE := preload("res://assets/sprites/props/wader_left.png")
## Walking more sideways than this (share of the screen direction) shows a three-quarter view.
const DIAGONAL_VIEW := 0.35
## Screen height of the figure, from the boots to the hat.
const BODY_HEIGHT := 215.0
const BASKET_TEXTURE := preload("res://assets/sprites/wader/wader_basket.svg")
## Where the sprites go relative to the feet, in screen pixels.
const BASKET_RECT := Rect2(-32.0, -140.0, 64.0, 56.0)
## The catch stack rises from the basket rim.
const STACK_BASE := Vector2(0.0, -136.0)
const STACK_STEP := 12.0
const STACK_FISH_LENGTH := 50.0
## Shoulder of the net arm, for side = +1 (net on the right).
const NET_SHOULDER := Vector2(27.0, -112.0)
## Landing nets by net level, held at the handle end with the hoop over the catch point.
## Handle end and hoop centre as shares of the sprite.
const NET_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/net_1.png"), preload("res://assets/sprites/props/net_2.png"),
	preload("res://assets/sprites/props/net_3.png"), preload("res://assets/sprites/props/net_4.png"),
	preload("res://assets/sprites/props/net_5.png"), preload("res://assets/sprites/props/net_6.png"),
]
const NET_HANDLE := Vector2(0.015, 0.965)
const NET_HOOP := Vector2(0.75, 0.28)
## Diving gear by gear level (1 = waders, nothing extra to draw).
const SNORKEL_TEXTURE := preload("res://assets/sprites/props/gear_2.png")
const TANK_TEXTURES: Dictionary[int, Texture2D] = {
	3: preload("res://assets/sprites/props/gear_3.png"), 4: preload("res://assets/sprites/props/gear_4.png"),
}
const SUIT_TEXTURE := preload("res://assets/sprites/props/gear_5.png")
const SUBMARINE_TEXTURE := preload("res://assets/sprites/props/gear_6.png")
const SNORKEL_WIDTH := 66.0
const TANK_HEIGHT := 125.0
const SUBMARINE_WIDTH := 230.0
## Where the eyes are, relative to the feet.
const EYES := Vector2(4.0, -170.0)

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
	var from_behind := screen_facing.y < 0.0
	var bob := absf(sin(_walk_phase)) * 5.0 if is_walking() else sin(_time * 2.0) * 1.5
	var hoop := _hoop_offset()
	# Each zone calls for its gear: snorkel in the second, scuba in the third, and so on.
	var gear := mini(gear_level, zone_order) if swimming else 1

	draw_colored_polygon(Iso.ellipse(Vector2.ZERO, 30.0), SHADOW)
	# Facing the camera, the backpack and tanks are hidden behind the body and the net is in front.
	if from_behind:
		_draw_net(hoop, side, bob)
	else:
		_draw_tanks(gear, side, bob)
		_draw_backpack(bob)
	_draw_body(screen_facing.normalized(), bob, gear)
	if in_water and not swimming:
		_draw_water_around(WATERLINE_Y, 32.0)
	if gear in [2, 3, 4] and not from_behind:
		_draw_snorkel(side, bob)
	if swimming:
		_draw_water_around(SWIM_WATERLINE_Y, 46.0)
	if from_behind:
		_draw_tanks(gear, side, bob)
		_draw_backpack(bob)
	else:
		_draw_net(hoop, side, bob)
	if full:
		_draw_label(tr("Backpack full!"), stack_top_position() - position + Vector2(0.0, -40.0 - bob))


## The view that matches the walking direction; the figure bobs and sways a little while walking.
## In the two deepest zones the hard-hat suit or the submersible takes its place.
func _draw_body(screen_facing: Vector2, bob: float, gear: int) -> void:
	if gear >= 5:
		_draw_vehicle(SUIT_TEXTURE if gear == 5 else SUBMARINE_TEXTURE, screen_facing, bob, gear == 6)
		return
	var away := screen_facing.y < 0.0
	var texture := BACK_TEXTURE if away else FRONT_TEXTURE
	var mirror := 1.0
	if absf(screen_facing.x) > DIAGONAL_VIEW:
		texture = AWAY_TEXTURE if away else TOWARDS_TEXTURE
		mirror = -1.0 if (screen_facing.x < 0.0) == away else 1.0
	var size := texture.get_size() * (BODY_HEIGHT / texture.get_height())
	var stride := clampf(ground_velocity.length() / WALK_SPEED, 0.0, 1.0)
	var sway := sin(_walk_phase) * 0.03 * stride
	var base := Transform2D(sway, Vector2(mirror, 1.0), 0.0, Vector2.ZERO)
	WalkDraw.figure(self, base, texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), _walk_phase, stride, bob)
	draw_set_transform(Vector2.ZERO)


## Tints everything below the water surface and draws a ring where the surface meets the body.
func _draw_water_around(waterline: float, radius: float) -> void:
	draw_rect(Rect2(-radius, waterline, radius * 2.0, -waterline + 2.0), water_tint)
	draw_polyline(Iso.ellipse(Vector2(0.0, waterline), radius), Color(1.0, 1.0, 1.0, 0.7), 3.0, true)


## The snorkel mask over the eyes, its tube on the far side.
func _draw_snorkel(side: float, bob: float) -> void:
	var size := SNORKEL_TEXTURE.get_size() * (SNORKEL_WIDTH / SNORKEL_TEXTURE.get_width())
	draw_set_transform(Vector2(EYES.x * side, EYES.y - bob), 0.0, Vector2(side, 1.0))
	draw_texture_rect(SNORKEL_TEXTURE, Rect2(Vector2(-size.x * 0.45, -size.y * 0.35), size), false)
	draw_set_transform(Vector2.ZERO)


## Scuba tanks or the rebreather on the back.
func _draw_tanks(gear: int, side: float, bob: float) -> void:
	if not TANK_TEXTURES.has(gear):
		return
	var texture := TANK_TEXTURES[gear]
	var size := texture.get_size() * (TANK_HEIGHT / texture.get_height())
	draw_set_transform(Vector2(-side * 34.0, -105.0 - bob), 0.0, Vector2(side, 1.0))
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y * 0.6), size), false)
	draw_set_transform(Vector2.ZERO)


## The hard-hat suit or the submersible instead of the figure, turned to the walking side.
func _draw_vehicle(texture: Texture2D, screen_facing: Vector2, bob: float, submarine: bool) -> void:
	var size := texture.get_size() * (SUBMARINE_WIDTH / texture.get_width() if submarine else BODY_HEIGHT / texture.get_height())
	# The suit faces the camera; the submersible looks to screen-left.
	var mirror := 1.0
	if submarine and screen_facing.x > 0.0:
		mirror = -1.0
	draw_set_transform(Vector2(0.0, -bob - (60.0 if submarine else 0.0)), 0.0, Vector2(mirror, 1.0))
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), false)
	draw_set_transform(Vector2.ZERO)


## The basket and the stack of caught fish, which sways while walking and leans back
## against the walking direction.
func _draw_backpack(bob: float) -> void:
	draw_texture_rect(BASKET_TEXTURE, Rect2(BASKET_RECT.position + Vector2(0.0, -bob), BASKET_RECT.size), false)
	var lean := -Iso.to_screen(ground_velocity).x * 0.004
	var squash := 1.0 - 0.08 * sin(_stack_bounce * PI)
	for i in carried.size():
		var sway := sin(_walk_phase * 0.5 + i * 0.4) * 0.5 * i if is_walking() else 0.0
		var offset_x := (3.0 if i % 2 == 0 else -3.0) + sway + lean * i
		var at := STACK_BASE + Vector2(offset_x, -bob - STACK_STEP * i * squash)
		var mirror := 1.0 if i % 2 == 0 else -1.0
		carried[i].draw(self, Transform2D(Vector2(mirror, 0.0), Vector2(0.0, 1.0), at), STACK_FISH_LENGTH)


## The landing net of the net level, from the hand to the hoop; on the water a ring shows where
## the net catches, and the struggle meter fills around it.
func _draw_net(hoop: Vector2, side: float, bob: float) -> void:
	var shoulder := Vector2(NET_SHOULDER.x * side, NET_SHOULDER.y - bob)
	var hand := shoulder + shoulder.direction_to(hoop) * 30.0
	var rim := Iso.ellipse(hoop, scoop_radius, 32)
	draw_polyline(rim, HOOP_FULL if full else CATCH_RING, 3.0, true)

	var texture := NET_TEXTURES[clampi(net_level, 1, NET_TEXTURES.size()) - 1]
	var size := texture.get_size()
	var handle := NET_HANDLE * size
	var along := NET_HOOP * size - handle
	var mirror := 1.0
	if hoop.x < hand.x:
		# Held to the left: mirror the sprite so the mesh hangs down.
		mirror = -1.0
		along.x = -along.x
	var reach := hoop - hand
	var turn := reach.angle() - along.angle()
	var stretch := reach.length() / maxf(along.length(), 1.0)
	draw_set_transform_matrix(Transform2D(turn, Vector2(stretch, stretch), 0.0, hand) * Transform2D(0.0, Vector2(mirror, 1.0), 0.0, Vector2.ZERO))
	draw_texture_rect(texture, Rect2(-handle, size), false)
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
