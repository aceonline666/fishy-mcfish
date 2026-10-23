class_name Visitor
extends Node2D
## A beach visitor. Walks along ground waypoints: pays at the ticket booth, admires a tank,
## then leaves. Drawn in code with random clothes until sprites arrive.

signal arrived(visitor: Visitor, waypoint: int)

const SPEED := 150.0
const LOOK_SECONDS := 1.8
const PAY_SECONDS := 0.5
const OUTLINE := Color(0.07, 0.09, 0.15)
const SHIRTS: Array[Color] = [
	Color(0.95, 0.4, 0.45), Color(0.4, 0.7, 0.95), Color(0.55, 0.85, 0.45), Color(0.95, 0.65, 0.3), Color(0.75, 0.5, 0.9),
]
const SKINS: Array[Color] = [Color(1.0, 0.82, 0.66), Color(0.85, 0.62, 0.45), Color(0.6, 0.42, 0.3), Color(0.98, 0.75, 0.6)]
const HAIRS: Array[Color] = [Color(0.25, 0.17, 0.1), Color(0.9, 0.75, 0.35), Color(0.55, 0.3, 0.15), Color(0.15, 0.15, 0.18)]
const SHADOW := Color(0.0, 0.06, 0.14, 0.25)
const HEART := Color(1.0, 0.35, 0.45)

var ground_position := Vector2.ZERO
## Coins this visitor brings to the booth.
var amount := 0.0
var pay_at := -1
var look_at_index := -1

var _path: Array[Vector2] = []
var _next := 0
var _wait := 0.0
var _heart := 0.0
var _walk_phase := 0.0
var _velocity := Vector2.ZERO
var _shirt: Color
var _skin: Color
var _hair: Color
var _hat := false


func setup(path: Array[Vector2], pays_at: int, looks_at: int, coins: float, rng: RandomNumberGenerator) -> void:
	_path = path
	pay_at = pays_at
	look_at_index = looks_at
	amount = coins
	ground_position = path[0]
	position = Iso.to_screen(ground_position)
	_next = 1
	_shirt = SHIRTS[rng.randi() % SHIRTS.size()]
	_skin = SKINS[rng.randi() % SKINS.size()]
	_hair = HAIRS[rng.randi() % HAIRS.size()]
	_hat = rng.randf() < 0.35


## Moves one step. Returns false once the visitor has left (and freed itself).
func simulate(delta: float) -> bool:
	_heart = maxf(_heart - delta, 0.0)
	if _wait > 0.0:
		_wait -= delta
		_velocity = Vector2.ZERO
		queue_redraw()
		return true
	if _next >= _path.size():
		queue_free()
		return false
	var target := _path[_next]
	var to_target := target - ground_position
	var step := SPEED * delta
	if to_target.length() <= step:
		ground_position = target
		arrived.emit(self, _next)
		if _next == look_at_index:
			_wait = LOOK_SECONDS
			_heart = LOOK_SECONDS
		elif _next == pay_at:
			_wait = PAY_SECONDS
		_next += 1
	else:
		_velocity = to_target.normalized() * SPEED
		ground_position += _velocity * delta
		_walk_phase += delta * 9.0
	position = Iso.to_screen(ground_position)
	queue_redraw()
	return true


func _draw() -> void:
	var screen_velocity := Iso.to_screen(_velocity)
	var side := -1.0 if screen_velocity.x < 0.0 else 1.0
	var from_behind := screen_velocity.y < -1.0
	var walking := _velocity.length_squared() > 1.0
	var bob := absf(sin(_walk_phase)) * 4.0 if walking else 0.0

	draw_colored_polygon(Iso.ellipse(Vector2.ZERO, 24.0), SHADOW)
	for leg: float in [-1.0, 1.0]:
		var lift := maxf(sin(_walk_phase + (0.0 if leg < 0.0 else PI)), 0.0) * 6.0 if walking else 0.0
		draw_line(Vector2(leg * 9.0, -50.0), Vector2(leg * 9.0, -lift), OUTLINE, 15.0)
		draw_line(Vector2(leg * 9.0, -50.0), Vector2(leg * 9.0, -lift - 2.0), Color(0.3, 0.32, 0.45), 9.0)

	var up := Vector2(0.0, -bob)
	IsoDraw.fill_outlined(self, Transform2D(0.0, up) * PackedVector2Array([
		Vector2(-20.0, -100.0), Vector2(20.0, -100.0), Vector2(26.0, -50.0), Vector2(-26.0, -50.0),
	]), _shirt, 3.5)
	for arm: float in [-1.0, 1.0]:
		var swing := sin(_walk_phase + (PI if arm < 0.0 else 0.0)) * 6.0 if walking else 0.0
		var shoulder := Vector2(arm * 20.0, -94.0) + up
		var hand := shoulder + Vector2(arm * 6.0 + swing, 36.0)
		draw_line(shoulder, hand, OUTLINE, 13.0)
		draw_line(shoulder, hand, _shirt.darkened(0.1), 8.0)
		draw_circle(hand, 6.0, OUTLINE)
		draw_circle(hand, 4.0, _skin)

	var head := Vector2(0.0, -122.0) + up
	draw_circle(head, 21.0, OUTLINE)
	draw_circle(head, 18.0, _skin)
	if from_behind:
		draw_circle(head + Vector2(0.0, -2.0), 17.0, _hair)
	else:
		var hair := PackedVector2Array()
		for i in 9:
			hair.append(head + Vector2.from_angle(PI + PI * i / 8.0) * 19.0)
		draw_colored_polygon(hair, _hair)
		for eye: float in [-1.0, 1.0]:
			draw_circle(head + Vector2(eye * 6.0 + side * 3.0, 3.0), 2.6, OUTLINE)
		draw_arc(head + Vector2(side * 3.0, 9.0), 5.0, 0.4, PI - 0.4, 8, OUTLINE, 2.0, true)
	if _hat:
		draw_colored_polygon(Iso.ellipse(head + Vector2(0.0, -12.0), 32.0, 16), Color(0.95, 0.85, 0.55))
		draw_polyline(Iso.ellipse(head + Vector2(0.0, -12.0), 32.0, 16), OUTLINE, 2.5, true)
		draw_circle(head + Vector2(0.0, -18.0), 13.0, Color(0.95, 0.85, 0.55))

	if _heart > 0.0:
		_draw_heart(head + Vector2(0.0, -46.0 - (LOOK_SECONDS - _heart) * 10.0), 11.0)


func _draw_heart(at: Vector2, size: float) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		points.append(at + Vector2(16.0 * pow(sin(t), 3.0),
				-(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * size / 16.0)
	IsoDraw.fill_outlined(self, points, HEART, 2.5)
