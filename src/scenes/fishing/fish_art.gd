class_name FishArt
extends RefCounted
## Side-on sprite of one species, drawn from two images so the tail can beat: <id>_body and
## <id>_tail: painted PNGs in assets/sprites/fish_painted, cut from the painted sheets by
## tools/extract_painted.py. A species without sprites is drawn as a coloured placeholder.
##
## Layout (in canvas units): the body canvas is 240 wide with the tail root at x=20 and the
## snout at x=220; the tail canvas is 70 wide with the tail root at x=62. Both are centred
## vertically on the body axis and face right.
##
## How a species swims (MOTIONS): most fish beat their tail fin ("tail"). Creatures without a
## cut tail are drawn as a bent mesh instead: eels, whales and slow swimmers send a wave down the
## body ("wave"), jellyfish and octopuses squeeze their bell or head and let the arms trail
## ("pulse"), squids squeeze the mantle and pull their arms together ("jet").

const PAINTED_DIR := "res://assets/sprites/fish_painted/"
## Share of the total length taken by the body; the rest is tail fin.
const BODY_SHARE := 0.8
const BODY_CANVAS_WIDTH := 240.0
const BODY_ROOT_X := 20.0
const BODY_SPAN := 200.0
const TAIL_CANVAS_WIDTH := 70.0
const TAIL_ROOT_X := 62.0
const OUTLINE_COLOR := Color(0.07, 0.09, 0.15)

enum Motion { TAIL, WAVE, PULSE, JET }
## Species that do not beat a tail fin; all others do. Waves: height of the wave at the tail
## (share of the length) and the number of waves along the body.
const MOTIONS: Dictionary[String, Motion] = {
	"conger_eel": Motion.WAVE, "frilled_shark": Motion.WAVE, "giant_oarfish": Motion.WAVE,
	"pelican_eel": Motion.WAVE, "pink_ling": Motion.WAVE, "roundnose_grenadier": Motion.WAVE,
	"sloanes_viperfish": Motion.WAVE,
	"blue_whale": Motion.WAVE, "humpback_whale": Motion.WAVE, "southern_right_whale": Motion.WAVE,
	"sperm_whale": Motion.WAVE,
	"ocean_sunfish": Motion.WAVE,
	"reef_manta_ray": Motion.WAVE, "smooth_stingray": Motion.WAVE,
	"green_sea_turtle": Motion.WAVE, "leatherback_turtle": Motion.WAVE, "loggerhead_turtle": Motion.WAVE,
	"knysna_seahorse": Motion.WAVE, "leafy_seadragon": Motion.WAVE, "weedy_seadragon": Motion.WAVE,
	"giant_isopod": Motion.WAVE, "japanese_spider_crab": Motion.WAVE, "chambered_nautilus": Motion.WAVE,
	"moon_jellyfish": Motion.PULSE, "lions_mane_jellyfish": Motion.PULSE, "blubber_jellyfish": Motion.PULSE,
	"nomuras_jellyfish": Motion.PULSE, "portuguese_man_o_war": Motion.PULSE, "vampire_squid": Motion.PULSE,
	"common_octopus": Motion.PULSE, "curled_octopus": Motion.PULSE, "giant_pacific_octopus": Motion.PULSE,
	"southern_blue_ringed_octopus": Motion.PULSE,
	"giant_squid": Motion.JET, "colossal_squid": Motion.JET, "japanese_flying_squid": Motion.JET,
}
const WAVES: Dictionary[String, Vector2] = {
	"conger_eel": Vector2(0.07, 1.2), "frilled_shark": Vector2(0.06, 1.0), "giant_oarfish": Vector2(0.05, 1.6),
	"pelican_eel": Vector2(0.07, 1.4), "pink_ling": Vector2(0.06, 1.2), "roundnose_grenadier": Vector2(0.06, 1.0),
	"sloanes_viperfish": Vector2(0.06, 1.2),
	"blue_whale": Vector2(0.05, 0.6), "humpback_whale": Vector2(0.05, 0.6), "southern_right_whale": Vector2(0.05, 0.6),
	"sperm_whale": Vector2(0.05, 0.6), "reef_manta_ray": Vector2(0.05, 0.6), "smooth_stingray": Vector2(0.05, 0.9),
}
const GENTLE_WAVE := Vector2(0.025, 0.6)
## Waves, squeezes and jets go slower than a tail beat.
const WAVE_RATE := 0.7
const PULSE_RATE := 0.35
## Grid the bent sprites are drawn as.
const MESH_COLUMNS := 10
const MESH_ROWS := 5

var species: SpeciesDef
var body: Texture2D
var tail: Texture2D
var motion := Motion.TAIL


static func for_species(def: SpeciesDef) -> FishArt:
	var art := FishArt.new()
	art.species = def
	art.motion = MOTIONS.get(def.id, Motion.TAIL)
	var body_path := PAINTED_DIR + def.id + "_body.png"
	var tail_path := PAINTED_DIR + def.id + "_tail.png"
	if ResourceLoader.exists(body_path) and ResourceLoader.exists(tail_path):
		art.body = load(body_path)
		art.tail = load(tail_path)
		# Creatures without a cut tail have an empty tail image.
		if art.motion != Motion.TAIL and art.tail.get_image().is_invisible():
			art.tail = null
	return art


func has_sprite() -> bool:
	return body != null


## Draws the fish centred on the origin of `view` (fish space: head towards +x, back towards -y)
## with the given total length. `phase` runs through the swimming cycle (radians) and `swim`
## says how strongly it swims (0 = at rest, 1 = full speed); `tint` multiplies the colours
## (black gives a silhouette).
func draw(canvas: CanvasItem, view: Transform2D, length: float, phase: float = 0.0, swim: float = 0.0, tint: Color = Color.WHITE) -> void:
	if not has_sprite():
		_draw_placeholder(canvas, view, length, tint)
		return
	var units := length * BODY_SHARE / BODY_SPAN
	var root_x := length * (0.5 - BODY_SHARE)
	var body_size := body.get_size() * (BODY_CANVAS_WIDTH / body.get_width()) * units
	var body_rect := Rect2(Vector2(root_x - BODY_ROOT_X * units, -body_size.y * 0.5), body_size)
	var tail_rect := Rect2()
	if tail != null:
		var tail_size := tail.get_size() * (TAIL_CANVAS_WIDTH / tail.get_width()) * units
		tail_rect = Rect2(Vector2(root_x - TAIL_ROOT_X * units, -tail_size.y * 0.5), tail_size)

	if motion == Motion.TAIL or swim <= 0.0:
		# The tail fin beats by shortening towards the camera and back.
		var tail_beat := 1.0 - swim * 0.25 * (1.0 - sin(phase))
		if tail != null:
			var beat := Transform2D(Vector2(tail_beat, 0.0), Vector2(0.0, 1.0), Vector2(root_x * (1.0 - tail_beat), 0.0))
			canvas.draw_set_transform_matrix(view * beat)
			canvas.draw_texture_rect(tail, tail_rect, false, tint)
		canvas.draw_set_transform_matrix(view)
		canvas.draw_texture_rect(body, body_rect, false, tint)
		canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
		return

	var warp: Callable
	match motion:
		Motion.WAVE:
			warp = _wave.bind(length, phase * WAVE_RATE, swim)
		Motion.PULSE:
			warp = _pulse.bind(body_rect, phase * PULSE_RATE, swim)
		Motion.JET:
			warp = _jet.bind(body_rect, phase * PULSE_RATE, swim)
	canvas.draw_set_transform_matrix(view)
	if tail != null:
		_draw_mesh(canvas, tail, tail_rect, warp, tint)
	_draw_mesh(canvas, body, body_rect, warp, tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


## A wave running from the head down to the tail, growing towards the tail.
func _wave(point: Vector2, length: float, phase: float, swim: float) -> Vector2:
	var wave: Vector2 = WAVES.get(species.id, GENTLE_WAVE)
	var along := clampf(0.5 - point.x / length, 0.0, 1.0)
	return point + Vector2(0.0, wave.x * length * swim * along * along * sin(phase - TAU * wave.y * along))


## Squeezes a bell (or head) at the top quickly and lets it widen slowly; the arms below stay
## wide and sway behind.
func _pulse(point: Vector2, rect: Rect2, phase: float, swim: float) -> Vector2:
	var squeeze := _squeeze(phase) * swim
	var center := rect.get_center()
	var top := clampf((rect.end.y - point.y) / rect.size.y, 0.0, 1.0)
	var x := center.x + (point.x - center.x) * (1.0 - 0.25 * squeeze * top)
	x += sin(phase * 2.0 - top * 4.0) * rect.size.x * 0.03 * swim * (1.0 - top)
	return Vector2(x, point.y - squeeze * rect.size.y * 0.08 * top)


## Squeezes the mantle (head end, right) and pulls the arms (left) together and back.
func _jet(point: Vector2, rect: Rect2, phase: float, swim: float) -> Vector2:
	var squeeze := _squeeze(phase) * swim
	var mantle := clampf((point.x - rect.position.x) / rect.size.x, 0.0, 1.0)
	var arms := 1.0 - mantle
	var y := point.y * (1.0 - squeeze * (0.1 * mantle + 0.4 * arms))
	y += sin(phase * 2.0 + mantle * 6.0) * rect.size.y * 0.04 * swim * arms
	return Vector2(point.x - squeeze * rect.size.x * 0.12 * arms * arms, y)


## 0 to 1: a quick squeeze, then a slow release.
static func _squeeze(phase: float) -> float:
	var t := fposmod(phase, TAU) / TAU
	return t / 0.25 if t < 0.25 else 1.0 - (t - 0.25) / 0.75


## Draws the texture over the rect as a grid whose points `warp` moves.
static func _draw_mesh(canvas: CanvasItem, texture: Texture2D, rect: Rect2, warp: Callable, tint: Color) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for row in MESH_ROWS + 1:
		for column in MESH_COLUMNS + 1:
			var uv := Vector2(float(column) / MESH_COLUMNS, float(row) / MESH_ROWS)
			points.append(warp.call(rect.position + uv * rect.size))
			uvs.append(uv)
			colors.append(tint)
	var indices := PackedInt32Array()
	for row in MESH_ROWS:
		for column in MESH_COLUMNS:
			var corner := row * (MESH_COLUMNS + 1) + column
			indices.append_array([corner, corner + 1, corner + MESH_COLUMNS + 2, corner, corner + MESH_COLUMNS + 2, corner + MESH_COLUMNS + 1])
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors, uvs,
		PackedInt32Array(), PackedFloat32Array(), texture.get_rid())


## A plain oval with a tail in the species colour, for species without sprites yet.
func _draw_placeholder(canvas: CanvasItem, view: Transform2D, length: float, tint: Color) -> void:
	var height := length * species.body_aspect
	var oval := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		oval.append(Vector2(cos(angle) * length * 0.4 + length * 0.1, sin(angle) * height * 0.5))
	var fin := PackedVector2Array([
		Vector2(-length * 0.25, 0.0), Vector2(-length * 0.5, -height * 0.45), Vector2(-length * 0.5, height * 0.45),
	])
	for shape: PackedVector2Array in [fin, oval]:
		var points := view * shape
		canvas.draw_colored_polygon(points, species.placeholder_color * tint)
		points.append(points[0])
		canvas.draw_polyline(points, OUTLINE_COLOR, 2.5, true)
