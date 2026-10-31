class_name Drone
extends Node2D
## A fishing drone. Flies out over its zone, hovers above a fish it is allowed to take, lifts it
## into its net, and brings full loads back to the drone pad. A painted quadcopter with a net,
## high above its shadow. Game logic uses `ground_position`; the node sits at the shadow. While
## the tank has no room for what it could catch, it lands on the pad and rests.

signal delivered(drone: Drone, species_ids: Array[String])

enum Task { FLY_OUT, HUNT, LIFT, RETURN, REST }

const SPEED := 260.0
## Screen height above the water.
const HEIGHT := 170.0
const PICKUP_RADIUS := 35.0
## Seconds to lift a fish, per second of struggle it would put up in a hand net.
const LIFT_PER_STRUGGLE := 1.5
const MIN_LIFT_S := 0.5
const ICON_LENGTH := 34.0
## How fast it sinks to the ground to rest, and climbs back, in share of its height per second.
const LAND_SPEED := 1.5
## Resting drones sit side by side on the pad, this far apart.
const REST_SPACING := 70.0

## Painted drones (assets/sprites/props), one look per drone in order of purchase.
const TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/drone_1.png"), preload("res://assets/sprites/props/drone_2.png"),
	preload("res://assets/sprites/props/drone_3.png"), preload("res://assets/sprites/props/drone_4.png"),
	preload("res://assets/sprites/props/drone_5.png"), preload("res://assets/sprites/props/drone_6.png"),
]
## Screen height of the sprite before the drone's size is applied, and how far below the body
## the net with the catch hangs.
const SPRITE_HEIGHT := 120.0
const NET_DROP := 45.0
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)

var ground_position := Vector2.ZERO
var zone: ZoneDef
var capacity := 3
var cargo: Array[FishArt] = []
var task := Task.FLY_OUT
## The fish it is going for, or lifting.
var target: SwimmingFish

var _pad := Vector2.ZERO
## Where it lands, beside the other drones.
var _rest := Vector2.ZERO
## 1 in the air, 0 on the ground.
var _height := 1.0
var _area: PlayArea
var _waypoint := Vector2.ZERO
var _lift_left := 0.0
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _texture: Texture2D = TEXTURES[0]


## `size` scales the drawing: later drones are bigger. `look` picks the sprite.
func setup(pad: Vector2, home_zone: ZoneDef, zone_area: PlayArea, carry: int, size: float = 1.0, look: int = 0) -> void:
	scale = Vector2.ONE * size
	_texture = TEXTURES[clampi(look, 0, TEXTURES.size() - 1)]
	_pad = pad
	_rest = pad + Vector2((look % 3 - 1) * REST_SPACING, (look / 3) * REST_SPACING * 0.5)
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
	return position + Vector2(0.0, -HEIGHT * _height + NET_DROP) * scale.y


## Moves one step. `fish` holds all swimming fish; `can_take` says if a species may be taken.
## `can_take` also says no while the tank has no room for that species, and `tank_full` (given
## the drone's zone) says if the tank has room for nothing it could catch: it then delivers what
## it carries and rests on the pad until there is room again.
## Returns a fish the drone just lifted (the caller removes it from the water), else null.
func simulate(delta: float, fish: Array[SwimmingFish], can_take: Callable, tank_full: Callable) -> SwimmingFish:
	_time += delta
	var lifted: SwimmingFish = null
	if (task == Task.FLY_OUT or task == Task.HUNT) and target == null and tank_full.call(zone):
		task = Task.RETURN if not cargo.is_empty() else Task.REST
	match task:
		Task.FLY_OUT:
			if _fly_to(_waypoint, delta):
				task = Task.HUNT
		Task.HUNT:
			if target != null and is_instance_valid(target) and not can_take.call(target.species.id):
				target = null
			if target == null or not is_instance_valid(target) or target.state != SwimmingFish.State.SWIMMING:
				target = _pick_target(fish, can_take)
			if target == null:
				if _fly_to(_waypoint, delta):
					_waypoint = _area.random_point(_rng, 80.0)
			elif _fly_to(target.ground_position, delta, PICKUP_RADIUS):
				task = Task.LIFT
				_lift_left = maxf(CatchRules.struggle_seconds(target.species) * LIFT_PER_STRUGGLE, MIN_LIFT_S)
		Task.LIFT:
			if target == null or not is_instance_valid(target) or target.state != SwimmingFish.State.SWIMMING 					or not can_take.call(target.species.id):
				target = null
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
		Task.REST:
			if _fly_to(_rest, delta):
				ground_position = _rest
				if not tank_full.call(zone):
					_start_trip()
	var landed := task == Task.REST and ground_position == _rest
	_height = move_toward(_height, 0.0 if landed else 1.0, LAND_SPEED * delta)
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
	var bob := sin(_time * 3.0) * 4.0 * _height
	var body := Vector2(0.0, -HEIGHT * _height + bob)
	var size := _texture.get_size() * (SPRITE_HEIGHT / _texture.get_height())
	draw_texture_rect(_texture, Rect2(body + Vector2(-size.x * 0.5, -SPRITE_HEIGHT * 0.4), size), false)
	# The catch in the net, and a line down to the fish being lifted.
	var net := body + Vector2(0.0, NET_DROP)
	if task == Task.LIFT:
		draw_line(net, Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.6), 2.0, true)
	for i in cargo.size():
		var view := Transform2D(Vector2(1.0 if i % 2 == 0 else -1.0, 0.0), Vector2(0.0, 1.0), net + Vector2(0.0, 6.0 - i * 9.0))
		cargo[i].draw(self, view, ICON_LENGTH)
