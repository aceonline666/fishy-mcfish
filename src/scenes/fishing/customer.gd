class_name Customer
extends Node2D
## A buyer at the fish shop: walks to a place in the queue, waits, and walks off with a fish in
## a water bag once served at a booth. Drawn from painted sprites (assets/sprites/buyers, cut by
## tools/import_buyers.py from art_source/characters/buyer_sheet_N.png) in front or back view,
## depending on where they walk, each also painted leaving with the fish.

signal left

enum State { ARRIVING, WAITING, LEAVING }

## Three-quarter views: the front views look down towards screen-right, the back views up
## towards screen-right; they are mirrored when walking left.
const LOOKS: Array[String] = ["buyer_1", "buyer_2", "buyer_3"]
## Per look, for the walk (WalkDraw): the share of the height above the hips (the hem of the dress
## or shorts) and the legs' half width as a share of the height.
const HIPS: Array[float] = [0.76, 0.8, 0.74]
const LEGS: Array[float] = [0.15, 0.2, 0.15]
const BUYERS_DIR := "res://assets/sprites/buyers/"
## Ground units per second.
const SPEED := 150.0
## Screen height of the figures, a little smaller than the wader and the sellers.
const HEIGHT := 200.0
const ARRIVE_DISTANCE := 6.0
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


func setup(look: int, start: Vector2, queue_spot: Vector2, exit: Vector2) -> void:
	_look = look % LOOKS.size()
	_load_sprites("")
	ground_position = start
	target = queue_spot
	_exit = exit
	position = Iso.to_screen(start)


## Moves up to a new place in the queue.
func move_to(queue_spot: Vector2) -> void:
	target = queue_spot
	if state == State.WAITING:
		state = State.ARRIVING


## Served: takes the fish and walks off, to `exit` if given.
func serve(exit: Vector2 = Vector2.INF) -> void:
	if exit != Vector2.INF:
		_exit = exit
	has_fish = true
	_load_sprites("_fish")
	state = State.LEAVING
	target = _exit
	queue_redraw()


## The front and back views, `suffix` "_fish" for the ones carrying the fish.
func _load_sprites(suffix: String) -> void:
	_front = load(BUYERS_DIR + LOOKS[_look] + "_front" + suffix + ".png")
	_back = load(BUYERS_DIR + LOOKS[_look] + "_back" + suffix + ".png")


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
	WalkDraw.figure(self, base, texture, rect, _walk_phase, 1.0 if walking else 0.0, bob, HIPS[_look], LEGS[_look])
	draw_set_transform(Vector2.ZERO)
