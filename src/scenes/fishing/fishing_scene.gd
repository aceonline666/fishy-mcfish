extends Control
## The North Sea spot, in isometric view: the sea at the bottom left, the beach aquarium at the
## top right, and a camera that follows the wader.
##
## The sea gets deeper further from the shore, in depth zones (data/zones.csv) marked by buoy
## lines; deeper zones need better diving gear and hold rarer fish. The wader scoops up fish into
## the backpack. On the beach, squares do things while the wader stands on them: store the catch
## in the tanks, sell it at the market, collect the coins visitors paid at the ticket booth, or
## pay towards new and bigger tanks, a bigger backpack and diving gear. Visitors come as long as
## the tanks have fish; grown fish bring in more.

const LOCATION_NAME := "North Sea"
## How much the world is magnified on screen.
const ZOOM := 1.5
const CAMERA_SMOOTHING := 6.0
## The camera may show this much (world pixels) beyond the spot's edges.
const CAMERA_OVERSCROLL := 120.0
## Screen pixels covered by the HUD bars at the top and bottom.
const PLAY_MARGIN_TOP := 170.0
const PLAY_MARGIN_BOTTOM := 330.0

#region Layout (ground units; the waterline is at y = 0, the beach at negative y)
## Reaches out to the end of the deepest zone (y = 1500).
const SPOT_RECT := Rect2(0.0, -700.0, 1250.0, 2200.0)
const SHORE_Y := 0.0
const DUNES_Y := -700.0
## Fish stay this far out in the water.
const WATER_MARGIN := 50.0
const SQUARE_HALF := 90.0
## Squares at the waterline.
const STORE_SQUARE := Vector2(330.0, -120.0)
const BACKPACK_SQUARE := Vector2(590.0, -120.0)
const MARKET_SQUARE := Vector2(850.0, -120.0)
const GEAR_SQUARE := Vector2(1110.0, -120.0)
const WRECK_POSITION := Vector2(640.0, 1260.0)
## The tank row, with a build or upgrade square in front of each tank slot.
const TANK_ROW_Y := -520.0
const TANK_FIRST_X := 380.0
const TANK_SPACING := 240.0
const TANK_SQUARE_OFFSET := Vector2(0.0, 175.0)
## Ticket booth and its cash pile, left of the tanks.
const BOOTH_POSITION := Vector2(90.0, -560.0)
const CASH_SQUARE := Vector2(110.0, -330.0)
const VISITOR_ENTRANCE := Vector2(-250.0, -700.0)
const VISITOR_PAY_SPOT := Vector2(180.0, -470.0)
const VISITOR_EXIT := Vector2(1450.0, -700.0)
## Visitors stand this far in front of the tank they look at.
const VISITOR_VIEW_OFFSET := Vector2(0.0, 110.0)
#endregion

const SPAWN_INTERVAL_S := 0.8
## Fish startle when the wader comes this close (ground units). Smaller than the net's reach
## (Wader.REACH + SCOOP_RADIUS), so walking straight at fish catches them.
const THREAT_RADIUS := 130.0
## How much faster an interrupted struggle drains than it builds up.
const HOLD_DECAY := 2.0
## Catches less than this far apart continue the combo.
const COMBO_WINDOW_S := 1.3
## Seconds between fish handled on the store and market squares.
const UNLOAD_INTERVAL_S := 0.09
## Seconds between payments on a build square; each pays this share of the price.
const PAY_INTERVAL_S := 0.05
const PAY_SHARE := 0.04
const MAX_VISITORS := 6
const VISITOR_INTERVAL_S := 2.5
const WAKE_INTERVAL_S := 0.22
const COMBO_COLOR := Color(1.0, 0.85, 0.2)
const NEW_SPECIES_COLOR := Color(0.6, 1.0, 0.7)
const STORED_COLOR := Color(0.6, 0.9, 1.0)
const COIN_COLOR := Color(1.0, 0.86, 0.3)
const WARNING_COLOR := Color(1.0, 0.55, 0.45)

## Tests switch this off to control exactly which fish and visitors exist.
@export var auto_spawn := true

var rng := RandomNumberGenerator.new()
var live_well := LiveWell.new(10)
var water_area := PlayArea.new(Rect2(SPOT_RECT.position.x, SHORE_Y + WATER_MARGIN, SPOT_RECT.size.x, SPOT_RECT.end.y - SHORE_Y - WATER_MARGIN))
## Where the wader may go: the beach and the zones the gear allows. Updated with the gear.
var walk_area := PlayArea.new(SPOT_RECT)

var _fish: Array[SwimmingFish] = []
var _art: Dictionary[String, FishArt] = {}
## Per depth zone (same order as DataRegistry.zones): the water its fish keep to, and spawns.
var _zone_areas: Array[PlayArea] = []
var _zone_spawns: Array[SpawnTable] = []
var _spawn_timer := 0.0
var _wader_zone: ZoneDef
var _gate_warned := false
var _squares: Array[ActionSquare] = []
var _slot_squares: Array[ActionSquare] = []
var _tank_nodes: Dictionary[int, TankNode] = {}
var _visitors: Array[Visitor] = []
var _visitor_timer := 1.0
var _holding := false
var _combo := 0
var _combo_timer := 0.0
var _current_square: ActionSquare
var _action_timer := 0.0
var _action_count := 0
var _action_total := 0.0
var _warned := false
## After a purchase the square turns into the next offer; it only takes coins again once the
## wader has stepped off and back on.
var _purchase_done := false
var _wake_timer := 0.0
var _shake := 0.0
var _camera := Vector2.ZERO
var _shown_money := 0.0
var _money_tween: Tween

@onready var wader: Wader = $World/Entities/Wader
@onready var _water: ColorRect = $Water
@onready var _world: Node2D = $World
@onready var _seabed: SeabedDecor = $World/Seabed
@onready var _buoys: ZoneBuoys = $World/Buoys
@onready var _squares_layer: Node2D = $World/Squares
@onready var _entities: Node2D = $World/Entities
@onready var _booth: TicketBooth = $World/Entities/TicketBooth
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
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.state_replaced.connect(_rebuild_from_state)
	resized.connect(_update_camera.bind(0.0, true))

	for zone in DataRegistry.zones:
		var top := maxf(zone.depth_start, SHORE_Y + WATER_MARGIN)
		_zone_areas.append(PlayArea.new(Rect2(SPOT_RECT.position.x, top, SPOT_RECT.size.x, zone.depth_end - top)))
		_zone_spawns.append(SpawnTable.new(zone.spawns))
	_seabed.generate(water_area)
	_seabed.add_wreck(WRECK_POSITION)
	_booth.position = Iso.to_screen(BOOTH_POSITION)
	_build_squares()
	_rebuild_from_state()
	wader.ground_position = STORE_SQUARE + Vector2(0.0, 260.0)
	wader.position = Iso.to_screen(wader.ground_position)
	_update_camera(0.0, true)
	_show_money(GameState.state.money)
	_populate.call_deferred()
	_show_offline_earnings.call_deferred()


func _process(delta: float) -> void:
	_update_shake(delta)
	wader.simulate(delta, walk_area)
	wader.in_water = wader.ground_position.y > SHORE_Y
	_update_zone()
	_update_camera(delta)
	_update_wake(delta)
	for fish in _fish:
		fish.simulate(delta, wader.ground_position, THREAT_RADIUS, _fish)
	_check_catches(delta)
	_combo_timer = maxf(_combo_timer - delta, 0.0)
	_update_squares(delta)
	_update_visitors(delta)

	if auto_spawn:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = SPAWN_INTERVAL_S
			_refill_zones()


## Tap to walk somewhere; hold and drag to steer.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index != 0:
			return
		_holding = touch.pressed
		if touch.pressed:
			_gate_warned = false
			_walk_to(scene_to_ground(touch.position))
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == 0 and _holding:
			_walk_to(scene_to_ground(drag.position))
			accept_event()


## Sends the wader towards a ground point; explains once if better gear is needed to get there.
func _walk_to(target: Vector2) -> void:
	wader.walk_to(target)
	if target.y > walk_area.rect.end.y and not _gate_warned:
		_gate_warned = true
		var next_gear := GameState.state.gear_level
		if next_gear < DataRegistry.gear_levels.size():
			_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 330.0),
					"Get the %s on the beach\nto swim further out!" % DataRegistry.gear_levels[next_gear].name, WARNING_COLOR, 1.2)
			Haptics.bump()


#region Public helpers (also used by tests)

## Adds one fish at a ground position. It lives in the zone at that depth (the nearest zone
## if the point is outside all of them).
func spawn_fish(species_id: String, at: Vector2, heading: float) -> SwimmingFish:
	var zone_index := DataRegistry.zones.size() - 1
	for i in DataRegistry.zones.size():
		if at.y < DataRegistry.zones[i].depth_end:
			zone_index = i
			break
	return _spawn_fish_in(zone_index, species_id, at, heading)


func _spawn_fish_in(zone_index: int, species_id: String, at: Vector2, heading: float) -> SwimmingFish:
	var fish := SwimmingFish.new()
	fish.setup(_art_for(species_id), DataRegistry.zones[zone_index], _zone_areas[zone_index], at, heading)
	_entities.add_child(fish)
	_fish.append(fish)
	return fish


func fish_count() -> int:
	return _fish.size()


func visitor_count() -> int:
	return _visitors.size()


func square(square_id: String) -> ActionSquare:
	for s in _squares:
		if s.id == square_id and s.visible:
			return s
	return null


## Converts a position in this control (screen pixels) to ground coordinates.
func scene_to_ground(scene_position: Vector2) -> Vector2:
	return Iso.to_ground(_world.get_transform().affine_inverse() * scene_position)


## Converts ground coordinates to a position in this control (screen pixels).
func ground_to_scene(ground: Vector2) -> Vector2:
	return _world_to_scene(Iso.to_screen(ground))

#endregion


func _art_for(species_id: String) -> FishArt:
	if not _art.has(species_id):
		_art[species_id] = FishArt.for_species(DataRegistry.species[species_id])
	return _art[species_id]


## Converts a position in the (zoomed, scrolled) world node to a position in this control.
func _world_to_scene(world_position: Vector2) -> Vector2:
	return _world.get_transform() * world_position


func _tank_slot_position(slot: int) -> Vector2:
	return Vector2(TANK_FIRST_X + TANK_SPACING * slot, TANK_ROW_Y)


## Recreates everything that mirrors the saved state: tanks, squares, backpack size, gear.
func _rebuild_from_state() -> void:
	var state := GameState.state
	for node: TankNode in _tank_nodes.values():
		node.queue_free()
	_tank_nodes.clear()
	for tank in state.tanks:
		_add_tank_node(tank)
	live_well.capacity = Aquarium.backpack_capacity(state)
	_apply_gear()
	_refresh_squares()
	_update_hud()


## Opens the zones the gear allows and updates the buoys and the wader's look.
func _apply_gear() -> void:
	var gear := GameState.state.gear_level
	var deepest := Charting.deepest_open_zone(gear)
	walk_area = PlayArea.new(Rect2(SPOT_RECT.position, Vector2(SPOT_RECT.size.x, deepest.depth_end - SPOT_RECT.position.y)))
	wader.gear_level = gear
	var lines: Array[Vector2] = []
	for i in range(1, DataRegistry.zones.size()):
		var zone := DataRegistry.zones[i]
		lines.append(Vector2(zone.depth_start, 1.0 if zone.gear_level <= gear else 0.0))
	_buoys.setup(lines, SPOT_RECT.size.x)


## Tracks which zone the wader is in; announces zones on entry.
func _update_zone() -> void:
	var zone := Charting.zone_at(wader.ground_position.y) if wader.in_water else null
	wader.swimming = zone != null and zone.order > 1
	if zone == _wader_zone:
		return
	_wader_zone = zone
	_location_label.text = "%s · %s" % [LOCATION_NAME, zone.name if zone != null else "Beach"]
	if zone != null:
		_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 120.0),
				"%s\n%s" % [zone.name, Charting.progress_text(GameState.state, zone)], STORED_COLOR, 0.8)


func _add_tank_node(tank: TankState) -> TankNode:
	var node := TankNode.new()
	node.setup(tank, _tank_slot_position(tank.slot), _art_for)
	_entities.add_child(node)
	_tank_nodes[tank.slot] = node
	return node


func _show_offline_earnings() -> void:
	if GameState.last_offline_earned >= 1.0:
		Juice.popup_text(_popups, Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 160.0),
				"While you were away:\n+%s coins at the booth" % NumberFormat.compact(GameState.last_offline_earned),
				52, COIN_COLOR, 2.5)
		GameState.last_offline_earned = 0.0


#region Camera

## Follows the wader, keeping the view over the spot.
func _update_camera(delta: float, snap: bool = false) -> void:
	if size.x <= 0.0:
		return
	var focus := Iso.to_screen(wader.ground_position) + Vector2(0.0, -60.0)
	var view_center := Vector2(size.x * 0.5, (PLAY_MARGIN_TOP + size.y - PLAY_MARGIN_BOTTOM) * 0.5)
	var target := view_center - focus * ZOOM

	var bounds := Rect2(Iso.to_screen(SPOT_RECT.position), Vector2.ZERO)
	for corner: Vector2 in [Vector2(SPOT_RECT.end.x, SPOT_RECT.position.y), SPOT_RECT.end, Vector2(SPOT_RECT.position.x, SPOT_RECT.end.y)]:
		bounds = bounds.expand(Iso.to_screen(corner))
	bounds = bounds.grow(CAMERA_OVERSCROLL)
	target.x = _clamp_axis(target.x, size.x - bounds.end.x * ZOOM, -bounds.position.x * ZOOM)
	target.y = _clamp_axis(target.y, size.y - PLAY_MARGIN_BOTTOM - bounds.end.y * ZOOM, PLAY_MARGIN_TOP - bounds.position.y * ZOOM)

	_camera = target if snap else _camera.lerp(target, 1.0 - exp(-CAMERA_SMOOTHING * delta))
	_apply_world_position()


## Clamps a camera offset; centres it if the spot is smaller than the view on this axis.
func _clamp_axis(value: float, low: float, high: float) -> float:
	return clampf(value, low, high) if low <= high else (low + high) * 0.5


func _apply_world_position() -> void:
	var shake := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * _shake if _shake > 0.0 else Vector2.ZERO
	_world.position = _camera + shake
	var water := _water.material as ShaderMaterial
	water.set_shader_parameter("rect_size", size)
	water.set_shader_parameter("world_origin", _world.position)
	water.set_shader_parameter("zoom", ZOOM)
	water.set_shader_parameter("shore_y", SHORE_Y)
	water.set_shader_parameter("dunes_y", DUNES_Y)

#endregion


#region Spawning

func _populate() -> void:
	if not auto_spawn:
		return
	for i in DataRegistry.zones.size():
		while _zone_fish_count(i) < DataRegistry.zones[i].population:
			_spawn_group(i, true)


## Tops up one zone that is short of fish, swimming in from the side.
func _refill_zones() -> void:
	for i in DataRegistry.zones.size():
		if _zone_fish_count(i) < DataRegistry.zones[i].population:
			_spawn_group(i, false)
			return


func _zone_fish_count(zone_index: int) -> int:
	var zone := DataRegistry.zones[zone_index]
	return _fish.filter(func(f: SwimmingFish) -> bool: return f.zone == zone).size()


## Spawns a school (or a single big fish) in a zone. Beyond the left or right edge of the
## zone unless `inside` is set, so new fish swim in.
func _spawn_group(zone_index: int, inside: bool) -> void:
	var area := _zone_areas[zone_index]
	var id := _zone_spawns[zone_index].pick(rng)
	var def := DataRegistry.species[id]
	var rect := area.rect
	var origin: Vector2
	var heading: float
	if inside:
		origin = area.random_point(rng, 60.0)
		heading = rng.randf() * TAU
	else:
		var from_left := rng.randf() < 0.5
		origin = Vector2(rect.position.x - 150.0 if from_left else rect.end.x + 150.0,
				rng.randf_range(rect.position.y + 40.0, rect.end.y - 40.0))
		heading = origin.direction_to(area.center()).angle()
	var spread := CatchRules.body_length(def)
	for i in CatchRules.school_size(def, rng):
		var jitter := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * spread
		_spawn_fish_in(zone_index, id, origin + jitter, heading + rng.randf_range(-0.2, 0.2))

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

	var was_charted := Charting.is_charted(GameState.state, fish.zone)
	if GameState.record_catch(fish.species.id, fish.zone.id):
		_announce(_world_to_scene(wader.stack_top_position() + Vector2(0.0, -110.0)),
				"New species!\n" + fish.species.common_name, NEW_SPECIES_COLOR, 1.4)
		Sfx.play(&"ding", 1.5, -4.0)
		Haptics.bump()
	if not was_charted and Charting.is_charted(GameState.state, fish.zone):
		_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 220.0), "%s charted!" % fish.zone.name, COMBO_COLOR, 1.6)
		Sfx.play(&"ding", 1.0)
		Sfx.play(&"ding", 1.26, -4.0)
	_update_hud()

#endregion


#region Squares

func _build_squares() -> void:
	_add_square("store", ActionSquare.Kind.STORE, "Store fish", STORE_SQUARE)
	_add_square("market", ActionSquare.Kind.MARKET, "Fish market", MARKET_SQUARE)
	_add_square("cash", ActionSquare.Kind.CASH, "Collect coins", CASH_SQUARE)
	_add_square("upgrade_backpack", ActionSquare.Kind.BUY, "Bigger backpack", BACKPACK_SQUARE)
	_add_square("upgrade_gear", ActionSquare.Kind.BUY, "", GEAR_SQUARE)
	for slot in DataRegistry.tank_slots.size():
		_slot_squares.append(_add_square("", ActionSquare.Kind.BUY, "", _tank_slot_position(slot) + TANK_SQUARE_OFFSET))


func _add_square(square_id: String, kind: ActionSquare.Kind, title: String, center: Vector2) -> ActionSquare:
	var new_square := ActionSquare.new()
	new_square.setup(square_id, kind, title, center, SQUARE_HALF)
	_squares_layer.add_child(new_square)
	_squares.append(new_square)
	return new_square


## Updates the purchase squares: one upgrade square per built tank, a build square for the next
## free slot, the backpack upgrade. Squares with nothing left to buy are hidden.
func _refresh_squares() -> void:
	var state := GameState.state
	for slot in _slot_squares.size():
		var slot_square := _slot_squares[slot]
		var tank := state.tank_in_slot(slot)
		if tank != null:
			_set_purchase(slot_square, "upgrade_tank_%d" % slot, "Bigger tank", Aquarium.tank_upgrade_cost(tank))
		elif slot == state.tanks.size():
			_set_purchase(slot_square, "build_tank", "Build tank", Aquarium.next_tank_cost(state))
		else:
			slot_square.hide()
	var backpack := square_by_id("upgrade_backpack")
	_set_purchase(backpack, "upgrade_backpack", "Bigger backpack", Aquarium.backpack_upgrade_cost(state))
	var gear := square_by_id("upgrade_gear")
	var next_gear := DataRegistry.gear_levels[mini(state.gear_level, DataRegistry.gear_levels.size() - 1)]
	_set_purchase(gear, "upgrade_gear", next_gear.name, Aquarium.gear_upgrade_cost(state))


func _set_purchase(target: ActionSquare, square_id: String, title: String, price: float) -> void:
	target.id = square_id
	target.title = title
	target.price = price
	target.paid = GameState.state.build_progress.get(square_id, 0.0)
	target.visible = price >= 0.0


## Finds a square by id even while it is hidden.
func square_by_id(square_id: String) -> ActionSquare:
	for s in _squares:
		if s.id == square_id:
			return s
	return null


## The visible square the wader stands on; the nearest one if squares overlap.
func _square_under_wader() -> ActionSquare:
	var best: ActionSquare = null
	for s in _squares:
		if s.visible and s.contains(wader.ground_position):
			if best == null or s.ground_center.distance_to(wader.ground_position) < best.ground_center.distance_to(wader.ground_position):
				best = s
	return best


func _update_squares(delta: float) -> void:
	var on := _square_under_wader()
	for s in _squares:
		s.active = s == on
	square_by_id("store").calling = live_well.is_full()
	var cash := square_by_id("cash")
	cash.amount = GameState.state.cash_pile
	cash.calling = GameState.state.cash_pile >= 1.0

	if on != _current_square:
		_finish_square_action()
		_current_square = on
		_action_timer = 0.0
		_action_count = 0
		_action_total = 0.0
		_warned = false
		_purchase_done = false
	if on == null or _purchase_done:
		return
	_action_timer -= delta
	if _action_timer > 0.0:
		return
	match on.kind:
		ActionSquare.Kind.STORE:
			_action_timer = UNLOAD_INTERVAL_S
			_store_one()
		ActionSquare.Kind.MARKET:
			_action_timer = UNLOAD_INTERVAL_S
			_sell_one()
		ActionSquare.Kind.CASH:
			_action_timer = 0.3
			_collect_cash()
		ActionSquare.Kind.BUY:
			_action_timer = PAY_INTERVAL_S
			_pay_into(on)


## Shows the total of what just happened on a square, once.
func _finish_square_action() -> void:
	if _current_square == null or _action_count == 0:
		return
	var at := _world_to_scene(_current_square.position + Vector2(0.0, -110.0))
	match _current_square.kind:
		ActionSquare.Kind.STORE:
			_announce(at, "%d stored!" % _action_count, STORED_COLOR)
		ActionSquare.Kind.MARKET:
			_announce(at, "+%s coins" % NumberFormat.compact(_action_total), COIN_COLOR)
	_action_count = 0
	_action_total = 0.0


## Moves the topmost fish that fits into a tank, flying it into that tank.
func _store_one() -> void:
	var state := GameState.state
	var index := -1
	for i in range(live_well.count() - 1, -1, -1):
		if Aquarium.tank_for(state, DataRegistry.species[live_well.species_ids[i]]) != null:
			index = i
			break
	if index < 0:
		_finish_square_action()
		if live_well.count() > 0 and not _warned:
			_warned = true
			_announce(_world_to_scene(square_by_id("store").position + Vector2(0.0, -110.0)),
					"No room in the tanks!\nBuild or upgrade a tank.", WARNING_COLOR, 1.2)
			Haptics.bump()
		return
	var species_id := live_well.take_at(index)
	var art := wader.take_from_stack_at(index)
	var from := _world_to_scene(wader.stack_top_position())
	var tank := GameState.store_fish(species_id)
	var node := _tank_nodes[tank.slot]
	_action_count += 1
	Juice.fly_fish(_popups, art, from, _world_to_scene(node.drop_point()), Wader.STACK_FISH_LENGTH * ZOOM,
			_on_fish_reached_tank.bind(node))
	Sfx.play(&"pop", 1.0 + _action_count * 0.05, -6.0)
	if live_well.count() == 0:
		_finish_square_action()
	_update_hud()


func _on_fish_reached_tank(node: TankNode) -> void:
	if not is_instance_valid(node):
		return
	Juice.splash(_effects, node.drop_point(), 5)
	node.bounce()
	Sfx.play(&"splash", 1.4, -10.0)
	Haptics.tick()


## Sells the top fish of the backpack.
func _sell_one() -> void:
	if live_well.count() == 0:
		_finish_square_action()
		return
	var species_id := live_well.take_last()
	wader.take_from_stack()
	var price := GameState.sell_fish(species_id)
	_action_count += 1
	_action_total += price
	var market := square_by_id("market")
	Juice.fly_coin(_popups, _world_to_scene(wader.stack_top_position()), _world_to_scene(market.position), 12.0 * ZOOM)
	Sfx.play(&"coin", 1.0 + _action_count * 0.04, -4.0)
	if live_well.count() == 0:
		_finish_square_action()
	_update_hud()


func _collect_cash() -> void:
	var amount := GameState.collect_cash()
	if amount < 1.0:
		return
	var at := _world_to_scene(square_by_id("cash").position)
	_announce(at + Vector2(0.0, -110.0), "+%s coins" % NumberFormat.compact(amount), COIN_COLOR)
	for i in mini(int(log(amount + 1.0) / log(2.0)) + 2, 10):
		get_tree().create_timer(i * 0.05).timeout.connect(Sfx.play.bind(&"coin", 1.0 + i * 0.05, -2.0))
	Haptics.bump()


## Pays a slice of the price; completes the purchase once fully paid.
func _pay_into(target: ActionSquare) -> void:
	if GameState.state.money < 0.01:
		if not _warned:
			_warned = true
			_announce(_world_to_scene(target.position + Vector2(0.0, -110.0)), "Not enough coins", WARNING_COLOR, 0.6)
		return
	var before := GameState.state.money
	var done := GameState.pay_into(target.id, maxf(target.price * PAY_SHARE, 1.0), target.price)
	if GameState.state.money < before:
		Juice.fly_coin(_popups, _world_to_scene(wader.position + Vector2(0.0, -120.0)), _world_to_scene(target.position), 10.0 * ZOOM)
		_action_count += 1
		Sfx.play(&"coin", 0.9 + minf(_action_count, 25) * 0.02, -10.0)
	target.paid = GameState.state.build_progress.get(target.id, 0.0)
	if done:
		_complete_purchase(target)


func _complete_purchase(target: ActionSquare) -> void:
	var state := GameState.state
	var at := _world_to_scene(target.position + Vector2(0.0, -130.0))
	var message := ""
	if target.id == "build_tank":
		var tank := GameState.build_next_tank()
		_add_tank_node(tank).bounce()
		message = "New tank!"
	elif target.id == "upgrade_backpack":
		GameState.upgrade_backpack()
		live_well.capacity = Aquarium.backpack_capacity(state)
		message = "Bigger backpack!\n%d fish" % live_well.capacity
	elif target.id == "upgrade_gear":
		GameState.upgrade_gear()
		_apply_gear()
		var zone := Charting.deepest_open_zone(state.gear_level)
		message = "%s!\nYou can now reach the %s" % [DataRegistry.gear_levels[state.gear_level - 1].name, zone.name]
	elif target.id.begins_with("upgrade_tank_"):
		var tank := state.tank_in_slot(target.id.trim_prefix("upgrade_tank_").to_int())
		GameState.upgrade_tank(tank)
		_tank_nodes[tank.slot].bounce()
		message = "%s!\n%s L" % [DataRegistry.tank_levels[tank.level - 1].name, NumberFormat.compact(Aquarium.capacity(tank))]
	_announce(at, message, COMBO_COLOR, 1.0)
	Sfx.play(&"ding", 1.0)
	Sfx.play(&"ding", 1.5, -6.0)
	Juice.splash(_effects, target.position, 18)
	Haptics.bump()
	_shake = 10.0
	_action_count = 0
	_purchase_done = true
	_refresh_squares()
	_update_hud()
	SaveSystem.save_game()

#endregion


#region Visitors

func _update_visitors(delta: float) -> void:
	var walking: Array[Visitor] = _visitors.duplicate()
	for visitor in walking:
		if not visitor.simulate(delta):
			_visitors.erase(visitor)
	if not auto_spawn:
		return
	_visitor_timer -= delta
	if _visitor_timer > 0.0 or _visitors.size() >= MAX_VISITORS or GameState.state.pending_income < 1.0:
		return
	_visitor_timer = VISITOR_INTERVAL_S
	spawn_visitor()


## Sends a visitor with the income earned so far: to the booth, then to a tank with fish.
func spawn_visitor() -> Visitor:
	var tank := GameState.state.tanks[0]
	var tanks_with_fish := GameState.state.tanks.filter(func(t: TankState) -> bool: return not t.fish.is_empty())
	if not tanks_with_fish.is_empty():
		tank = tanks_with_fish[rng.randi() % tanks_with_fish.size()]
	var view_spot := _tank_slot_position(tank.slot) + VISITOR_VIEW_OFFSET + Vector2(rng.randf_range(-50.0, 50.0), 0.0)
	var path: Array[Vector2] = [VISITOR_ENTRANCE, VISITOR_PAY_SPOT, view_spot, VISITOR_EXIT]
	var visitor := Visitor.new()
	visitor.setup(path, 1, 2, GameState.take_pending_income(), rng)
	visitor.arrived.connect(_on_visitor_arrived)
	_entities.add_child(visitor)
	_visitors.append(visitor)
	return visitor


func _on_visitor_arrived(visitor: Visitor, waypoint: int) -> void:
	if waypoint != visitor.pay_at or visitor.amount <= 0.0:
		return
	GameState.add_to_cash_pile(visitor.amount)
	Juice.fly_coin(_popups, _world_to_scene(visitor.position + Vector2(0.0, -90.0)), _world_to_scene(square_by_id("cash").position), 9.0 * ZOOM)
	Sfx.play(&"coin", 1.3, -12.0)

#endregion


#region Effects

func _announce(at: Vector2, text: String, color: Color, hold_s: float = 0.35) -> void:
	Juice.popup_text(_popups, at, text, 52, color, hold_s)


## Little rings around the legs while wading.
func _update_wake(delta: float) -> void:
	if not wader.is_walking() or not wader.in_water:
		_wake_timer = 0.0
		return
	_wake_timer -= delta
	if _wake_timer <= 0.0:
		_wake_timer = WAKE_INTERVAL_S
		Juice.ripple(_effects, wader.position + Vector2(0.0, Wader.WATERLINE_Y), 60.0)
		Sfx.play(&"splash", rng.randf_range(1.3, 1.6), -20.0)


func _update_shake(delta: float) -> void:
	_shake = maxf(_shake - delta * 60.0, 0.0)


func _bump(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 1.08
	create_tween().tween_property(control, "scale", Vector2.ONE, 0.12)

#endregion


#region HUD

func _update_hud() -> void:
	var state := GameState.state
	_backpack_label.text = "Backpack  %d / %d" % [live_well.count(), live_well.capacity]
	_backpack_bar.max_value = live_well.capacity
	_backpack_bar.value = live_well.count()
	var used := 0.0
	var capacity := 0.0
	for tank in state.tanks:
		used += Aquarium.used_space(tank)
		capacity += Aquarium.capacity(tank)
	_tank_label.text = "Tanks  %s / %s L  ·  +%s coins/min" % [
		NumberFormat.compact(used), NumberFormat.compact(capacity), NumberFormat.compact(Aquarium.income_rate(state) * 60.0)]
	if live_well.is_full():
		_hint_label.text = "Backpack full! Store the fish in a tank or sell them at the market."
	elif live_well.count() > 0:
		_hint_label.text = "Walk up the beach to store your catch."
	elif state.cash_pile >= 1.0:
		_hint_label.text = "Visitors left coins at the ticket booth. Go collect them!"
	else:
		_hint_label.text = "Tap the water to wade there and catch fish."


func _on_money_changed(money: float) -> void:
	if _money_tween:
		_money_tween.kill()
	_money_tween = create_tween()
	_money_tween.tween_method(_show_money, _shown_money, money, 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_update_hud()


func _show_money(value: float) -> void:
	_shown_money = value
	_money_label.text = "Coins  " + NumberFormat.compact(value)

#endregion
