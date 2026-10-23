class_name SwimmingFish
extends Node2D
## A fish in the fishing scene. Steers itself in ground coordinates (wander, schooling, fleeing
## the wader) and draws itself side-on: from SVG sprites (FishArt) where they exist, otherwise
## with chunky placeholder shapes drawn in code.

enum State { SWIMMING, CAUGHT }

const OUTLINE_COLOR := Color(0.07, 0.09, 0.15)
const OUTLINE_WIDTH := 3.0
const SHADOW_COLOR := Color(0.0, 0.06, 0.14, 0.22)
## How far below the fish its shadow falls on the seabed, in screen pixels.
const SHADOW_DROP := 24.0
const SPARKLE_COLOR := Color(1.0, 0.95, 0.55, 0.9)
const BODY_SEGMENTS := 10
const BODY_SHARE := FishArt.BODY_SHARE
## Steepest on-screen tilt of the side-on drawing, in radians.
const MAX_TILT := 0.6
## Length factor when swimming straight towards or away from the camera.
const MIN_FORESHORTEN := 0.55

const TURN_RATE := 2.5
const WANDER_JITTER := 3.0
const WANDER_ANGLE := 0.6
const EDGE_MARGIN := 90.0
const SCHOOL_RADIUS := 200.0
const FLEE_SECONDS := 0.45
const FLEE_SPEED_MULT := 1.5
## A fish in the net is tangled: it wriggles hard but moves slowly, so holding on is doable.
const HELD_SPEED_MULT := 0.5
const HELD_WIGGLE_MULT := 3.0

var species: SpeciesDef
var art: FishArt
## The depth zone the fish lives in, and the water it keeps to.
var zone: ZoneDef
var area: PlayArea
var state := State.SWIMMING
var ground_position := Vector2.ZERO
## Ground units per second.
var velocity := Vector2.ZERO
## Swimming direction as a ground angle.
var heading := 0.0
## Seconds the net has been on this fish; it is caught at CatchRules.struggle_seconds().
var hold_time := 0.0
var body_length := 0.0
## Side-on body depth.
var body_height := 0.0

var _cruise_speed := 0.0
var _wander := 0.0
var _swim_phase := 0.0
var _flee_timer := 0.0
var _flee_direction := Vector2.ZERO
var _age := 0.0


func setup(fish_art: FishArt, home_zone: ZoneDef, home_area: PlayArea, start: Vector2, start_heading: float) -> void:
	art = fish_art
	zone = home_zone
	area = home_area
	species = fish_art.species
	var def := species
	ground_position = start
	heading = start_heading
	position = Iso.to_screen(start)
	body_length = CatchRules.body_length(def)
	body_height = body_length * def.body_aspect
	_cruise_speed = CatchRules.cruise_speed(def)
	velocity = Vector2.from_angle(heading) * _cruise_speed
	_swim_phase = randf() * TAU
	_wander = randf_range(-1.0, 1.0)


func is_held() -> bool:
	return hold_time > 0.0


## How far outside the scoop circle the fish can be and still be caught.
func catch_radius() -> float:
	return body_length * 0.2


## Moves the fish one step, keeping to its home area. Fish flee from `threat` (the wader)
## within `threat_radius`. `school` holds all swimming fish; only nearby fish of the same
## species matter.
func simulate(delta: float, threat: Vector2, threat_radius: float, school: Array[SwimmingFish]) -> void:
	_age += delta
	_wander = clampf(_wander + randf_range(-1.0, 1.0) * WANDER_JITTER * delta, -1.0, 1.0)
	var steer := Vector2.from_angle(heading).rotated(_wander * WANDER_ANGLE)
	if not area.contains(ground_position, EDGE_MARGIN):
		steer += ground_position.direction_to(area.center()) * 2.0
	if species.length_cm < CatchRules.SCHOOLING_BELOW_CM:
		steer += _schooling(school)

	var speed := _cruise_speed
	var away_from_threat := threat.direction_to(ground_position)
	if is_held():
		steer += away_from_threat * 3.0
		speed *= HELD_SPEED_MULT
	else:
		if ground_position.distance_to(threat) < threat_radius:
			_flee_timer = FLEE_SECONDS
			_flee_direction = away_from_threat
		if _flee_timer > 0.0:
			_flee_timer -= delta
			steer += _flee_direction * 2.5
			speed *= FLEE_SPEED_MULT

	velocity = velocity.lerp(steer.normalized() * speed, clampf(TURN_RATE * delta, 0.0, 1.0))
	ground_position += velocity * delta
	if velocity.length_squared() > 1.0:
		heading = velocity.angle()
	position = Iso.to_screen(ground_position)
	var wiggle := HELD_WIGGLE_MULT if is_held() else 1.0
	_swim_phase += delta * (5.0 + velocity.length() / 30.0) * wiggle
	queue_redraw()


## Shrinks the fish into the net at the given screen position, then frees it.
func play_caught(target: Vector2) -> void:
	state = State.CAUGHT
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", target, 0.16).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ONE * 0.35, 0.16)
	tween.tween_property(self, "modulate:a", 0.0, 0.16).set_delay(0.06)
	tween.chain().tween_callback(queue_free)


func _schooling(school: Array[SwimmingFish]) -> Vector2:
	var center := Vector2.ZERO
	var direction := Vector2.ZERO
	var separation := Vector2.ZERO
	var count := 0
	var personal_space := body_length * 1.3
	for other in school:
		if other == self or other.species != species:
			continue
		var offset := other.ground_position - ground_position
		var distance := offset.length()
		if distance > SCHOOL_RADIUS or distance < 0.001:
			continue
		count += 1
		center += other.ground_position
		direction += other.velocity
		if distance < personal_space:
			separation -= offset / distance * (1.0 - distance / personal_space)
	if count == 0:
		return Vector2.ZERO
	center /= count
	return ground_position.direction_to(center) * 0.4 + direction.normalized() * 0.6 + separation * 1.5


#region Drawing
# Fish are drawn side-on, like isometric sprites: back up, mirrored when swimming left, tilted
# a little with the on-screen direction and shortened when swimming towards or away from the
# camera. Shapes are built in fish space (head towards +x, back towards -y).

func _draw() -> void:
	var to_screen := _view_transform()
	draw_colored_polygon(Iso.ellipse(Vector2(0.0, SHADOW_DROP), body_length * 0.36, 16), SHADOW_COLOR)
	if art.has_sprite():
		art.draw(self, to_screen, body_length, 0.75 + 0.25 * sin(_swim_phase))
	else:
		_draw_shapes(to_screen)
	if species.rarity >= SpeciesDef.Rarity.UNCOMMON:
		_draw_sparkles()


## Code-drawn fallback for species without sprites.
func _draw_shapes(to_screen: Transform2D) -> void:
	var color := species.placeholder_color
	_fill_outlined(to_screen * _tail_polygon(), color.darkened(0.1))
	_fill_outlined(to_screen * _dorsal_fin_polygon(), color.darkened(0.15))
	var body := to_screen * _body_polygon()
	draw_colored_polygon(body, color)
	# Countershading: a lighter belly.
	draw_colored_polygon(to_screen * _belly_polygon(), color.lightened(0.35))
	_outline(body)
	_fill_outlined(to_screen * _pectoral_fin_polygon(), color.darkened(0.2))
	_draw_face(to_screen)


## Maps fish space to screen space for the current swimming direction.
func _view_transform() -> Transform2D:
	var screen_direction := Iso.to_screen(Vector2.from_angle(heading)).normalized()
	var facing_right := Vector2(absf(screen_direction.x), screen_direction.y)
	var tilt := clampf(facing_right.angle(), -MAX_TILT, MAX_TILT)
	if is_held():
		tilt += sin(_swim_phase * 2.0) * 0.2
	var foreshorten := lerpf(MIN_FORESHORTEN, 1.0, facing_right.x)
	var view := Transform2D(tilt, Vector2.ZERO) * Transform2D(Vector2(foreshorten, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	if screen_direction.x < 0.0:
		view = Transform2D(Vector2(-1.0, 0.0), Vector2(0.0, 1.0), Vector2.ZERO) * view
	return view


func _fill_outlined(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	_outline(points)


func _outline(points: PackedVector2Array) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE_COLOR, OUTLINE_WIDTH, true)


## Body depth at t (0 = snout, 1 = tail root), 0..1: blunt head, deep belly, narrow tail root.
func _profile(t: float) -> float:
	return maxf(pow(maxf(sin(PI * (0.16 + 0.84 * pow(t, 0.85))), 0.0), 0.55), 0.22)


func _x_at(t: float) -> float:
	return lerpf(body_length * 0.5, body_length * (0.5 - BODY_SHARE), t)


func _back_y(t: float) -> float:
	return -body_height * 0.46 * _profile(t)


func _belly_y(t: float) -> float:
	return body_height * 0.54 * _profile(t)


func _body_polygon() -> PackedVector2Array:
	var back := PackedVector2Array()
	var belly := PackedVector2Array()
	for i in BODY_SEGMENTS + 1:
		var t := float(i) / BODY_SEGMENTS
		back.append(Vector2(_x_at(t), _back_y(t)))
		belly.append(Vector2(_x_at(t), _belly_y(t)))
	belly.reverse()
	var polygon := back
	polygon.append_array(belly)
	# Rounded snout, from the chin around the front to the forehead.
	var top := _back_y(0.0)
	var bottom := _belly_y(0.0)
	var center := Vector2(_x_at(0.0), (top + bottom) * 0.5)
	var radius := Vector2(body_height * 0.22, (bottom - top) * 0.5)
	for k in range(1, 6):
		var angle := PI * 0.5 - PI * k / 6.0
		polygon.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return polygon


func _belly_polygon() -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for i in range(1, BODY_SEGMENTS):
		var t := float(i) / BODY_SEGMENTS
		polygon.append(Vector2(_x_at(t), body_height * 0.12 * _profile(t)))
	for i in range(BODY_SEGMENTS - 1, 0, -1):
		var t := float(i) / BODY_SEGMENTS
		polygon.append(Vector2(_x_at(t), _belly_y(t) * 0.92))
	return polygon


## Forked tail. Its length and spread pulse with the tail beat, which reads as the tail
## sweeping towards and away from the camera.
func _tail_polygon() -> PackedVector2Array:
	var root_x := _x_at(1.0)
	var beat := sin(_swim_phase)
	var tail_length := body_length * (1.0 - BODY_SHARE) * (0.75 + 0.25 * beat)
	var spread := body_height * 0.55 * (1.0 - 0.15 * beat)
	var root_half := body_height * 0.12
	return PackedVector2Array([
		Vector2(root_x + 2.0, -root_half),
		Vector2(root_x - tail_length, -spread),
		Vector2(root_x - tail_length * 0.55, 0.0),
		Vector2(root_x - tail_length, spread),
		Vector2(root_x + 2.0, root_half),
	])


func _dorsal_fin_polygon() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(_x_at(0.3), _back_y(0.3) + 3.0),
		Vector2(_x_at(0.58), _back_y(0.45) - body_height * 0.32),
		Vector2(_x_at(0.66), _back_y(0.66) + 3.0),
	])


func _pectoral_fin_polygon() -> PackedVector2Array:
	var root := Vector2(_x_at(0.24), body_height * 0.1)
	var flap := sin(_swim_phase * 1.3) * 0.4
	var reach := body_height * 0.42
	return PackedVector2Array([
		root + Vector2(reach * 0.15, -reach * 0.15),
		root + Vector2(-reach, reach * 0.35).rotated(flap),
		root + Vector2(-reach * 0.2, reach * 0.3),
	])


## A big comic eye and a gill line.
func _draw_face(to_screen: Transform2D) -> void:
	var eye_center := Vector2(_x_at(0.0) - body_height * 0.3, -body_height * 0.08)
	var radius := clampf(body_height * 0.17, 3.5, 11.0)
	var eye := to_screen * eye_center
	var forward := to_screen.basis_xform(Vector2.RIGHT).normalized()
	draw_circle(eye, radius + 1.5, OUTLINE_COLOR)
	draw_circle(eye, radius, Color.WHITE)
	draw_circle(eye + forward * radius * 0.3, radius * 0.55, OUTLINE_COLOR)

	var gill := PackedVector2Array()
	var gill_center := eye_center + Vector2(-body_height * 0.05, body_height * 0.05)
	for k in 5:
		var angle := lerpf(-0.9, 0.9, k / 4.0)
		gill.append(gill_center + Vector2(-cos(angle), sin(angle)) * body_height * 0.32)
	draw_polyline(to_screen * gill, OUTLINE_COLOR.lerp(species.placeholder_color, 0.4), 2.0, true)


## Twinkling stars orbiting fish that are not common.
func _draw_sparkles() -> void:
	for k in 3:
		var angle := _age * 1.7 + k * TAU / 3.0
		var orbit := body_length * 0.5 + 16.0
		var at := Vector2(cos(angle) * orbit, sin(angle) * orbit * 0.5 - 10.0)
		var size := 7.0 + 4.0 * sin(_age * 6.0 + k * 2.0)
		var star := PackedVector2Array()
		for j in 8:
			star.append(at + Vector2.from_angle(j * PI / 4.0) * (size if j % 2 == 0 else size * 0.35))
		draw_colored_polygon(star, SPARKLE_COLOR)

#endregion
