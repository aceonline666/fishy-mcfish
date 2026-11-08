class_name DarkThings
extends Node2D
## Secrets of the deep: things lurking at the edge of the dark (assets/sprites/props, cut from
## art_source/props/dark_things_sheet.png by tools/extract_dark_things.py). They lie just above
## the seabed, below the fish, and nothing can catch them.
## - The deep sea horror: now and then, while the wader is in the last zone, a huge creature
##   glides slowly past far off, barely visible in the dark; the submarine's spotlight shows it.
## - Glowing eyes: in the dark of the last zones pairs of eyes open somewhere off in the water,
##   blink, and are gone as soon as the wader comes close or shines its light on them.

const HORROR: Texture2D = preload("res://assets/sprites/props/deep_horror.png")
const EYES: Array[Texture2D] = [
	preload("res://assets/sprites/props/eyes_1.png"), preload("res://assets/sprites/props/eyes_2.png"),
	preload("res://assets/sprites/props/eyes_3.png"), preload("res://assets/sprites/props/eyes_4.png"),
]
## Seconds between two passes of the horror, shortest and longest, and its first pass.
const HORROR_INTERVAL := Vector2(60.0, 150.0)
const HORROR_FIRST := Vector2(15.0, 40.0)
## Screen length of the horror, its speed (ground units per second) and how far from the wader
## it passes (ground units, deeper down).
const HORROR_LENGTH := 820.0
const HORROR_SPEED := 70.0
const HORROR_OFFSET := Vector2(350.0, 650.0)
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
const EYE_WAIT := Vector2(5.0, 14.0)
const EYE_HEIGHT := 34.0
## The eyes show only where the deep sea is at least this dark (SeaDepth.abyss).
const EYE_MIN_DARK := 0.5

## Set by the scene every frame: the wader, the ground rows of the last zone and of the zones
## with eyes, and the spotlight (Spotlight).
var wader_ground := Vector2.ZERO
var horror_rows := Vector2(INF, INF)
var eye_rows := Vector2(INF, INF)
var spot_width := 2160.0
var light_origin := Vector2.ZERO
var light_dir := Vector2.RIGHT
var light_on := 0.0

var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _horror_wait := 0.0
## The horror passing now: its ground position and direction on screen (+1 right, -1 left); none
## while _horror_dir is 0. It glides straight across the screen, as it is drawn from the side.
var _horror_at := Vector2.ZERO
var _horror_dir := 0.0
var _eyes: Array[Eyes] = []
## Draws the horror again additively, so only its bright parts (eye, teeth, lights) shine.
var _shine := Node2D.new()


func _ready() -> void:
	_shine.material = Glow.material()
	_shine.draw.connect(_draw_horror.bind(_shine, true))
	add_child(_shine)
	_rng.randomize()
	_horror_wait = _rng.randf_range(HORROR_FIRST.x, HORROR_FIRST.y)
	for i in EYE_PAIRS:
		var eyes := Eyes.new()
		eyes.wait = _rng.randf_range(1.0, EYE_WAIT.y)
		_eyes.append(eyes)


func _process(delta: float) -> void:
	_time += delta
	_update_horror(delta)
	for eyes in _eyes:
		_update_eyes(eyes, delta)
	queue_redraw()
	_shine.queue_redraw()


## Starts a pass of the horror right away, `start` ground units off to the side, if the wader is in
## the last zone (also for screenshots).
func send_horror(start: float = 1300.0) -> void:
	if not _in_rows(wader_ground.y, horror_rows):
		return
	_horror_dir = 1.0 if _rng.randf() < 0.5 else -1.0
	var depth := clampf(wader_ground.y + _rng.randf_range(HORROR_OFFSET.x, HORROR_OFFSET.y), horror_rows.x + 200.0, horror_rows.y - 150.0)
	_horror_at = Vector2(wader_ground.x, depth) - _screen_right() * _horror_dir * start


func _update_horror(delta: float) -> void:
	if _horror_dir == 0.0:
		_horror_wait -= delta
		if _horror_wait <= 0.0:
			_horror_wait = _rng.randf_range(HORROR_INTERVAL.x, HORROR_INTERVAL.y)
			send_horror()
		return
	_horror_at += _screen_right() * _horror_dir * HORROR_SPEED * delta
	var ahead := (_horror_at - wader_ground).dot(_screen_right()) * _horror_dir
	if ahead > 1500.0:
		_horror_dir = 0.0


## The ground direction that runs straight to the right on screen.
static func _screen_right() -> Vector2:
	return Vector2(1.0, -1.0).normalized()


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
	# The sprite faces east; mirrored when it swims west. A slow sway of the body.
	canvas.draw_set_transform(at, sin(_time * 0.8) * 0.03, Vector2(_horror_dir, 1.0))
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
	var ground := Vector2.ZERO
	var texture: Texture2D
	var alpha := 0.0
	var wait := 0.0
	var blink_phase := 0.0
	var stay := 0.0
	var since := 0.0
