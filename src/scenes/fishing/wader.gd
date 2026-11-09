class_name Wader
extends Node2D
## The player character at shallow spots. Wades towards the finger, scoops up fish that come
## within reach of the hand net and carries them as a stack in a backpack basket. Game logic
## uses `ground_position`; the node sits at the feet on screen. Drawn from painted sprites in
## assets/sprites/wader: the figure in the outfit the zone calls for (waders with the basket,
## snorkel, scuba gear, rebreather, hard-hat suit, submersible; tools/extract_wader_sheet.py) in
## the view of its walking direction, painted in step while walking, with the catch stacked on its
## back and the landing net of its net level (tools/extract_wader.py). From the scuba gear on the
## tank takes the back, so the catch goes into a mesh bag towed on a short line instead
## (assets/sprites/wader/catch_bag.png, art_source/characters/catch_bag_sprite_prompt.md).

const WALK_SPEED := 450.0
const ACCELERATION := 2400.0
## Share of the speed kept when the finger lifts.
const STOP_KEEP_SPEED := 0.2
const ARRIVE_DISTANCE := 10.0
## Starts slowing down this close to the target, so arrival feels soft.
const SLOWDOWN_DISTANCE := 70.0
## Distance from the feet to the centre of the net hoop, in ground units.
const REACH := 95.0
## Net radius with the hand net; better nets are a little wider.
const SCOOP_RADIUS := 55.0
## The water rises on the figure with the distance from the shore (the waterline is at ground
## y 0): up to the knees in the middle of the first zone, the hips early in the second, and
## over the head where the third zone begins. What is below the surface takes on the water's
## tint for the depth, like the fish (src/shaders/fish_water.gdshader).
const SUBMERGE_DEPTH := 8 * Grid.UNIT
const FIGURE_HEIGHT := 216.0
const DRY := 100000.0
const SUBMERGED := -100000.0
## Share of the seabed's depth tint on what is under water.
const UNDERWATER_TINT := 0.55
const WATER_SHADER := preload("res://src/shaders/fish_water.gdshader")

const WADER_DIR := "res://assets/sprites/wader/"
## Walking more sideways than this (share of the screen direction) shows a three-quarter view,
## and nearly straight across the screen (less up or down than SIDE_VIEW) the profile. These views
## are painted looking screen-left; they are mirrored when walking to the right.
const DIAGONAL_VIEW := 0.35
const SIDE_VIEW := 0.5
## Outfits by gear level.
const OUTFITS: Array[String] = ["wader", "snorkel", "scuba", "rebreather", "hardhat", "sub"]
## Each view of an outfit is a strip of the standing frame and WALK_FRAMES walk frames, one per
## quarter of the walk cycle (tools/extract_wader_sheet.py).
const WALK_FRAMES := 4
## The submersible floats this high above the ground.
const SUB_FLOAT := 40.0
## The catch stack rises from the basket rim.
const STACK_BASE := Vector2(0.0, -136.0)
## Each fish on the stack rises this share of its and the one below's mean thickness above it:
## below 1 they overlap.
const STACK_OVERLAP := 0.5
## Carried fish keep their sizes relative to each other: their length in the sea
## (CatchRules.body_length) times CARRIED_SCALE, within these bounds (a mackerel about 50, a cod
## about 75, a whale at the top). In the towed bag BAG_SCALE of that.
const CARRIED_SCALE := 0.42
const CARRIED_LENGTH := Vector2(30.0, 120.0)
const BAG_SCALE := 0.8
## From this gear on the catch is towed in a bag instead of stacked on the back.
const TOW_FROM_GEAR := 3
const CATCH_BAG: Texture2D = preload("res://assets/sprites/wader/catch_bag.png")
## In the bag sprite: the middle of its mouth (the ring), where the tow line is tied (the snap
## hook), and the ring's width.
const BAG_MOUTH := Vector2(615.0, 145.0)
const BAG_HOOK := Vector2(45.0, 365.0)
const BAG_RING_WIDTH := 470.0
## Screen width of the ring, empty and with BAG_FULL_COUNT fish or more.
const BAG_MOUTH_SCREEN := Vector2(34.0, 52.0)
const BAG_FULL_COUNT := 12
## The bag trails this far behind and to the side (ground units, so the body does not hide it)
## and floats this high (screen) on its line, which is tied to the diver's belt.
const TOW_DISTANCE := 95.0
const TOW_SIDE := 70.0
const TOW_HEIGHT := 70.0
const TOW_BELT := Vector2(0.0, -95.0)
const TOW_LINE := Color(0.95, 0.78, 0.2)
## Fish shown poking out of the bag's mouth, and their length.
const BAG_SHOWN := 3
## The submersible's headlamp in the standing frame of each view (pixels from its top left, as
## painted looking screen-left), where its spotlight comes from: a glow on the lamp and a soft
## beam down to the lit seabed (Spotlight). The lamp is hidden in the back view.
const SUB_LAMPS: Dictionary[String, Vector2] = {
	"front": Vector2(93.0, 18.0), "towards": Vector2(80.0, 17.0), "side": Vector2(55.0, 28.0),
	"away": Vector2(70.0, 30.0), "back": Vector2(90.0, 28.0),
}
## The hard-hat helmet's headlamp in the standing frame of each view, as SUB_LAMPS. It shines
## more dimly (fishing_scene's HEADLAMP_LIGHT), and its lens faces away in the away and back
## views, so those show no glow.
const HARDHAT_LAMPS: Dictionary[String, Vector2] = {
	"front": Vector2(84.0, 24.0), "towards": Vector2(56.0, 35.0), "side": Vector2(55.0, 28.0),
	"away": Vector2(68.0, 27.0), "back": Vector2(81.0, 30.0),
}
const LAMP_COLOR := Color(1.0, 0.95, 0.8)
## The beam reaches the seabed this far ahead of the sub (ground units), as wide as the cone
## (half angle), and starts this bright at the lamp.
const BEAM_REACH := 400.0
const BEAM_HALF_ANGLE := 0.66
const BEAM_ALPHA := 0.2
const BEAM_STEPS := 10
## Shoulder of the net arm, for side = +1 (net on the right).
const NET_SHOULDER := Vector2(27.0, -112.0)
## Landing nets by net level (assets/sprites/wader/net_N, art_source/characters/net_sprite_prompt.md,
## all six painted to the same layout): the hoop lies on the water at the catch point, and the
## painted handle runs from it to the hand, stretched along its own length as far as needed (the
## hoop keeps its shape). In the sprites: the hoop centre, the handle's tip and the hoop's width as
## shares of the sprite, and where the handle starts (share of the width, measured from the hoop
## centre along the handle).
const NET_HOOP := Vector2(0.316, 0.256)
const NET_TIP := Vector2(0.945, 0.836)
const NET_HOOP_WIDTH := 0.577
const NET_HANDLE_START := 0.303
const NET_LEVELS := 6
## Screen width of the hoop with the first net; better nets are a little bigger.
const NET_HOOP_SCREEN := 64.0
const NET_GROWTH := 0.08

const OUTLINE := Color(0.07, 0.09, 0.15)
## The ring on the water that shows where the net catches.
const CATCH_RING := Color(1.0, 1.0, 1.0, 0.45)
const HOOP_FULL := Color(1.0, 0.45, 0.3)
const SHADOW := Color(0.0, 0.06, 0.14, 0.25)
const PROGRESS := Color(1.0, 0.85, 0.2)
## Opacity of the copy shown while something stands in front of the wader.
const SEE_THROUGH := 0.4
## Screen half width of the figure, for telling whether something covers it.
const FIGURE_HALF_WIDTH := 50.0

var ground_position := Vector2.ZERO
var ground_velocity := Vector2.ZERO
## Ground direction the wader faces; starts facing the camera.
var facing := Vector2(1.0, 1.0).normalized()
## How close the furthest-along struggling fish is to being caught, 0..1.
var struggle_progress := 0.0
## True when the backpack is full; shown above the stack.
var full := false
## The fish in the backpack, bottom first.
var carried: Array[FishArt] = []
## False on the beach: no water around the legs.
var in_water := true
## True in deeper zones: the water comes up to the chest.
var swimming := false
## Diving gear bought: the gear for the current zone is worn, up to this level.
var gear_level := 1
## Order of the depth zone the wader is in; 0 on the beach.
var zone_order := 0
## Index + 1 into the net levels; picks the landing net.
var net_level := 1
## Current net radius (grows with the net level).
var scoop_radius := SCOOP_RADIUS
## Walking speed factor: faster on the sand than in the water.
var speed_multiplier := 1.0
## Ground units per second a current carries the wader along, on top of its own walking. Set by
## the scene for the zone it is in.
var drift := Vector2.ZERO
## What the wader can walk behind (Layers.Cover, in the parent's coordinates). Set by the scene.
var covers: Array[Layers.Cover] = []
## True while one of `covers` stands in front of the figure.
var covered := false
## Tells whether something on the water's surface above the swimming wader (IceFloes.hides())
## hides a screen rectangle; then the see-through copy shows above it. Set by the scene, if any.
var surface_hides: Callable
## The spotlight (Spotlight): the ground direction it shines in and how far it is on (0 to 1).
## Set by the scene; drawn as the beam from the submersible's headlamp.
var light_dir := Vector2(1.0, 1.0).normalized()
var light_on := 0.0

var _target := Vector2.ZERO
var _has_target := false
var _walk_phase := 0.0
var _time := 0.0
var _dip := 0.0
var _stack_bounce := 0.0
## Loaded sprites by name.
var _textures: Dictionary[String, Texture2D] = {}
## The see-through copy of the figure, shown above everything while it is covered. A group, so
## the parts of the figure do not show through each other.
var _see_through := CanvasGroup.new()
var _see_through_figure := Node2D.new()
## Draws what the water does not tint, above the figure.
var _overlay := Node2D.new()
## The headlamp's glow and beam, drawn additively; behind the figure while the beam points away
## from the camera.
var _beam := Node2D.new()


func _ready() -> void:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = WATER_SHADER
	shader_material.set_shader_parameter("strength", UNDERWATER_TINT)
	material = shader_material
	Layers.put(self, Layers.WADER)
	Layers.put(_see_through, Layers.WADER)
	_see_through.self_modulate = Color(1.0, 1.0, 1.0, SEE_THROUGH)
	_see_through.visible = false
	_see_through_figure.draw.connect(_draw_figure.bind(_see_through_figure))
	_see_through.add_child(_see_through_figure)
	add_child(_see_through)
	_beam.material = Glow.material()
	_beam.draw.connect(_draw_beam)
	add_child(_beam)
	Layers.put(_overlay, Layers.WADER)
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


## The water colours of the location, which what is under water takes on with depth.
func set_water_colors(shallow: Color, deep: Color, clarity: float) -> void:
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("shallow_color", shallow)
	shader_material.set_shader_parameter("deep_color", deep)
	shader_material.set_shader_parameter("clarity", clarity)


## Screen height (relative to the feet) of the water surface on the figure: DRY on the beach,
## SUBMERGED once the water is deeper than the figure.
func waterline() -> float:
	if not in_water:
		return DRY
	var share := ground_position.y / SUBMERGE_DEPTH
	return SUBMERGED if share >= 1.0 else -FIGURE_HEIGHT * maxf(share, 0.0)


func walk_to(ground_target: Vector2) -> void:
	_target = ground_target
	_has_target = true


## Stops walking, braking hard so it only takes a short step.
func stop() -> void:
	_has_target = false
	ground_velocity *= STOP_KEEP_SPEED


## True when the wader travels in the submersible: no steps, no ripples.
func in_submarine() -> bool:
	return _gear() >= OUTFITS.size()


## True when the outfit has a headlamp: the hard-hat helmet and the submersible.
func has_headlamp() -> bool:
	return _gear() >= OUTFITS.find("hardhat") + 1


## The gear worn: each zone calls for its gear (snorkel in the second, scuba in the third, and so
## on), up to the gear bought.
func _gear() -> int:
	return mini(gear_level, zone_order) if swimming else 1


func is_walking() -> bool:
	return ground_velocity.length() > 20.0


## Footfalls so far: one for every half swing of the legs.
func steps_taken() -> int:
	return floori(_walk_phase / PI)


## Ground centre of the net hoop, where fish are scooped up.
func scoop_center() -> Vector2:
	return ground_position + facing * REACH


func hoop_screen_position() -> Vector2:
	return position + _hoop_offset()


## Screen position of the top of the catch stack, or of the towed bag's mouth.
func stack_top_position() -> Vector2:
	if tows_bag():
		return position + _bag_mouth()
	var rises := _stack_rises(1.0)
	return position + STACK_BASE + Vector2(0.0, -rises[-1] if not rises.is_empty() else 0.0)


## Screen length of a carried fish on the stack (or, times BAG_SCALE, in the bag).
static func carried_length(art: FishArt) -> float:
	return clampf(CatchRules.body_length(art.species) * CARRIED_SCALE, CARRIED_LENGTH.x, CARRIED_LENGTH.y)


## How high each fish of the stack lies above the bottom one, squashed by `squash`.
func _stack_rises(squash: float) -> PackedFloat32Array:
	var rises := PackedFloat32Array()
	var below := 0.0
	for art in carried:
		var thickness := carried_length(art) * art.species.body_aspect
		rises.append(0.0 if rises.is_empty() else rises[-1] + (below + thickness) * 0.5 * STACK_OVERLAP * squash)
		below = thickness
	return rises


## True when the catch goes into the towed bag rather than onto the back.
func tows_bag() -> bool:
	return _gear() >= TOW_FROM_GEAR


## Puts a caught fish on top of the stack, with a short dip of the net.
func add_to_stack(art: FishArt) -> void:
	carried.append(art)
	_dip = 1.0
	_stack_bounce = 1.0


## Takes the top fish off the stack.
func take_from_stack() -> FishArt:
	return take_from_stack_at(carried.size() - 1)


## Takes a fish out of the stack; the ones above it drop down.
func take_from_stack_at(index: int) -> FishArt:
	_stack_bounce = 0.6
	var art := carried[index]
	carried.remove_at(index)
	return art


func simulate(delta: float, area: PlayArea) -> void:
	_time += delta
	_dip = maxf(_dip - delta * 5.0, 0.0)
	_stack_bounce = maxf(_stack_bounce - delta * 4.0, 0.0)
	var desired := Vector2.ZERO
	if _has_target:
		var to_target := _target - ground_position
		var distance := to_target.length()
		if distance > ARRIVE_DISTANCE:
			desired = to_target / distance * WALK_SPEED * speed_multiplier * minf(distance / SLOWDOWN_DISTANCE, 1.0)
		else:
			_has_target = false
	ground_velocity = ground_velocity.move_toward(desired, ACCELERATION * delta)
	ground_position = area.clamp_point(ground_position + (ground_velocity + drift) * delta, 20.0)
	if is_walking():
		facing = facing.slerp(ground_velocity.normalized(), clampf(10.0 * delta, 0.0, 1.0)).normalized()
	_walk_phase += delta * ground_velocity.length() / 42.0
	position = Iso.to_screen(ground_position)
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("waterline", waterline())
	shader_material.set_shader_parameter("depth", SeaDepth.depth(ground_position.y))
	shader_material.set_shader_parameter("abyss", SeaDepth.abyss(ground_position.y))
	_update_cover()
	queue_redraw()
	_overlay.queue_redraw()
	_beam.visible = light_on > 0.0 and has_headlamp()
	if _beam.visible:
		_beam.show_behind_parent = Iso.to_screen(light_dir).y < 0.0
		_beam.queue_redraw()
	if _see_through.visible:
		_see_through_figure.queue_redraw()


## Drawn among the objects, behind the one in front, while one of `covers` hides part of the
## figure; on its own layer above the pads otherwise. Its see-through copy shows above whatever
## covers it: on the wader's layer above the objects, on the surface layer under ice floes.
func _update_cover() -> void:
	var figure := Rect2(position + Vector2(-FIGURE_HALF_WIDTH, -FIGURE_HEIGHT), Vector2(FIGURE_HALF_WIDTH * 2.0, FIGURE_HEIGHT))
	covered = false
	for cover in covers:
		if cover.sort_y > position.y and cover.bounds.intersects(figure):
			covered = true
			break
	z_index = Layers.OBJECTS if covered else Layers.WADER
	var under_surface: bool = not covered and swimming and surface_hides.is_valid() and surface_hides.call(figure)
	_see_through.z_index = Layers.SURFACE if under_surface else Layers.WADER
	_see_through.visible = covered or under_surface


func _hoop_offset() -> Vector2:
	return Iso.to_screen(facing * REACH) + Vector2(0.0, 6.0 * _dip)


#region Drawing

func _draw() -> void:
	draw_colored_polygon(Iso.ellipse(Vector2.ZERO, 30.0), SHADOW)
	_draw_figure(self)


## The figure with its net and catch, on `canvas`.
func _draw_figure(canvas: CanvasItem) -> void:
	var screen_facing := Iso.to_screen(facing)
	var side := -1.0 if screen_facing.x < 0.0 else 1.0
	# The submersible floats gently instead of stepping.
	var bob := sin(_time * 2.0) * (4.0 if in_submarine() else 1.5)
	if is_walking() and not in_submarine():
		bob = absf(sin(_walk_phase)) * 5.0
	var hoop := _hoop_offset()
	var gear := _gear()
	var view := _view(screen_facing.normalized())
	var view_name: String = view[0]
	var from_behind := view_name == "back" or view_name == "away"

	# The towed bag trails behind: drawn first when it is further from the camera than the diver.
	var bag_behind := tows_bag() and _bag_mouth().y < -TOW_HEIGHT
	if bag_behind:
		_draw_bag(canvas)
	# Facing the camera, the catch on the back is hidden behind the body and the net is in front.
	if from_behind:
		_draw_net(canvas, hoop, side, bob)
	elif not tows_bag():
		_draw_stack(canvas, bob)
	_draw_body(canvas, view, bob, gear)
	if from_behind:
		if not tows_bag():
			_draw_stack(canvas, bob)
	else:
		_draw_net(canvas, hoop, side, bob)
	if tows_bag() and not bag_behind:
		_draw_bag(canvas)


## The outfit the gear calls for, in the view of the walking direction: the standing frame, or the
## walk frame for the point in the step while walking. The submersible floats and turns its
## propeller instead.
func _draw_body(canvas: CanvasItem, view: Array, bob: float, gear: int) -> void:
	var outfit := OUTFITS[clampi(gear, 1, OUTFITS.size()) - 1]
	var texture := _texture("%s_%s" % [outfit, view[0]])
	var frame_size := Vector2(texture.get_width() / (WALK_FRAMES + 1.0), texture.get_height())
	var frame := 1 + posmod(floori(_walk_phase / (PI * 0.5)), WALK_FRAMES) if is_walking() else 0
	var lift := -bob - SUB_FLOAT if outfit == "sub" else 0.0
	canvas.draw_set_transform(Vector2(0.0, lift), 0.0, Vector2(view[1], 1.0))
	canvas.draw_texture_rect_region(texture, Rect2(Vector2(-frame_size.x * 0.5, -frame_size.y), frame_size), Rect2(Vector2(frame * frame_size.x, 0.0), frame_size))
	canvas.draw_set_transform(Vector2.ZERO)


## The headlamp of the submersible or the hard-hat helmet, relative to the node (the feet).
func lamp_position() -> Vector2:
	var view := _view(Iso.to_screen(facing).normalized())
	var sub := in_submarine()
	var texture := _texture("%s_%s" % ["sub" if sub else "hardhat", view[0]])
	var frame_size := Vector2(texture.get_width() / (WALK_FRAMES + 1.0), texture.get_height())
	var lamps := SUB_LAMPS if sub else HARDHAT_LAMPS
	var lamp: Vector2 = lamps[view[0]] - Vector2(frame_size.x * 0.5, frame_size.y)
	var lift := sin(_time * 2.0) * 4.0 + SUB_FLOAT if sub else 0.0
	return Vector2(lamp.x * view[1], lamp.y - lift)


## The headlamp's light: a soft fan from the lamp down to where the spotlight meets the seabed,
## fading out towards it and to its sides, and a glow on the lamp unless it faces away.
func _draw_beam() -> void:
	var lamp := lamp_position()
	var ground_dir := light_dir.normalized()
	var points := PackedVector2Array()
	var weights := PackedFloat32Array()
	for i in BEAM_STEPS + 1:
		var share := float(i) / BEAM_STEPS * 2.0 - 1.0
		points.append(Iso.to_screen(ground_dir.rotated(share * BEAM_HALF_ANGLE) * BEAM_REACH))
		weights.append(1.0 - share * share)
	var bright := Color(LAMP_COLOR, BEAM_ALPHA * light_on)
	var clear := Color(LAMP_COLOR, 0.0)
	for i in BEAM_STEPS:
		var mid_a := lamp.lerp(points[i], 0.4)
		var mid_b := lamp.lerp(points[i + 1], 0.4)
		var color_a := Color(LAMP_COLOR, bright.a * 0.55 * weights[i])
		var color_b := Color(LAMP_COLOR, bright.a * 0.55 * weights[i + 1])
		_beam.draw_primitive([lamp, mid_a, mid_b], [bright, color_a, color_b], [])
		_beam.draw_primitive([mid_a, points[i], points[i + 1], mid_b], [color_a, clear, clear, color_b], [])
	var view: String = _view(Iso.to_screen(facing).normalized())[0]
	if view != "back" and (in_submarine() or view != "away"):
		Glow.draw(_beam, lamp, 34.0, Color(LAMP_COLOR, 0.7 * light_on))
		Glow.draw(_beam, lamp, 12.0, Color(LAMP_COLOR, light_on))


## The view for a screen direction, as [view name, mirror].
func _view(screen_facing: Vector2) -> Array:
	var away := screen_facing.y < 0.0
	if absf(screen_facing.x) <= DIAGONAL_VIEW:
		return ["back" if away else "front", 1.0]
	var name := "side" if absf(screen_facing.y) < SIDE_VIEW else ("away" if away else "towards")
	return [name, -1.0 if screen_facing.x > 0.0 else 1.0]


func _texture(sprite: String) -> Texture2D:
	if not _textures.has(sprite):
		_textures[sprite] = load(WADER_DIR + sprite + ".png")
	return _textures[sprite]


## The stack of caught fish on the back, which sways while walking and leans back against the
## walking direction.
func _draw_stack(canvas: CanvasItem, bob: float) -> void:
	var lean := -Iso.to_screen(ground_velocity).x * 0.004
	var rises := _stack_rises(1.0 - 0.08 * sin(_stack_bounce * PI))
	for i in carried.size():
		var sway := sin(_walk_phase * 0.5 + i * 0.4) * 0.5 * i if is_walking() else 0.0
		var offset_x := (3.0 if i % 2 == 0 else -3.0) + sway + lean * i
		var at := STACK_BASE + Vector2(offset_x, -bob - rises[i])
		var mirror := 1.0 if i % 2 == 0 else -1.0
		carried[i].draw(canvas, Transform2D(Vector2(mirror, 0.0), Vector2(0.0, 1.0), at), carried_length(carried[i]))


## The bag's mouth on screen, relative to the feet: behind the diver on its line, swaying a little.
func _bag_mouth() -> Vector2:
	var sway := Vector2(sin(_time * 1.3) * 6.0, sin(_time * 1.9) * 4.0)
	var behind := -facing * TOW_DISTANCE + facing.orthogonal() * TOW_SIDE
	return Iso.to_screen(behind) + Vector2(0.0, -TOW_HEIGHT) + sway


## The towed catch bag on its line, growing with the catch, the top fish poking out of its mouth.
func _draw_bag(canvas: CanvasItem) -> void:
	var mouth := _bag_mouth()
	var fill := clampf(float(carried.size()) / BAG_FULL_COUNT, 0.0, 1.0)
	var scale_factor := lerpf(BAG_MOUTH_SCREEN.x, BAG_MOUTH_SCREEN.y, fill) / BAG_RING_WIDTH
	# The hook side faces the diver.
	var mirror := 1.0 if mouth.x > 0.0 else -1.0
	var hook := mouth + (BAG_HOOK - BAG_MOUTH) * Vector2(mirror, 1.0) * scale_factor
	canvas.draw_line(TOW_BELT, hook, OUTLINE, 4.0, true)
	canvas.draw_line(TOW_BELT, hook, TOW_LINE, 2.0, true)
	canvas.draw_set_transform(mouth, 0.0, Vector2(mirror, 1.0) * scale_factor)
	canvas.draw_texture(CATCH_BAG, -BAG_MOUTH)
	canvas.draw_set_transform(Vector2.ZERO)
	var shown := mini(carried.size(), BAG_SHOWN)
	for i in shown:
		var art := carried[carried.size() - shown + i]
		# Head up, tail in the bag, fanned out a little.
		var tilt := -PI * 0.5 + (i - (shown - 1) * 0.5) * 0.45
		var length := carried_length(art) * BAG_SCALE
		var at := mouth + Vector2.from_angle(tilt) * length * 0.3
		art.draw(canvas, Transform2D(tilt, at), length, _time * 4.0 + i, 0.3)


## The landing net of the net level, its hoop lying on the water at the catch point and its handle
## reaching up to the hand.
func _draw_net(canvas: CanvasItem, hoop: Vector2, side: float, bob: float) -> void:
	var shoulder := Vector2(NET_SHOULDER.x * side, NET_SHOULDER.y - bob)
	var hand := shoulder + shoulder.direction_to(hoop) * 30.0

	var level := clampi(net_level, 1, NET_LEVELS)
	var texture := _texture("net_%d" % level)
	var size := texture.get_size()
	var center := NET_HOOP * size
	var along := NET_TIP * size - center
	var tip_distance := along.length()
	var u := along / tip_distance
	var v := u.orthogonal()
	var handle_start := NET_HANDLE_START * size.x
	var scale_factor := NET_HOOP_SCREEN * (1.0 + NET_GROWTH * (level - 1)) / (size.x * NET_HOOP_WIDTH)
	var reach := hand - hoop
	var stretch := maxf((reach.length() / scale_factor - handle_start) / (tip_distance - handle_start), 0.2)
	var turn := reach.angle() - u.angle()
	# Mirror the sprite across the handle if needed, so the bag hangs below the hoop on screen.
	var flip := 1.0 if v.rotated(turn).y * v.y >= 0.0 else -1.0
	var big := size.length()
	var handle_half := size.y * 0.25
	for part: Array in [[-big, handle_start, -big, big], [handle_start, tip_distance + 8.0, -handle_half, handle_half]]:
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for corner: Vector2 in [Vector2(part[0], part[2]), Vector2(part[1], part[2]), Vector2(part[1], part[3]), Vector2(part[0], part[3])]:
			uvs.append((center + u * corner.x + v * corner.y) / size)
			var a := corner.x if corner.x <= handle_start else handle_start + (corner.x - handle_start) * stretch
			points.append(hoop + (u * a + v * corner.y * flip).rotated(turn) * scale_factor)
		canvas.draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, texture)


## Drawn on top and untinted by the water: the ring that shows where the net catches, the
## struggle meter around it and the full-backpack warning.
func _draw_overlay() -> void:
	var hoop := _hoop_offset()
	_overlay.draw_polyline(Iso.ellipse(hoop, scoop_radius, 32), HOOP_FULL if full else CATCH_RING, 3.0, true)
	if struggle_progress > 0.0:
		var arc := Iso.ellipse_arc(hoop, scoop_radius + 16.0, -PI * 0.5, -PI * 0.5 + TAU * struggle_progress, 28)
		_overlay.draw_polyline(arc, OUTLINE, 12.0, true)
		_overlay.draw_polyline(arc, PROGRESS, 7.0, true)
	if full:
		_draw_label(tr("Basket full!"), stack_top_position() - position + Vector2(0.0, -40.0))


func _draw_label(text: String, at: Vector2) -> void:
	var font := IsoDraw.title_font()
	var width := 320.0
	var origin := at - Vector2(width * 0.5, 0.0)
	_overlay.draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, 34, 10, OUTLINE)
	_overlay.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, 34, HOOP_FULL)

#endregion
