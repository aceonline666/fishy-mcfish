class_name Customer
extends Node2D
## A buyer at the fish shop: walks up the beach to a place in the queue, waits, and walks off
## with a fish in a water bag once a seller has served them. Drawn from painted sprites
## (assets/sprites/props) in front or back view, depending on where they walk; most looks have a
## painted "leaving with a fish" version, the others get a bag drawn in their hand.

signal left

enum State { ARRIVING, WAITING, LEAVING }

## Three-quarter views: the front views look down towards screen-right, the back views up
## towards screen-right; they are mirrored when walking left.
const LOOKS: Array[String] = ["customer_2", "customer_3", "customer_4", "customer_5", "customer_6"]
## The same person carrying a fish, by look index.
const WITH_FISH: Dictionary[int, String] = {0: "buyer_1", 1: "buyer_3"}
const PROPS_DIR := "res://assets/sprites/props/"
## Ground units per second.
const SPEED := 150.0
const HEIGHT := 175.0
const ARRIVE_DISTANCE := 6.0
const BAG_WATER := Color(0.6, 0.85, 1.0, 0.75)
const BAG_FISH := Color(1.0, 0.55, 0.15)
const OUTLINE := Color(0.07, 0.09, 0.15)
const SHADOW := Color(0.0, 0.06, 0.14, 0.25)

var state := State.ARRIVING
var ground_position := Vector2.ZERO
var target := Vector2.ZERO
var has_fish := false

var _front: Texture2D
var _back: Texture2D
var _walking_away := false
var _mirrored := false
var _walk_phase := 0.0
var _exit := Vector2.ZERO
var _look := 0
## True while the sprite shows the bag; otherwise it is drawn.
var _painted_bag := false


func setup(look: int, start: Vector2, queue_spot: Vector2, exit: Vector2) -> void:
	_look = look % LOOKS.size()
	var name_prefix := PROPS_DIR + LOOKS[_look]
	_front = load(name_prefix + "_front.png")
	_back = load(name_prefix + "_back.png")
	ground_position = start
	target = queue_spot
	_exit = exit
	position = Iso.to_screen(start)


## Moves up to a new place in the queue.
func move_to(queue_spot: Vector2) -> void:
	target = queue_spot
	if state == State.WAITING:
		state = State.ARRIVING


## Served: takes the fish and walks off.
func serve() -> void:
	has_fish = true
	if WITH_FISH.has(_look):
		_front = load(PROPS_DIR + WITH_FISH[_look] + "_front.png")
		_back = load(PROPS_DIR + WITH_FISH[_look] + "_back.png")
		_painted_bag = true
	state = State.LEAVING
	target = _exit
	queue_redraw()


func is_waiting() -> bool:
	return state == State.WAITING


func _process(delta: float) -> void:
	var offset := target - ground_position
	if offset.length() <= ARRIVE_DISTANCE:
		if state == State.LEAVING:
			left.emit()
			queue_free()
			return
		state = State.WAITING
		_walk_phase = 0.0
		queue_redraw()
		return
	var step := offset.normalized() * minf(SPEED * delta, offset.length())
	ground_position += step
	position = Iso.to_screen(ground_position)
	var screen_step := Iso.to_screen(step)
	_walking_away = screen_step.y < 0.0
	_mirrored = screen_step.x < 0.0
	_walk_phase += delta * 9.0
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(Iso.ellipse(Vector2(0.0, 2.0), 26.0, 12), SHADOW)
	var texture := _back if _walking_away else _front
	var size := texture.get_size() * (HEIGHT / texture.get_height())
	var walking := state != State.WAITING
	var bob := absf(sin(_walk_phase)) * 5.0 if walking else 0.0
	var rect := Rect2(Vector2(-size.x * 0.5, -size.y), size)
	var base := Transform2D(0.0, Vector2(-1.0 if _mirrored else 1.0, 1.0), 0.0, Vector2.ZERO)
	WalkDraw.figure(self, base, texture, rect, _walk_phase, 1.0 if walking else 0.0, bob)
	draw_set_transform(Vector2.ZERO)
	if has_fish and not _painted_bag:
		_draw_bag(Vector2(size.x * (0.42 if not _mirrored else -0.42), -size.y * 0.42 - bob))


## A water bag with a fish, hanging from the hand.
func _draw_bag(at: Vector2) -> void:
	draw_line(at + Vector2(0.0, -16.0), at + Vector2(0.0, -8.0), OUTLINE, 2.5)
	draw_circle(at + Vector2(0.0, 6.0), 15.0, OUTLINE)
	draw_circle(at + Vector2(0.0, 6.0), 13.0, BAG_WATER)
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-7.0, 7.0), at + Vector2(0.0, 2.0), at + Vector2(6.0, 7.0), at + Vector2(0.0, 12.0),
	]), BAG_FISH)
	draw_colored_polygon(PackedVector2Array([at + Vector2(6.0, 7.0), at + Vector2(11.0, 3.0), at + Vector2(11.0, 11.0)]), BAG_FISH)
	draw_circle(at + Vector2(-3.0, 0.0), 2.5, Color(1.0, 1.0, 1.0, 0.8))
