extends Control
## The fishing screen at a shallow spot, in isometric view. Tap or hold on the water and the
## wader walks there; fish that come within reach of the hand net are scooped up and stacked
## in the backpack. Catches in quick succession build a combo. Walking onto the "Store fish"
## square unloads the backpack into the tank on the beach.
## M1 greybox: one hard-coded layer; the tank only collects fish until M2 adds the hall.

const LAYER_TITLE := "North Sea · Pier"
## Spawn weights for the pier layer. Moves to data/layers.csv in M3.
const PIER_SPAWNS: Dictionary[String, float] = {
	"european_sprat": 50.0,
	"lesser_sand_eel": 30.0,
	"atlantic_herring": 30.0,
	"atlantic_mackerel": 6.0,
}
## How much the world is magnified on screen. Larger means a bigger wader and fish and a
## smaller walkable area.
const ZOOM := 1.5
const TARGET_POPULATION := 12
const SPAWN_INTERVAL_S := 0.8
const BACKPACK_CAPACITY := 12
## Ground y of the waterline. The beach shows in the top-right corner of the screen.
const SHORE_Y := -40.0
## The store square sits this far from the waterline, at this share of the screen width.
const STORE_ZONE_SHORE_DISTANCE := 180.0
const STORE_ZONE_SCREEN_X := 0.6
## Screen pixels covered by the HUD bars at the top and bottom.
const PLAY_MARGIN_TOP := 170.0
const PLAY_MARGIN_BOTTOM := 330.0
## Fish startle when the wader comes this close (ground units). Smaller than the net's reach
## (Wader.REACH + SCOOP_RADIUS), so walking straight at fish catches them.
const THREAT_RADIUS := 130.0
## How much faster an interrupted struggle drains than it builds up.
const HOLD_DECAY := 2.0
## Catches less than this far apart continue the combo.
const COMBO_WINDOW_S := 1.3
## Seconds between fish flying from the backpack into the tank.
const UNLOAD_INTERVAL_S := 0.09
const WAKE_INTERVAL_S := 0.22
const COMBO_COLOR := Color(1.0, 0.85, 0.2)
const NEW_SPECIES_COLOR := Color(0.6, 1.0, 0.7)
const STORED_COLOR := Color(0.6, 0.9, 1.0)

## Tests switch this off to control exactly which fish exist.
@export var auto_spawn := true

var rng := RandomNumberGenerator.new()
var live_well := LiveWell.new(BACKPACK_CAPACITY)
var area: PlayArea

var _fish: Array[SwimmingFish] = []
var _art: Dictionary[String, FishArt] = {}
var _spawns := SpawnTable.new(PIER_SPAWNS)
var _spawn_timer := 0.0
var _holding := false
var _combo := 0
var _combo_timer := 0.0
var _unload_timer := 0.0
var _unloaded := 0
var _flying_to_tank := 0
var _wake_timer := 0.0
var _shake := 0.0
var _shown_money := 0.0
var _money_tween: Tween

@onready var wader: Wader = $World/Entities/Wader
@onready var store_zone: StoreZone = $World/StoreZone
@onready var _water: ColorRect = $Water
@onready var _world: Node2D = $World
@onready var _seabed: SeabedDecor = $World/Seabed
@onready var _entities: Node2D = $World/Entities
@onready var _effects: Node2D = $World/Effects
@onready var _popups: Control = $Popups
@onready var _money_label: Label = %MoneyLabel
@onready var _location_label: Label = %LocationLabel
@onready var _backpack_label: Label = %BackpackLabel
@onready var _backpack_bar: ProgressBar = %BackpackBar
@onready var _tank_label: Label = %TankLabel
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	rng.randomize()
	_world.scale = Vector2.ONE * ZOOM
	_location_label.text = LAYER_TITLE
	EventBus.money_changed.connect(_on_money_changed)
	resized.connect(_on_resized)
	_on_resized()
	_show_money(GameState.state.money)
	_update_hud()
	_populate.call_deferred()


func _process(delta: float) -> void:
	if area == null:
		return
	_update_shake(delta)
	wader.simulate(delta, area)
	_update_wake(delta)
	for fish in _fish:
		fish.simulate(delta, area, wader.ground_position, THREAT_RADIUS, _fish)
	_check_catches(delta)
	_combo_timer = maxf(_combo_timer - delta, 0.0)
	_update_storing(delta)

	if auto_spawn:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0 and _fish.size() < TARGET_POPULATION:
			_spawn_timer = SPAWN_INTERVAL_S
			_spawn_group(false)


## Tap to walk somewhere; hold and drag to steer.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index != 0:
			return
		_holding = touch.pressed
		if touch.pressed:
			wader.walk_to(scene_to_ground(touch.position))
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == 0 and _holding:
			wader.walk_to(scene_to_ground(drag.position))
			accept_event()


## Converts a position in this control (screen pixels) to ground coordinates.
func scene_to_ground(scene_position: Vector2) -> Vector2:
	return Iso.to_ground(_world.get_transform().affine_inverse() * scene_position)


## Converts ground coordinates to a position in this control (screen pixels).
func ground_to_scene(ground: Vector2) -> Vector2:
	return _world_to_scene(Iso.to_screen(ground))


## Adds one fish at a ground position. Public so tests can place fish precisely.
func spawn_fish(species_id: String, at: Vector2, heading: float) -> SwimmingFish:
	var fish := SwimmingFish.new()
	fish.setup(_art_for(species_id), at, heading)
	_entities.add_child(fish)
	_fish.append(fish)
	return fish


func fish_count() -> int:
	return _fish.size()


func _art_for(species_id: String) -> FishArt:
	if not _art.has(species_id):
		_art[species_id] = FishArt.for_species(DataRegistry.species[species_id])
	return _art[species_id]


## Converts a position in the (zoomed) world node to a position in this control.
func _world_to_scene(world_position: Vector2) -> Vector2:
	return _world.get_transform() * world_position


func _on_resized() -> void:
	if size.x <= 0.0:
		return
	# The play area, water and decoration work in unzoomed world pixels.
	var world_size := size / ZOOM
	var top := PLAY_MARGIN_TOP / ZOOM
	var visible_rect := Rect2(0.0, top, world_size.x, maxf(world_size.y - top - PLAY_MARGIN_BOTTOM / ZOOM, 200.0))
	area = PlayArea.new(visible_rect, SHORE_Y)
	var water := _water.material as ShaderMaterial
	water.set_shader_parameter("rect_size", world_size)
	water.set_shader_parameter("shore_y", SHORE_Y)
	_seabed.generate(area)
	# Ground point with the given ground y that appears at the given screen x.
	var zone_y := SHORE_Y + STORE_ZONE_SHORE_DISTANCE
	store_zone.place(Vector2(world_size.x * STORE_ZONE_SCREEN_X / Iso.BASIS.x.x + zone_y, zone_y))
	if wader.ground_position == Vector2.ZERO:
		wader.ground_position = area.center()
	wader.ground_position = area.clamp_point(wader.ground_position, 20.0)
	wader.position = Iso.to_screen(wader.ground_position)


#region Spawning

func _populate() -> void:
	if not auto_spawn or area == null:
		return
	while _fish.size() < TARGET_POPULATION:
		_spawn_group(true)


## Spawns a school (or a single big fish). Off-screen to the left or right unless `inside`
## is set, so new fish swim in from the sides.
func _spawn_group(inside: bool) -> void:
	var id := _spawns.pick(rng)
	var def := DataRegistry.species[id]
	var origin: Vector2
	if inside:
		origin = area.random_point(rng, 120.0)
	else:
		var rect := area.screen_rect
		var x := -80.0 if rng.randf() < 0.5 else rect.end.x + 80.0
		origin = Iso.to_ground(Vector2(x, rng.randf_range(rect.position.y + 200.0, rect.end.y - 80.0)))
		if origin.y < SHORE_Y + 100.0:
			return
	var heading := origin.direction_to(area.center()).angle() if not inside else rng.randf() * TAU
	var spread := CatchRules.body_length(def)
	for i in CatchRules.school_size(def, rng):
		var jitter := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * spread
		spawn_fish(id, origin + jitter, heading + rng.randf_range(-0.2, 0.2))

#endregion


#region Catching

func _check_catches(delta: float) -> void:
	var scoop := wader.scoop_center()
	var progress := 0.0
	# Iterate over a copy: catching removes fish from _fish.
	var candidates: Array[SwimmingFish] = _fish.duplicate()
	for fish in candidates:
		if fish.ground_position.distance_to(scoop) > Wader.SCOOP_RADIUS + fish.catch_radius():
			fish.hold_time = maxf(fish.hold_time - delta * HOLD_DECAY, 0.0)
			continue
		if live_well.is_full():
			fish.hold_time = 0.0
			continue
		fish.hold_time += delta
		var needed := CatchRules.struggle_seconds(fish.species)
		if fish.hold_time >= needed:
			_catch(fish)
		else:
			progress = maxf(progress, fish.hold_time / needed)
	wader.full = live_well.is_full()
	wader.struggle_progress = progress


func _catch(fish: SwimmingFish) -> void:
	_fish.erase(fish)
	live_well.add(fish.species.id)
	wader.add_to_stack(fish.art)
	var hoop := wader.hoop_screen_position()
	Juice.ripple(_effects, fish.position, fish.body_length * 0.5)
	Juice.splash(_effects, hoop, 8)
	fish.play_caught(hoop)
	# Bigger fish make a deeper sound.
	var pitch := clampf(1.6 - fish.species.length_cm / 60.0, 0.6, 1.5)
	Sfx.play(&"pop", pitch * rng.randf_range(0.95, 1.05))
	Haptics.tick()
	_bump(_backpack_bar)

	_combo = _combo + 1 if _combo_timer > 0.0 else 1
	_combo_timer = COMBO_WINDOW_S
	GameState.record_best("best_combo", _combo)
	if _combo >= 2:
		Juice.popup_text(_popups, _world_to_scene(wader.stack_top_position() + Vector2(0.0, -50.0)),
				CatchRules.combo_name(_combo), 56 + 6 * mini(_combo, 6), COMBO_COLOR)
		# One whole tone higher for every step of the combo.
		Sfx.play(&"ding", pow(2.0, (_combo - 2) * 2.0 / 12.0), -4.0)
		Haptics.bump()
		if _combo >= 4:
			_shake = 3.0 * mini(_combo, 8)

	if GameState.record_catch(fish.species.id):
		_announce_new_species(fish.species)
	_update_hud()


func _announce_new_species(def: SpeciesDef) -> void:
	Juice.popup_text(_popups, Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 140.0),
			"New species!\n" + def.common_name, 60, NEW_SPECIES_COLOR, 1.4)
	Sfx.play(&"ding", 1.5, -4.0)
	Haptics.bump()

#endregion


#region Storing

## While the wader stands on the store square, fish fly one by one from the backpack into
## the tank, with a rising pitch.
func _update_storing(delta: float) -> void:
	var on_square := store_zone.contains(wader.ground_position)
	store_zone.active = on_square
	store_zone.calling = live_well.is_full() and not on_square
	if not on_square or live_well.count() == 0:
		_unload_timer = 0.0
		if not on_square:
			_unloaded = 0
		return
	_unload_timer -= delta
	if _unload_timer > 0.0:
		return
	_unload_timer = UNLOAD_INTERVAL_S

	var from := _world_to_scene(wader.stack_top_position())
	var species_id := live_well.take_last()
	var art := wader.take_from_stack()
	_unloaded += 1
	_flying_to_tank += 1
	var to := _world_to_scene(store_zone.tank_screen_position())
	Juice.fly_fish(_popups, art, from, to, Wader.STACK_FISH_LENGTH * ZOOM, _on_fish_reached_tank.bind(species_id))
	Sfx.play(&"pop", 1.0 + _unloaded * 0.05, -6.0)
	_update_hud()


func _on_fish_reached_tank(species_id: String) -> void:
	GameState.store_fish(species_id)
	_flying_to_tank -= 1
	Juice.splash(_effects, store_zone.tank_screen_position(), 5)
	Sfx.play(&"splash", 1.4, -10.0)
	Haptics.tick()
	if _flying_to_tank == 0 and live_well.count() == 0:
		Juice.popup_text(_popups, _world_to_scene(store_zone.position + Vector2(0.0, -110.0)),
				"%d stored!" % _unloaded, 56, STORED_COLOR)
		Sfx.play(&"ding", 1.0, -4.0)
		Haptics.bump()
	_update_hud()

#endregion


#region Effects

## Little rings around the legs while wading.
func _update_wake(delta: float) -> void:
	if not wader.is_walking():
		_wake_timer = 0.0
		return
	_wake_timer -= delta
	if _wake_timer <= 0.0:
		_wake_timer = WAKE_INTERVAL_S
		Juice.ripple(_effects, wader.position + Vector2(0.0, Wader.WATERLINE_Y), 60.0)
		Sfx.play(&"splash", rng.randf_range(1.3, 1.6), -20.0)


func _update_shake(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 60.0, 0.0)
		_world.position = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * _shake
	elif _world.position != Vector2.ZERO:
		_world.position = Vector2.ZERO


func _bump(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 1.08
	create_tween().tween_property(control, "scale", Vector2.ONE, 0.12)

#endregion


#region HUD

func _update_hud() -> void:
	_backpack_label.text = "Backpack  %d / %d" % [live_well.count(), live_well.capacity]
	_backpack_bar.max_value = live_well.capacity
	_backpack_bar.value = live_well.count()
	var tank := GameState.state.tank_fish
	_tank_label.text = "Tank  %d fish · worth %s" % [tank.size(), NumberFormat.compact(GameState.catch_value(tank))]
	if live_well.is_full():
		_hint_label.text = "Backpack full! Walk onto the Store fish square."
	elif live_well.count() > 0:
		_hint_label.text = "Walk onto the Store fish square to unload."
	else:
		_hint_label.text = "Tap the water to wade there and catch fish."


func _on_money_changed(money: float) -> void:
	if _money_tween:
		_money_tween.kill()
	_money_tween = create_tween()
	_money_tween.tween_method(_show_money, _shown_money, money, 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _show_money(value: float) -> void:
	_shown_money = value
	_money_label.text = "Coins  " + NumberFormat.compact(value)

#endregion
