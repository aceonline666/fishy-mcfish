class_name Wader
extends Node2D
## The player character at shallow spots. Wades towards the finger, scoops up fish that come
## within reach of the hand net and carries them as a stack in a backpack basket. Game logic
## uses `ground_position`; the node sits at the feet on screen. The body is drawn from SVG
## sprites (front and back view, mirrored for left and right); the net is drawn in code.

const WALK_SPEED := 320.0
const ACCELERATION := 2400.0
const ARRIVE_DISTANCE := 10.0
## Starts slowing down this close to the target, so arrival feels soft.
const SLOWDOWN_DISTANCE := 70.0
## Distance from the feet to the centre of the net hoop, in ground units.
const REACH := 95.0
const SCOOP_RADIUS := 55.0
## Screen height of the water surface at the legs (knee-deep).
const WATERLINE_Y := -26.0

const FRONT_TEXTURE := preload("res://assets/sprites/wader/wader_front.svg")
const BACK_TEXTURE := preload("res://assets/sprites/wader/wader_back.svg")
const LEG_TEXTURE := preload("res://assets/sprites/wader/wader_leg.svg")
const BASKET_TEXTURE := preload("res://assets/sprites/wader/wader_basket.svg")
## Where the sprites go relative to the feet, in screen pixels.
const UPPER_BODY_RECT := Rect2(-60.0, -204.0, 120.0, 150.0)
const LEG_SIZE := Vector2(30.0, 70.0)
const BASKET_RECT := Rect2(-32.0, -140.0, 64.0, 56.0)
## The catch stack rises from the basket rim.
const STACK_BASE := Vector2(0.0, -136.0)
const STACK_STEP := 12.0
const STACK_FISH_LENGTH := 50.0
## Shoulder of the net arm, for side = +1 (net on the right).
const NET_SHOULDER := Vector2(27.0, -112.0)

const OUTLINE := Color(0.07, 0.09, 0.15)
const SKIN := Color(1.0, 0.81, 0.62)
const JACKET := Color(1.0, 0.8, 0.16)
const POLE := Color(0.6, 0.42, 0.24)
const HOOP := Color(0.93, 0.78, 0.5)
const HOOP_FULL := Color(1.0, 0.45, 0.3)
const NET_FILL := Color(1.0, 1.0, 1.0, 0.18)
const NET_MESH := Color(1.0, 1.0, 1.0, 0.4)
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

var _target := Vector2.ZERO
var _has_target := false
var _walk_phase := 0.0
var _time := 0.0
var _dip := 0.0
var _stack_bounce := 0.0


func walk_to(ground_target: Vector2) -> void:
	_target = ground_target
	_has_target = true


func stop() -> void:
	_has_target = false


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
			desired = to_target / distance * WALK_SPEED * minf(distance / SLOWDOWN_DISTANCE, 1.0)
		else:
			_has_target = false
	ground_velocity = ground_velocity.move_toward(desired, ACCELERATION * delta)
	ground_position = area.clamp_point(ground_position + ground_velocity * delta, 20.0)
	if is_walking():
		facing = facing.slerp(ground_velocity.normalized(), clampf(10.0 * delta, 0.0, 1.0)).normalized()
	_walk_phase += delta * ground_velocity.length() / 26.0
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

	draw_colored_polygon(Iso.ellipse(Vector2.ZERO, 30.0), SHADOW)
	# Facing the camera, the backpack is hidden behind the body and the net is in front.
	if from_behind:
		_draw_net(hoop, side, bob)
	else:
		_draw_backpack(bob)
	_draw_legs()
	draw_set_transform(Vector2(0.0, -bob), 0.0, Vector2(side, 1.0))
	draw_texture_rect(BACK_TEXTURE if from_behind else FRONT_TEXTURE, UPPER_BODY_RECT, false)
	draw_set_transform(Vector2.ZERO)
	if from_behind:
		_draw_backpack(bob)
	else:
		_draw_net(hoop, side, bob)
	if full:
		_draw_label("Backpack full!", stack_top_position() - position + Vector2(0.0, -40.0 - bob))


func _draw_legs() -> void:
	for leg: float in [-1.0, 1.0]:
		var phase_offset := 0.0 if leg < 0.0 else PI
		var lift := maxf(sin(_walk_phase + phase_offset), 0.0) * 8.0 if is_walking() else 0.0
		draw_texture_rect(LEG_TEXTURE, Rect2(Vector2(leg * 13.0 - LEG_SIZE.x * 0.5, -67.0 - lift), LEG_SIZE), false)
	if not in_water:
		return
	# Knee-deep water over the lower legs, with a ring where the surface meets them.
	draw_rect(Rect2(-30.0, WATERLINE_Y, 60.0, -WATERLINE_Y + 2.0), WATER_TINT)
	draw_polyline(Iso.ellipse(Vector2(0.0, WATERLINE_Y), 32.0), Color(1.0, 1.0, 1.0, 0.7), 3.0, true)


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


## Pole from the hand to the hoop, the hoop as a ground circle, and the struggle meter.
func _draw_net(hoop: Vector2, side: float, bob: float) -> void:
	var shoulder := Vector2(NET_SHOULDER.x * side, NET_SHOULDER.y - bob)
	var hand := shoulder + shoulder.direction_to(hoop) * 38.0
	draw_line(hand, hoop, OUTLINE, 11.0, true)
	draw_line(hand, hoop, POLE, 6.0, true)
	draw_line(shoulder, hand, OUTLINE, 18.0)
	draw_line(shoulder, hand, JACKET, 11.0)
	draw_circle(hand, 9.0, OUTLINE)
	draw_circle(hand, 6.0, SKIN)

	var rim := Iso.ellipse(hoop, SCOOP_RADIUS, 28)
	draw_colored_polygon(rim, NET_FILL)
	for k in range(-2, 3):
		var offset := k * SCOOP_RADIUS * 0.35
		var half_chord := sqrt(SCOOP_RADIUS * SCOOP_RADIUS - offset * offset)
		draw_line(hoop + Iso.to_screen(Vector2(offset, -half_chord)), hoop + Iso.to_screen(Vector2(offset, half_chord)), NET_MESH, 1.5, true)
		draw_line(hoop + Iso.to_screen(Vector2(-half_chord, offset)), hoop + Iso.to_screen(Vector2(half_chord, offset)), NET_MESH, 1.5, true)
	draw_polyline(rim, OUTLINE, 9.0, true)
	draw_polyline(rim, HOOP_FULL if full else HOOP, 5.0, true)

	if struggle_progress > 0.0:
		var arc := Iso.ellipse_arc(hoop, SCOOP_RADIUS + 16.0, -PI * 0.5, -PI * 0.5 + TAU * struggle_progress, 28)
		draw_polyline(arc, OUTLINE, 12.0, true)
		draw_polyline(arc, PROGRESS, 7.0, true)


func _draw_label(text: String, at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var width := 320.0
	var origin := at - Vector2(width * 0.5, 0.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, 34, 10, OUTLINE)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, 34, HOOP_FULL)

#endregion
