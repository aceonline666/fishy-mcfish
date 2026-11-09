class_name DarkThings
extends Node2D
## Secrets of the deep: things lurking at the edge of the dark (assets/sprites/props, cut from
## art_source/props/dark_things_sheet.png by tools/extract_dark_things.py). They lie just above
## the seabed, below the fish, and nothing can catch them.
## - The deep sea horror: about every five minutes a huge creature glides slowly along the spot's
##   far (south) edge, out where no one can swim, barely visible in the dark; the submarine's
##   spotlight shows it. It does not wait for the wader: whoever is not there misses it.
## - Glowing eyes: in the dark of the last zones pairs of eyes open somewhere off in the water,
##   blink, and are gone as soon as the wader comes close or shines its light on them.
## Each is reported once it has been on screen (horror_seen, eyes_seen), for the secret goals.

## The horror passing now has come into view.
signal horror_seen
## A pair of eyes has opened fully in view.
signal eyes_seen

const HORROR: Texture2D = preload("res://assets/sprites/props/deep_horror.png")
const EYES: Array[Texture2D] = [
	preload("res://assets/sprites/props/eyes_1.png"), preload("res://assets/sprites/props/eyes_2.png"),
	preload("res://assets/sprites/props/eyes_3.png"), preload("res://assets/sprites/props/eyes_4.png"),
]
## Seconds from the start of one pass of the horror to the next, shortest and longest (also the
## first pass after the spot opens).
const HORROR_INTERVAL := Vector2(240.0, 360.0)
## Screen length of the horror and its speed (ground units per second). It swims along the far
## edge of the spot, this far beyond it (ground units, enough that its body stays clear of the
## walkable water), from beyond one side of the spot to beyond the other.
const HORROR_LENGTH := 820.0
const HORROR_SPEED := 85.0
const HORROR_BEYOND := Vector2(270.0, 330.0)
## How much of it shows in the dark, and in the spotlight.
const HORROR_DARK_ALPHA := 0.5
const HORROR_LIT_ALPHA := 0.95
## Its eye, teeth and lights shine through the dark: an additive copy at this strength.
const HORROR_SHINE := 0.45
## Eyes: how many pairs at most, where they open (ground distance from the wader), how close the
## wader may come before they vanish, how much spotlight they bear, and the seconds until a pair
## opens somewhere else.
const EYE_PAIRS := 2
const EYE_DISTANCE := Vector2(420.0, 750.0)
const EYE_SHY := 330.0
const EYE_SHY_LIGHT := 0.25
const EYE_WAIT := Vector2(50.0, 140.0)
const EYE_HEIGHT := 34.0
## The eyes show only where the deep sea is at least this dark (SeaDepth.abyss).
const EYE_MIN_DARK := 0.5

## Set by the scene: the wader, the far edge of the spot (ground y; INF: no horror), the ground
## rows of the zones with eyes, and the spotlight (Spotlight).
var wader_ground := Vector2.ZERO
var horror_edge := INF
var eye_rows := Vector2(INF, INF)
var spot_width := 2160.0
var light_origin := Vector2.ZERO
var light_dir := Vector2.RIGHT
var light_on := 0.0

var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _horror_wait := 0.0
## The horror passing now: its ground position and direction along the edge (+1 east, -1 west);
## none while _horror_dir is 0. Whether it has been reported as seen.
var _horror_at := Vector2.ZERO
var _horror_dir := 0.0
var _horror_reported := false
var _eyes: Array[Eyes] = []
## Draws the horror again additively, so only its bright parts (eye, teeth, lights) shine.
var _shine := Node2D.new()


func _ready() -> void:
	_shine.material = Glow.material()
	_shine.draw.connect(_draw_horror.bind(_shine, true))
	add_child(_shine)
	_rng.randomize()
	_horror_wait = _rng.randf_range(HORROR_INTERVAL.x, HORROR_INTERVAL.y)
	for i in EYE_PAIRS:
		var eyes := Eyes.new()
		eyes.wait = _rng.randf_range(10.0, EYE_WAIT.y)
		_eyes.append(eyes)


func _process(delta: float) -> void:
	_time += delta
	_update_horror(delta)
	for eyes in _eyes:
		_update_eyes(eyes, delta)
	queue_redraw()
	_shine.queue_redraw()


## Starts a pass of the horror right away along the far edge, from beyond one side of the spot;
## with `start`, that many ground units along the edge before the wader instead (screenshots).
func send_horror(start: float = NAN) -> void:
	if is_inf(horror_edge):
		return
	_horror_dir = 1.0 if _rng.randf() < 0.5 else -1.0
	var x := wader_ground.x - _horror_dir * start if not is_nan(start) 			else (-HORROR_LENGTH if _horror_dir > 0.0 else spot_width + HORROR_LENGTH)
	_horror_at = Vector2(x, horror_edge + _rng.randf_range(HORROR_BEYOND.x, HORROR_BEYOND.y))
	_horror_reported = false


## Whether a pass of the horror is under way.
func horror_passing() -> bool:
	return _horror_dir != 0.0


func _update_horror(delta: float) -> void:
	_horror_wait -= delta
	if _horror_wait <= 0.0:
		_horror_wait = _rng.randf_range(HORROR_INTERVAL.x, HORROR_INTERVAL.y)
		send_horror()
	if _horror_dir == 0.0:
		return
	_horror_at.x += _horror_dir * HORROR_SPEED * delta
	if not _horror_reported and _on_screen(Iso.to_screen(_horror_at)):
		_horror_reported = true
		horror_seen.emit()
	if (_horror_at.x - spot_width * 0.5) * _horror_dir > spot_width * 0.5 + HORROR_LENGTH:
		_horror_dir = 0.0


## Whether a point of this node (screen coordinates of the world) shows in the viewport.
func _on_screen(point: Vector2) -> bool:
	return is_inside_tree() and get_viewport_rect().has_point(get_global_transform_with_canvas() * point)


func _update_eyes(eyes: Eyes, delta: float) -> void:
	if eyes.shown:
		var lit := Spotlight.amount(eyes.ground, light_origin, light_dir, light_on)
		var shy := eyes.ground.distance_to(wader_ground) < EYE_SHY or lit > EYE_SHY_LIGHT or not _in_rows(wader_ground.y, eye_rows)
		eyes.alpha = move_toward(eyes.alpha, 0.0 if shy or eyes.closing else 1.0, delta * (4.0 if shy else 0.7))
		if shy:
			eyes.closing = true
		if eyes.closing and eyes.alpha <= 0.0:
			eyes.shown = false
			eyes.wait = _rng.randf_range(EYE_WAIT.x, EYE_WAIT.y)
		elif not eyes.reported and eyes.alpha >= 1.0 and _on_screen(Iso.to_screen(eyes.ground)):
			eyes.reported = true
			eyes_seen.emit()
		return
	eyes.wait -= delta
	if eyes.wait > 0.0 or not _in_rows(wader_ground.y, eye_rows):
		return
	var angle := _rng.randf() * TAU
	var ground := wader_ground + Vector2.from_angle(angle) * _rng.randf_range(EYE_DISTANCE.x, EYE_DISTANCE.y)
	ground.x = clampf(ground.x, 60.0, spot_width - 60.0)
	if not _in_rows(ground.y, eye_rows) or SeaDepth.abyss(ground.y) < EYE_MIN_DARK \
			or Spotlight.amount(ground, light_origin, light_dir, light_on) > 0.0:
		eyes.wait = 0.5
		return
	eyes.ground = ground
	eyes.texture = EYES[_rng.randi() % EYES.size()]
	eyes.shown = true
	eyes.closing = false
	eyes.alpha = 0.0
	eyes.reported = false
	eyes.blink_phase = _rng.randf() * 10.0
	# They look a while, then close and open somewhere else.
	eyes.stay = _rng.randf_range(6.0, 14.0)
	eyes.since = 0.0


## The horror on `canvas`: plain, or (`shine`) its additive copy.
func _draw_horror(canvas: CanvasItem, shine: bool) -> void:
	if _horror_dir == 0.0:
		return
	var lit := Spotlight.amount(_horror_at, light_origin, light_dir, light_on)
	var alpha := HORROR_SHINE * (1.0 - lit) if shine else lerpf(HORROR_DARK_ALPHA, HORROR_LIT_ALPHA, lit)
	var size := HORROR.get_size() * (HORROR_LENGTH / HORROR.get_width())
	var at := Iso.to_screen(_horror_at) + Vector2(0.0, sin(_time * 0.6) * 10.0)
	# The sprite faces east; mirrored when it swims west, and tilted to run along the edge
	# (diagonal on screen). A slow sway of the body.
	var heading := Iso.to_screen(Vector2(_horror_dir, 0.0))
	var flip := 1.0 if heading.x >= 0.0 else -1.0
	var angle := atan2(heading.y * flip, heading.x * flip)
	canvas.draw_set_transform(at, angle + sin(_time * 0.8) * 0.03, Vector2(flip, 1.0))
	canvas.draw_texture_rect(HORROR, Rect2(-size * 0.5, size), false, Color(1.0, 1.0, 1.0, alpha))
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw() -> void:
	_draw_horror(self, false)
	for eyes in _eyes:
		if not eyes.shown or eyes.alpha <= 0.0:
			continue
		eyes.since += get_process_delta_time()
		if eyes.since > eyes.stay:
			eyes.closing = true
		# A blink now and then: the eyes squeeze shut for a moment.
		var blink := fposmod(_time + eyes.blink_phase, 4.5)
		var open := 1.0 - (1.0 - smoothstep(0.0, 0.08, absf(blink - 0.1))) * 0.9
		var size := eyes.texture.get_size() * (EYE_HEIGHT / eyes.texture.get_height())
		var at := Iso.to_screen(eyes.ground)
		draw_texture_rect(eyes.texture, Rect2(at - Vector2(size.x * 0.5, size.y * 0.5 * open), Vector2(size.x, size.y * open)),
				false, Color(1.0, 1.0, 1.0, eyes.alpha))


static func _in_rows(y: float, rows: Vector2) -> bool:
	return y >= rows.x and y < rows.y


class Eyes extends RefCounted:
	var shown := false
	var closing := false
	var reported := false
	var ground := Vector2.ZERO
	var texture: Texture2D
	var alpha := 0.0
	var wait := 0.0
	var blink_phase := 0.0
	var stay := 0.0
	var since := 0.0
