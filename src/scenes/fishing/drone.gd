class_name Drone
extends Node2D
## A fishing drone. Flies out over its zone, hovers above a fish it is allowed to take, lifts it
## into its net, and brings full loads back to the drone pad. Drawn in code: a little quadcopter
## high above its shadow. Game logic uses `ground_position`; the node sits at the shadow.

signal delivered(drone: Drone, species_ids: Array[String])

enum Task { FLY_OUT, HUNT, LIFT, RETURN }

const SPEED := 260.0
## Screen height above the water.
const HEIGHT := 170.0
const PICKUP_RADIUS := 35.0
## Seconds to lift a fish, per second of struggle it would put up in a hand net.
const LIFT_PER_STRUGGLE := 1.5
const MIN_LIFT_S := 0.5
const ICON_LENGTH := 34.0

const OUTLINE := Color(0.07, 0.09, 0.15)
const BODY := Color(1.0, 0.78, 0.2)
const BODY_DARK := Color(0.85, 0.55, 0.1)
const ROTOR := Color(0.85, 0.92, 1.0, 0.55)
const LIGHT := Color(0.4, 1.0, 0.5)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)

var ground_position := Vector2.ZERO
var zone: ZoneDef
var capacity := 3
var cargo: Array[FishArt] = []
var task := Task.FLY_OUT
## The fish it is going for, or lifting.
var target: SwimmingFish

var _pad := Vector2.ZERO
var _area: PlayArea
var _waypoint := Vector2.ZERO
var _lift_left := 0.0
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func setup(pad: Vector2, home_zone: ZoneDef, zone_area: PlayArea, carry: int) -> void:
	_pad = pad
	zone = home_zone
	_area = zone_area
	capacity = carry
	ground_position = pad
	position = Iso.to_screen(pad)
	_rng.randomize()
	_time = _rng.randf() * 10.0
	_start_trip()


## Screen point of the net below the drone, relative to the parent.
func net_position() -> Vector2:
	return position + Vector2(0.0, -HEIGHT + 46.0)


## Moves one step. `fish` holds all swimming fish; `can_take` says if a species may be taken.
## Returns a fish the drone just lifted (the caller removes it from the water), else null.
func simulate(delta: float, fish: Array[SwimmingFish], can_take: Callable) -> SwimmingFish:
	_time += delta
	var lifted: SwimmingFish = null
	match task:
		Task.FLY_OUT:
			if _fly_to(_waypoint, delta):
				task = Task.HUNT
		Task.HUNT:
			if target == null or not is_instance_valid(target) or target.state != SwimmingFish.State.SWIMMING:
				target = _pick_target(fish, can_take)
			if target == null:
				if _fly_to(_waypoint, delta):
					_waypoint = _area.random_point(_rng, 80.0)
			elif _fly_to(target.ground_position, delta, PICKUP_RADIUS):
				task = Task.LIFT
				_lift_left = maxf(CatchRules.struggle_seconds(target.species) * LIFT_PER_STRUGGLE, MIN_LIFT_S)
		Task.LIFT:
			if target == null or not is_instance_valid(target) or target.state != SwimmingFish.State.SWIMMING:
				task = Task.HUNT
			else:
				# Hover over the fish while it wriggles.
				ground_position = ground_position.lerp(target.ground_position, minf(delta * 6.0, 1.0))
				_lift_left -= delta
				if _lift_left <= 0.0:
					lifted = target
					cargo.append(target.art)
					target = null
					task = Task.RETURN if cargo.size() >= capacity else Task.HUNT
		Task.RETURN:
			if _fly_to(_pad, delta):
				var ids: Array[String] = []
				for art in cargo:
					ids.append(art.species.id)
				cargo.clear()
				delivered.emit(self, ids)
				_start_trip()
	position = Iso.to_screen(ground_position)
	queue_redraw()
	return lifted


func _start_trip() -> void:
	task = Task.FLY_OUT
	_waypoint = _area.random_point(_rng, 80.0)


## Flies towards a point; returns true once within `radius`.
func _fly_to(point: Vector2, delta: float, radius: float = 8.0) -> bool:
	var offset := point - ground_position
	if offset.length() <= radius:
		return true
	ground_position += offset.limit_length(SPEED * delta)
	return offset.length() <= radius + SPEED * delta


## The nearest fish in its zone it may take, or null.
func _pick_target(fish: Array[SwimmingFish], can_take: Callable) -> SwimmingFish:
	var best: SwimmingFish = null
	var best_distance := INF
	for candidate in fish:
		if candidate.zone != zone or not can_take.call(candidate.species.id):
			continue
		var distance := candidate.ground_position.distance_squared_to(ground_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _draw() -> void:
	draw_colored_polygon(Iso.ellipse(Vector2.ZERO, 34.0, 16), SHADOW)
	var bob := sin(_time * 3.0) * 4.0
	var body := Vector2(0.0, -HEIGHT + bob)

	# Net hanging below, with the catch in it.
	var net := body + Vector2(0.0, 46.0)
	draw_line(body + Vector2(0.0, 12.0), net, OUTLINE, 3.0, true)
	if task == Task.LIFT:
		draw_line(net, Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.6), 2.0, true)
	for i in cargo.size():
		var view := Transform2D(Vector2(1.0 if i % 2 == 0 else -1.0, 0.0), Vector2(0.0, 1.0), net + Vector2(0.0, 6.0 - i * 9.0))
		cargo[i].draw(self, view, ICON_LENGTH)
	draw_colored_polygon(Iso.ellipse(net + Vector2(0.0, 10.0), 22.0, 14), Color(1.0, 1.0, 1.0, 0.25))
	draw_polyline(Iso.ellipse(net + Vector2(0.0, 10.0), 22.0, 14), OUTLINE, 3.0, true)

	# Arms and spinning rotors.
	for corner: Vector2 in [Vector2(-40.0, -8.0), Vector2(40.0, -8.0), Vector2(-28.0, 6.0), Vector2(28.0, 6.0)]:
		var hub := body + corner
		draw_line(body, hub, OUTLINE, 9.0, true)
		draw_line(body, hub, BODY_DARK, 5.0, true)
		var blade := 22.0 * absf(cos(_time * 40.0 + corner.x))
		draw_colored_polygon(Iso.ellipse(hub + Vector2(0.0, -8.0), maxf(blade, 6.0), 12), ROTOR)
		draw_circle(hub + Vector2(0.0, -6.0), 4.0, OUTLINE)

	var shell := PackedVector2Array([
		body + Vector2(-24.0, -14.0), body + Vector2(24.0, -14.0), body + Vector2(28.0, 6.0),
		body + Vector2(18.0, 14.0), body + Vector2(-18.0, 14.0), body + Vector2(-28.0, 6.0),
	])
	IsoDraw.fill_outlined(self, shell, BODY, 3.5)
	draw_circle(body + Vector2(10.0, -2.0), 7.0, OUTLINE)
	draw_circle(body + Vector2(10.0, -2.0), 5.0, Color(0.6, 0.85, 1.0))
	draw_circle(body + Vector2(-14.0, -6.0), 3.0, LIGHT if fmod(_time, 1.0) < 0.5 else BODY_DARK)
