class_name Seabirds
extends Node2D
## Now and then a seabird, or a small flock, flies over the screen, high above its faint shadow:
## one kind per location, flying reptiles in the Jurassic Sea. Painted seen from above, flying
## screen-left (assets/sprites/birds, cut from art_source/props/seabirds_N.png by
## tools/extract_seabirds.py); mirrored to fly right. They beat their wings for a while, then
## glide. Nothing can catch them.

## Per location the kinds that fly there: [sprite id, size (the gliding sprite's longest side,
## ground pixels), wing beats per second, share of the time spent gliding].
const KINDS: Dictionary[String, Array] = {
	"north_sea": [["herring_gull", 140.0, 2.6, 0.5]],
	"coral_reef": [["great_frigatebird", 170.0, 2.0, 0.75]],
	"australia": [["australian_pelican", 200.0, 1.6, 0.6]],
	"japan": [["black_tailed_gull", 135.0, 2.6, 0.5]],
	"south_africa": [["cape_gannet", 165.0, 2.4, 0.5]],
	"antarctica": [["wandering_albatross", 230.0, 1.4, 0.85]],
	"jurassic_sea": [["rhamphorhynchus", 150.0, 2.4, 0.5], ["pterodactylus", 115.0, 2.8, 0.4]],
}
const POSES: Array[String] = ["glide", "up", "mid", "down"]
## The wing beat: up, level, down, level.
const BEAT: Array[int] = [1, 2, 3, 2]
## Seconds between two flights over the screen, shortest and longest.
const INTERVAL := Vector2(45.0, 120.0)
## Birds in a flock, and how far apart they fly (ground pixels).
const FLOCK := Vector2i(1, 3)
const FLOCK_SPREAD := Vector2(150.0, 80.0)
## How high above its shadow a bird flies, and how fast (screen pixels of the world per second).
const HEIGHT := 260.0
const SPEED := Vector2(110.0, 150.0)
## Seconds of beating, then of gliding (scaled by the kind's glide share).
const FLAP_TIME := Vector2(1.0, 2.5)
const GLIDE_TIME := Vector2(1.5, 4.0)
## Where across the view (share of its height, from the top) a flight crosses: clear of the
## top and bottom bars.
const LANE := Vector2(0.25, 0.6)
## A flight starts and ends this far beyond the sides of the view.
const MARGIN := 150.0
const SHADOW := Color(0.0, 0.06, 0.14, 0.12)

## Set by the scene: the location and the part of the world on screen.
var location_id := "north_sea"
var view := Rect2(0.0, 0.0, 720.0, 1280.0)

var _rng := RandomNumberGenerator.new()
var _wait := 0.0
var _birds: Array[Bird] = []
var _textures: Dictionary[String, Texture2D] = {}


class Bird:
	var kind: Array
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var gliding := false
	var phase_left := 0.0
	var beat := 0.0


func _ready() -> void:
	_rng.randomize()
	_wait = _rng.randf_range(INTERVAL.x * 0.3, INTERVAL.y * 0.5)


func _process(delta: float) -> void:
	update(delta)
	queue_redraw()


## Advances the flights by `delta` seconds; a new one starts when due.
func update(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_wait = _rng.randf_range(INTERVAL.x, INTERVAL.y)
		send_flock()
	for bird in _birds:
		bird.position += bird.velocity * delta
		bird.phase_left -= delta
		if bird.phase_left <= 0.0:
			_switch(bird)
		if not bird.gliding:
			bird.beat += delta * bird.kind[2]
	_birds = _birds.filter(func(b: Bird) -> bool: return not _gone(b))


## Sends a bird or a small flock across the view, from beyond one side to beyond the other.
## Nothing flies at a location without birds (or without their sprites).
func send_flock() -> void:
	var kinds: Array = KINDS.get(location_id, []).filter(func(k: Array) -> bool: return has_sprites(k[0]))
	if kinds.is_empty():
		return
	var kind: Array = kinds[_rng.randi_range(0, kinds.size() - 1)]
	var right := _rng.randf() < 0.5
	var speed := _rng.randf_range(SPEED.x, SPEED.y)
	var drift := _rng.randf_range(-0.15, 0.15) * speed
	var start := Vector2(view.position.x - MARGIN if right else view.end.x + MARGIN, view.position.y + view.size.y * _rng.randf_range(LANE.x, LANE.y))
	for i in _rng.randi_range(FLOCK.x, FLOCK.y):
		var bird := Bird.new()
		bird.kind = kind
		var behind := FLOCK_SPREAD.x * i * (-1.0 if right else 1.0)
		bird.position = start + Vector2(behind + _rng.randf_range(-15.0, 15.0), _rng.randf_range(-FLOCK_SPREAD.y, FLOCK_SPREAD.y) * signf(i))
		bird.velocity = Vector2(speed if right else -speed, drift)
		bird.gliding = _rng.randf() < kind[3]
		bird.phase_left = _rng.randf_range(0.0, 1.5)
		bird.beat = _rng.randf()
		_birds.append(bird)


func flying() -> int:
	return _birds.size()


## True when all poses of the bird `id` are painted.
static func has_sprites(id: String) -> bool:
	return POSES.all(func(pose: String) -> bool: return ResourceLoader.exists("res://assets/sprites/birds/%s_%s.png" % [id, pose]))


func _switch(bird: Bird) -> void:
	bird.gliding = not bird.gliding
	var share: float = bird.kind[3]
	if bird.gliding:
		bird.phase_left = _rng.randf_range(GLIDE_TIME.x, GLIDE_TIME.y) * share * 2.0
	else:
		bird.phase_left = _rng.randf_range(FLAP_TIME.x, FLAP_TIME.y) * (1.0 - share) * 2.0
		bird.beat = 0.0


func _gone(bird: Bird) -> bool:
	return bird.position.x < view.position.x - MARGIN * 2.0 - FLOCK_SPREAD.x * FLOCK.y if bird.velocity.x < 0.0 \
			else bird.position.x > view.end.x + MARGIN * 2.0 + FLOCK_SPREAD.x * FLOCK.y


func _draw() -> void:
	for bird in _birds:
		draw_colored_polygon(Iso.ellipse(bird.position + Vector2(0.0, HEIGHT), bird.kind[1] * 0.22, 12), SHADOW)
	for bird in _birds:
		var pose := 0 if bird.gliding else BEAT[floori(bird.beat * BEAT.size()) % BEAT.size()]
		var texture := _texture(bird.kind[0], POSES[pose])
		var glide := _texture(bird.kind[0], "glide")
		var scale_by: float = bird.kind[1] / maxf(glide.get_width(), glide.get_height())
		var size := texture.get_size() * scale_by
		var flip := -1.0 if bird.velocity.x > 0.0 else 1.0
		draw_set_transform(bird.position, 0.0, Vector2(flip, 1.0))
		draw_texture_rect(texture, Rect2(-size * 0.5, size), false)
	draw_set_transform(Vector2.ZERO)


func _texture(id: String, pose: String) -> Texture2D:
	var key := "%s_%s" % [id, pose]
	if not _textures.has(key):
		_textures[key] = load("res://assets/sprites/birds/%s.png" % key)
	return _textures[key]
