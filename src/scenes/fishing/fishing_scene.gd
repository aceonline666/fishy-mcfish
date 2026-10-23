extends Control
## A fishing spot (the player's current location), in isometric view: the sea at the bottom
## left, the beach at the top right, and a camera that follows the wader.
##
## The sea gets deeper further from the shore, in depth zones (data/zones.csv) marked by buoy
## lines; deeper zones need better diving gear and hold rarer fish. The wader scoops up fish into
## the backpack. On the beach, squares do things while the wader stands on them. At home the
## beach holds the business, in rows: squares at the waterline (store the catch, backpack, net,
## diving gear, drones), the tanks, the fish shops with their "Sell fish" squares (backpack first,
## then the most valuable fish from the tanks), and the tropical tanks. Hired sellers sell grown
## fish on their own. Away from home there is only a dock that ships the catch home or sells it.
## The World map travels between locations.

## The spot must be rebuilt: after travelling, loading or starting a new game.
signal rebuild_requested

## How much the world is magnified on screen.
const ZOOM := 1.5
const CAMERA_SMOOTHING := 6.0
## The camera may show this much (world pixels) beyond the spot's edges.
const CAMERA_OVERSCROLL := 120.0
## Screen pixels covered by the HUD bars at the top and bottom.
const PLAY_MARGIN_TOP := 270.0
const PLAY_MARGIN_BOTTOM := 330.0

#region Layout (ground units; the waterline is at y = 0, the beach at negative y)
## Reaches out to the end of the deepest zone (y = 1500). Home has a wide, deep beach for the
## business, laid out on a grid of five columns; other locations only a dock. Pads keep clear
## gaps so the wader does not step onto the wrong one by accident.
const HOME_SPOT_RECT := Rect2(0.0, -2200.0, 2100.0, 3700.0)
const AWAY_SPOT_RECT := Rect2(0.0, -400.0, 1500.0, 1900.0)
const SHORE_Y := 0.0
## Fish stay this far out in the water.
const WATER_MARGIN := 50.0
## Zone populations in the data are meant for a spot this wide; wider spots get more fish.
const POPULATION_WIDTH := 1500.0
## Half the length (along the row) and depth of the pads.
const SQUARE_HALF := Vector2(180.0, 110.0)
## The grid columns at home: pads, tanks and shops line up in them.
const COLUMN_FIRST_X := 230.0
const COLUMN_SPACING := 410.0
## Pads at the waterline. Drones start from and deliver to their pad.
const FRONT_ROW_Y := -200.0
const DRONE_PAD := Vector2(COLUMN_FIRST_X, FRONT_ROW_Y)
const STORE_SQUARE := Vector2(COLUMN_FIRST_X + COLUMN_SPACING, FRONT_ROW_Y)
const BACKPACK_SQUARE := Vector2(COLUMN_FIRST_X + COLUMN_SPACING * 2.0, FRONT_ROW_Y)
const NET_SQUARE := Vector2(COLUMN_FIRST_X + COLUMN_SPACING * 3.0, FRONT_ROW_Y)
const GEAR_SQUARE := Vector2(COLUMN_FIRST_X + COLUMN_SPACING * 4.0, FRONT_ROW_Y)
## Away from home: the dock ships the catch to the tanks at home, or sells it.
const SHIP_SQUARE := Vector2(450.0, FRONT_ROW_Y)
const DOCK_SELL_SQUARE := Vector2(1000.0, FRONT_ROW_Y)
const WRECK_LOCATION := "north_sea"
const WRECK_POSITION := Vector2(1000.0, 1260.0)
## The tank rows (temperate first, tropical behind the shops), with a build or upgrade pad in
## front of each tank slot.
const TANK_ROW_Y: Dictionary[String, float] = {"temperate": -800.0, "tropical": -1960.0}
const TANK_SQUARE_OFFSET := Vector2(0.0, 240.0)
## The shop row behind the first tanks, each shop with its "Sell fish" pad in front, and the
## pad to hire sellers in the next column.
const SHOP_ROW_Y := -1370.0
const SHOP_SQUARE_OFFSET := Vector2(0.0, 220.0)
const HIRE_SQUARE := Vector2(COLUMN_FIRST_X + COLUMN_SPACING * 3.0, SHOP_ROW_Y + 220.0)
#endregion

const SPAWN_INTERVAL_S := 0.8
## Fish startle when the wader comes this close (ground units). Smaller than the net's reach
## (Wader.REACH + scoop radius), so walking straight at fish catches them.
const THREAT_RADIUS := 130.0
## How much faster an interrupted struggle drains than it builds up.
const HOLD_DECAY := 2.0
## Catches less than this far apart continue the combo.
const COMBO_WINDOW_S := 1.3
## Seconds between fish stored on the store square, and sold on a "Sell fish" square.
const UNLOAD_INTERVAL_S := 0.09
const SELL_INTERVAL_S := 0.3
## Walking on sand is faster than wading.
const BEACH_SPEED := 1.5
## Each further drone is this much bigger than the first; it carries more and bigger fish.
const DRONE_SIZE_STEP := 0.3
const LANGUAGE_FLAGS: Dictionary[String, Texture2D] = {
	"en": preload("res://assets/ui/flag_us.svg"),
	"de": preload("res://assets/ui/flag_de.svg"),
}
## Each better net is this much wider.
const NET_RADIUS_STEP := 0.12
## Seconds between payments on a build square; each pays this share of the price.
const PAY_INTERVAL_S := 0.05
const PAY_SHARE := 0.04
## Seconds between banners when several goals are reached at once.
const GOAL_BANNER_SPACING_S := 2.0
## Fish per second a drone working at another location brings home.
const AWAY_DRONE_FISH_PER_SECOND := 0.2
const WAKE_INTERVAL_S := 0.22
const COMBO_COLOR := Color(1.0, 0.85, 0.2)
const NEW_SPECIES_COLOR := Color(0.6, 1.0, 0.7)
const STORED_COLOR := Color(0.6, 0.9, 1.0)
const COIN_COLOR := Color(1.0, 0.86, 0.3)
const WARNING_COLOR := Color(1.0, 0.55, 0.45)

## Tests switch this off to control exactly which fish exist.
@export var auto_spawn := true

var rng := RandomNumberGenerator.new()
var live_well := LiveWell.new(10)
## Where the player is, and whether that is home (with the aquarium).
var location: LocationDef
var is_home := true
var water_area: PlayArea
## Where the wader may go: the beach and the zones the gear allows. Updated with the gear.
var walk_area: PlayArea

var _spot_rect := HOME_SPOT_RECT
var _fish: Array[SwimmingFish] = []
var _art: Dictionary[String, FishArt] = {}
## The location's depth zones, and per zone the water its fish keep to and the spawns.
var _zones: Array[ZoneDef] = []
var _zone_areas: Array[PlayArea] = []
var _zone_spawns: Array[SpawnTable] = []
var _spawn_timer := 0.0
var _wader_zone: ZoneDef
var _gate_warned := false
var _squares: Array[ActionSquare] = []
var _slot_squares: Array[ActionSquare] = []
var _tank_nodes: Dictionary[int, TankNode] = {}
## One square per shop slot: "Sell fish" for built shops, "Build shop" for the next one.
var _shop_squares: Array[ActionSquare] = []
var _shop_nodes: Array[ShopNode] = []
var _drones: Array[Drone] = []
## Per drone working at another location: progress towards its next fish.
var _away_drone_progress := PackedFloat32Array()
var _next_goal_banner_at := 0.0
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
@onready var _effects: Node2D = $World/Effects
@onready var _popups: Control = $Popups
@onready var _money_label: Label = %MoneyLabel
@onready var _coin_icon: TextureRect = %CoinIcon
@onready var _location_label: Label = %LocationLabel
@onready var _backpack_label: Label = %BackpackLabel
@onready var _backpack_bar: ProgressBar = %BackpackBar
@onready var _tank_label: Label = %TankLabel
@onready var _hint_label: Label = %HintLabel
@onready var _fishpedia_button: Button = %FishpediaButton
@onready var _goals_button: Button = %GoalsButton
@onready var _map_button: Button = %MapButton
@onready var _language_button: Button = %LanguageButton
@onready var _menu_button: Button = %MenuButton

var fishpedia := Fishpedia.new()
var goals := GoalsPanel.new()
var world_map := WorldMap.new()
var game_menu := GameMenu.new()


func _ready() -> void:
	rng.randomize()
	_world.scale = Vector2.ONE * ZOOM
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.state_replaced.connect(_rebuild_from_state)
	resized.connect(_update_camera.bind(0.0, true))
	fishpedia.art_for = _art_for
	add_child(fishpedia)
	_fishpedia_button.pressed.connect(fishpedia.open)
	add_child(goals)
	_goals_button.pressed.connect(goals.open)
	add_child(world_map)
	world_map.travel_chosen.connect(_on_travel_chosen)
	_map_button.pressed.connect(world_map.open)
	_language_button.pressed.connect(Settings.cycle_language)
	add_child(game_menu)
	game_menu.game_replaced.connect(rebuild_requested.emit)
	_menu_button.pressed.connect(game_menu.open)
	EventBus.achievement_reached.connect(_on_achievement_reached)

	location = Travel.current(GameState.state)
	is_home = Travel.is_home(GameState.state)
	_spot_rect = HOME_SPOT_RECT if is_home else AWAY_SPOT_RECT
	water_area = PlayArea.new(Rect2(_spot_rect.position.x, SHORE_Y + WATER_MARGIN, _spot_rect.size.x, _spot_rect.end.y - SHORE_Y - WATER_MARGIN))
	walk_area = PlayArea.new(_spot_rect)
	_zones = DataRegistry.zones_in(location.id)
	for zone in _zones:
		var top := maxf(zone.depth_start, SHORE_Y + WATER_MARGIN)
		_zone_areas.append(PlayArea.new(Rect2(_spot_rect.position.x, top, _spot_rect.size.x, zone.depth_end - top)))
		_zone_spawns.append(SpawnTable.new(zone.spawns))
	_seabed.tropical = location.env == "tropical"
	_seabed.generate(water_area)
	if location.id == WRECK_LOCATION:
		_seabed.add_wreck(WRECK_POSITION)
	EventBus.fish_sold_by_seller.connect(_on_fish_sold_by_seller)
	_build_squares()
	_rebuild_from_state()
	wader.ground_position = STORE_SQUARE + Vector2(0.0, 330.0)
	wader.position = Iso.to_screen(wader.ground_position)
	_update_camera(0.0, true)
	_show_money(GameState.state.money)
	_update_location_label()
	_show_language()
	_populate.call_deferred()
	_show_offline_earnings.call_deferred()


## The language changed: redo every text set in code. Panels translate when they open.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_show_language()
		_update_location_label()
		_refresh_squares()
		_update_hud()
		_show_money(_shown_money)


func _process(delta: float) -> void:
	_update_shake(delta)
	wader.simulate(delta, walk_area)
	wader.in_water = wader.ground_position.y > SHORE_Y
	wader.speed_multiplier = 1.0 if wader.in_water else BEACH_SPEED
	_update_zone()
	_update_camera(delta)
	_update_wake(delta)
	for fish in _fish:
		fish.simulate(delta, wader.ground_position, THREAT_RADIUS, _fish)
	_check_catches(delta)
	_combo_timer = maxf(_combo_timer - delta, 0.0)
	_update_drones(delta)
	_update_squares(delta)

	if auto_spawn:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = SPAWN_INTERVAL_S
			_refill_zones()


## Touch to walk towards the finger, drag to steer; the wader stops when the finger lifts.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index != 0:
			return
		_holding = touch.pressed
		if touch.pressed:
			_gate_warned = false
			_walk_to(scene_to_ground(touch.position))
		else:
			wader.stop()
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
					tr("Buy on the beach: %s\nto swim further out!") % tr(DataRegistry.gear_levels[next_gear].name), WARNING_COLOR, 1.2)
			Haptics.bump()


#region Public helpers (also used by tests)

## Adds one fish at a ground position. It lives in the zone at that depth (the nearest zone
## if the point is outside all of them).
func spawn_fish(species_id: String, at: Vector2, heading: float) -> SwimmingFish:
	var zone_index := _zones.size() - 1
	for i in _zones.size():
		if at.y < _zones[i].depth_end:
			zone_index = i
			break
	return _spawn_fish_in(zone_index, species_id, at, heading)


func _spawn_fish_in(zone_index: int, species_id: String, at: Vector2, heading: float) -> SwimmingFish:
	var fish := SwimmingFish.new()
	fish.setup(_art_for(species_id), _zones[zone_index], _zone_areas[zone_index], at, heading)
	_entities.add_child(fish)
	_fish.append(fish)
	return fish


func fish_count() -> int:
	return _fish.size()


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


## Ground position of a tank slot: each environment has its own row, filled left to right.
func _tank_slot_position(slot: int) -> Vector2:
	var env := DataRegistry.tank_slots[slot].env
	var column := 0
	for i in slot:
		if DataRegistry.tank_slots[i].env == env:
			column += 1
	return Vector2(COLUMN_FIRST_X + COLUMN_SPACING * column, TANK_ROW_Y[env])


## Recreates everything that mirrors the saved state: tanks, squares, backpack size, gear.
func _rebuild_from_state() -> void:
	var state := GameState.state
	for node: TankNode in _tank_nodes.values():
		node.queue_free()
	_tank_nodes.clear()
	if is_home:
		for tank in state.tanks:
			_add_tank_node(tank)
	live_well.capacity = Aquarium.backpack_capacity(state)
	wader.scoop_radius = Wader.SCOOP_RADIUS * (1.0 + NET_RADIUS_STEP * (state.net_level - 1))
	_sync_shops()
	_apply_gear()
	_sync_drones()
	_refresh_squares()
	_update_hud()


## Opens the zones the gear allows and updates the buoys and the wader's look.
func _apply_gear() -> void:
	var gear := GameState.state.gear_level
	var deepest := Charting.deepest_open_zone(location.id, gear)
	walk_area = PlayArea.new(Rect2(_spot_rect.position, Vector2(_spot_rect.size.x, deepest.depth_end - _spot_rect.position.y)))
	wader.gear_level = gear
	var lines: Array[Vector2] = []
	for i in range(1, _zones.size()):
		var zone := _zones[i]
		lines.append(Vector2(zone.depth_start, 1.0 if zone.gear_level <= gear else 0.0))
	_buoys.setup(lines, _spot_rect.size.x)


## Tracks which zone the wader is in; announces zones on entry.
func _update_zone() -> void:
	var zone := Charting.zone_at(location.id, wader.ground_position.y) if wader.in_water else null
	wader.swimming = zone != null and zone.order > 1
	if zone == _wader_zone:
		return
	_wader_zone = zone
	_update_location_label()
	if zone != null:
		_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 120.0),
				"%s\n%s" % [tr(zone.name), Charting.progress_text(GameState.state, zone)], STORED_COLOR, 0.8)


func _update_location_label() -> void:
	_location_label.text = "%s · %s" % [tr(location.name), tr(_wader_zone.name) if _wader_zone != null else tr("Beach")]


func _add_tank_node(tank: TankState) -> TankNode:
	var node := TankNode.new()
	node.setup(tank, _tank_slot_position(tank.slot), _art_for)
	_entities.add_child(node)
	_tank_nodes[tank.slot] = node
	return node


func _show_offline_earnings() -> void:
	var lines: Array[String] = []
	if GameState.last_offline_stored > 0:
		lines.append(tr("Stored by drones: %d fish") % GameState.last_offline_stored)
	if GameState.last_offline_earned >= 1.0:
		lines.append(tr("Your sellers earned +%s coins") % NumberFormat.compact(GameState.last_offline_earned))
	if not lines.is_empty():
		Juice.popup_text(_popups, Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 160.0),
				tr("While you were away:") + "\n" + "\n".join(lines), 52, COIN_COLOR, 2.5)
	GameState.last_offline_earned = 0.0
	GameState.last_offline_stored = 0


#region Camera

## Follows the wader, keeping the view over the spot.
func _update_camera(delta: float, snap: bool = false) -> void:
	if size.x <= 0.0:
		return
	var focus := Iso.to_screen(wader.ground_position) + Vector2(0.0, -60.0)
	var view_center := Vector2(size.x * 0.5, (PLAY_MARGIN_TOP + size.y - PLAY_MARGIN_BOTTOM) * 0.5)
	var target := view_center - focus * ZOOM

	var bounds := Rect2(Iso.to_screen(_spot_rect.position), Vector2.ZERO)
	for corner: Vector2 in [Vector2(_spot_rect.end.x, _spot_rect.position.y), _spot_rect.end, Vector2(_spot_rect.position.x, _spot_rect.end.y)]:
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
	water.set_shader_parameter("dunes_y", _spot_rect.position.y)
	water.set_shader_parameter("shallow_color", location.shallow_color)
	water.set_shader_parameter("deep_color", location.deep_color)
	water.set_shader_parameter("sand_color", location.sand_color)
	water.set_shader_parameter("wet_sand_color", location.sand_color.darkened(0.15))
	water.set_shader_parameter("dune_color", location.sand_color.darkened(0.1).lerp(Color(0.6, 0.7, 0.35), 0.35))

#endregion


#region Spawning

func _populate() -> void:
	if not auto_spawn:
		return
	for i in _zones.size():
		while _zone_fish_count(i) < _zone_population(i):
			_spawn_group(i, true)


## Tops up one zone that is short of fish, swimming in from the side.
func _refill_zones() -> void:
	for i in _zones.size():
		if _zone_fish_count(i) < _zone_population(i):
			_spawn_group(i, false)
			return


## Fish a zone holds: its data population, scaled to the width of the spot.
func _zone_population(zone_index: int) -> int:
	return roundi(_zones[zone_index].population * _spot_rect.size.x / POPULATION_WIDTH)


func _zone_fish_count(zone_index: int) -> int:
	var zone := _zones[zone_index]
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
		if fish.ground_position.distance_to(scoop) > wader.scoop_radius + fish.catch_radius():
			fish.hold_time = maxf(fish.hold_time - delta * HOLD_DECAY, 0.0)
			continue
		if live_well.is_full():
			fish.hold_time = 0.0
			continue
		fish.hold_time += delta
		var needed := CatchRules.struggle_seconds(fish.species, Aquarium.net_speed(GameState.state))
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
				tr("New species!") + "\n" + tr(fish.species.common_name), NEW_SPECIES_COLOR, 1.4)
		Sfx.play(&"ding", 1.5, -4.0)
		Haptics.bump()
		_bump(_fishpedia_button)
	if not was_charted and Charting.is_charted(GameState.state, fish.zone):
		_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 220.0),
				tr("%s charted!\nDrones can fish here now") % tr(fish.zone.name), COMBO_COLOR, 1.6)
		Sfx.play(&"ding", 1.0)
		Sfx.play(&"ding", 1.26, -4.0)
		_sync_drones()
		_refresh_squares()
	GameState.check_achievements()
	_update_hud()

#endregion


#region Squares

func _build_squares() -> void:
	if not is_home:
		# Away from home: a dock that ships the catch to the tanks at home, or sells it.
		_add_square("store", ActionSquare.Kind.STORE, SHIP_SQUARE)
		_add_square("sell_dock", ActionSquare.Kind.SELL, DOCK_SELL_SQUARE)
		return
	_add_square("store", ActionSquare.Kind.STORE, STORE_SQUARE)
	_add_square("upgrade_backpack", ActionSquare.Kind.BUY, BACKPACK_SQUARE)
	_add_square("upgrade_net", ActionSquare.Kind.BUY, NET_SQUARE)
	_add_square("upgrade_gear", ActionSquare.Kind.BUY, GEAR_SQUARE)
	_add_square("buy_drone", ActionSquare.Kind.BUY, DRONE_PAD)
	_add_square("hire_seller", ActionSquare.Kind.BUY, HIRE_SQUARE)
	for slot in DataRegistry.tank_slots.size():
		_slot_squares.append(_add_square("", ActionSquare.Kind.BUY, _tank_slot_position(slot) + TANK_SQUARE_OFFSET))
	for slot in DataRegistry.shop_slots.size():
		_shop_squares.append(_add_square("", ActionSquare.Kind.SELL, _shop_position(slot) + SHOP_SQUARE_OFFSET))


## Titles and prices are set by _refresh_squares().
func _add_square(square_id: String, kind: ActionSquare.Kind, center: Vector2) -> ActionSquare:
	var new_square := ActionSquare.new()
	new_square.setup(square_id, kind, "", center, SQUARE_HALF)
	_squares_layer.add_child(new_square)
	_squares.append(new_square)
	return new_square


## Updates the purchase squares at home: one upgrade square per built tank, a build square for
## the next free slot of each environment (tropical ones once a tropical location is open), the
## shops (a "Sell fish" square per built shop, "Build shop" for the next), backpack, net, gear,
## drones and sellers. Squares with nothing left to buy are hidden. Away from home: the dock.
func _refresh_squares() -> void:
	if not is_home:
		square_by_id("store").title = tr("Ship home")
		square_by_id("sell_dock").title = tr("Sell fish")
		return
	square_by_id("store").title = tr("Store fish")
	var state := GameState.state
	var tropical_open := DataRegistry.locations.any(func(l: LocationDef) -> bool:
		return l.env == "tropical" and Travel.is_unlocked(state, l))
	for slot in _slot_squares.size():
		var slot_square := _slot_squares[slot]
		var env := DataRegistry.tank_slots[slot].env
		var tank := state.tank_in_slot(slot)
		if tank != null:
			_set_purchase(slot_square, "upgrade_tank_%d" % slot, tr("Bigger tank"), Aquarium.tank_upgrade_cost(tank))
		elif slot == Aquarium.next_slot(state, env) and (env == "temperate" or tropical_open):
			if env == "temperate":
				_set_purchase(slot_square, "build_tank", tr("Build tank"), Aquarium.next_tank_cost(state, env))
			else:
				_set_purchase(slot_square, "build_tropical_tank", tr("Tropical tank"), Aquarium.next_tank_cost(state, env))
		else:
			slot_square.hide()
	for slot in _shop_squares.size():
		var shop_square := _shop_squares[slot]
		shop_square.subtitle = _tier_zone_names(slot + 1)
		if slot < state.shop_count:
			shop_square.id = "sell_%d" % slot
			shop_square.kind = ActionSquare.Kind.SELL
			shop_square.title = tr("Sell fish")
			shop_square.show()
		elif slot == state.shop_count:
			shop_square.kind = ActionSquare.Kind.BUY
			_set_purchase(shop_square, "build_shop", tr("Build shop"), Selling.next_shop_cost(state))
		else:
			shop_square.hide()
	var backpack := square_by_id("upgrade_backpack")
	_set_purchase(backpack, "upgrade_backpack", tr("Bigger backpack"), Aquarium.backpack_upgrade_cost(state))
	var next_net := DataRegistry.net_levels[mini(state.net_level, DataRegistry.net_levels.size() - 1)]
	_set_purchase(square_by_id("upgrade_net"), "upgrade_net", tr(next_net.name), Aquarium.net_upgrade_cost(state))
	var gear := square_by_id("upgrade_gear")
	var next_gear := DataRegistry.gear_levels[mini(state.gear_level, DataRegistry.gear_levels.size() - 1)]
	_set_purchase(gear, "upgrade_gear", tr(next_gear.name), Aquarium.gear_upgrade_cost(state))
	# Drone N fishes zone N, so it is offered once that zone is charted.
	var drone_square := square_by_id("buy_drone")
	var drone_available := Automation.next_drone_available(state)
	_set_purchase(drone_square, "buy_drone", tr("Buy drone"), Automation.next_drone_cost(state) if drone_available else -1.0)
	drone_square.subtitle = tr(Automation.drone_zone(state, state.drone_count).name) if drone_available else ""
	var hire_square := square_by_id("hire_seller")
	_set_purchase(hire_square, "hire_seller", tr("Hire seller"), Selling.next_seller_cost(state))
	hire_square.subtitle = _tier_zone_names(state.seller_count + 1)


## The names of the zones whose fish a shop tier sells, e.g. "Sandbanks · Reef crest". Only
## locations the player has opened.
func _tier_zone_names(tier: int) -> String:
	var names: Array[String] = []
	for zone in DataRegistry.zones:
		if zone.order == tier and Travel.is_unlocked(GameState.state, DataRegistry.location(zone.location)):
			names.append(tr(zone.name))
	return " · ".join(names)


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
		ActionSquare.Kind.SELL:
			_action_timer = SELL_INTERVAL_S
			_sell_one(on)
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
			_announce(at, (tr("%d stored!") if is_home else tr("%d shipped home!")) % _action_count, STORED_COLOR)
		ActionSquare.Kind.SELL:
			_announce(at, tr("%d sold\n+%s coins") % [_action_count, NumberFormat.compact(_action_total)], COIN_COLOR)
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
			var advice := tr("Build or upgrade a tank.") if location.env == "temperate" else tr("Build a tropical tank at home.")
			_announce(_world_to_scene(square_by_id("store").position + Vector2(0.0, -110.0)),
					tr("No room in the tanks!") + "\n" + advice, WARNING_COLOR, 1.2)
			Haptics.bump()
		return
	var species_id := live_well.take_at(index)
	var art := wader.take_from_stack_at(index)
	var from := _world_to_scene(wader.stack_top_position())
	var tank := GameState.store_fish(species_id)
	_action_count += 1
	# At home the fish flies into its tank; away it goes into a crate on the dock.
	var node: TankNode = _tank_nodes.get(tank.slot)
	var to := node.drop_point() if node != null else square_by_id("store").position
	Juice.fly_fish(_popups, art, from, _world_to_scene(to), Wader.STACK_FISH_LENGTH * ZOOM,
			_on_fish_reached_tank.bind(node))
	Sfx.play(&"pop", 1.0 + _action_count * 0.05, -6.0)
	if live_well.count() == 0:
		_finish_square_action()
	_update_hud()


func _on_fish_reached_tank(node: TankNode) -> void:
	if node == null or not is_instance_valid(node):
		Sfx.play(&"pop", 0.8, -8.0)
		return
	Juice.splash(_effects, node.drop_point(), 5)
	node.bounce()
	Sfx.play(&"splash", 1.4, -10.0)
	Haptics.tick()


## Sells one fish on a "Sell fish" square. A shop sells the fish of its zone: from the backpack
## first, then the most valuable from the tanks. Backpack fish that no built shop buys are let go.
## The dock away from home sells the whole backpack.
func _sell_one(target: ActionSquare) -> void:
	var tier := _shop_tier(target)
	var index := _backpack_index_for(tier)
	var from: Vector2
	var price := 0.0
	if index >= 0:
		from = _world_to_scene(wader.stack_top_position())
		price = GameState.sell_fish(live_well.take_at(index))
		wader.take_from_stack_at(index)
	elif tier > 0 and _release_unsellable():
		return
	elif tier > 0:
		var sale := GameState.sell_from_tanks(tier)
		if sale.is_empty():
			_finish_square_action()
			if not _warned:
				_warned = true
				_announce(_world_to_scene(target.position + Vector2(0.0, -110.0)),
						tr("Nothing to sell here.\nThis shop buys fish from: %s") % _tier_zone_names(tier), WARNING_COLOR, 1.0)
			return
		price = sale[1]
		var tank: TankState = sale[2]
		var node: TankNode = _tank_nodes.get(tank.slot)
		from = _world_to_scene(node.drop_point() if node != null else target.position)
		if node != null:
			node.bounce()
	else:
		_finish_square_action()
		return
	_action_count += 1
	_action_total += price
	Juice.fly_coin(_popups, from, _wallet_position(), 12.0 * ZOOM)
	Sfx.play(&"coin", 1.0 + minf(_action_count, 20) * 0.04, -4.0)
	var shop_index := target.id.trim_prefix("sell_").to_int() if target.id.begins_with("sell_") and target.id != "sell_dock" else -1
	if shop_index >= 0 and shop_index < _shop_nodes.size():
		_shop_nodes[shop_index].bounce()
	_update_hud()


## The shop tier of a "Sell fish" square (1 for the first shop), or 0 for the dock.
func _shop_tier(target: ActionSquare) -> int:
	if target.id.begins_with("sell_") and target.id != "sell_dock":
		return target.id.trim_prefix("sell_").to_int() + 1
	return 0


## The topmost backpack fish a shop tier buys (any fish for tier 0), or -1.
func _backpack_index_for(tier: int) -> int:
	for i in range(live_well.count() - 1, -1, -1):
		if tier == 0 or Selling.tier_of(live_well.species_ids[i]) == tier:
			return i
	return -1


## Lets the topmost backpack fish go that no built shop buys and no tank takes, so it cannot
## block the backpack. Returns false if there is none.
func _release_unsellable() -> bool:
	var state := GameState.state
	for i in range(live_well.count() - 1, -1, -1):
		var id := live_well.species_ids[i]
		if Selling.has_shop_for(state, id) or Aquarium.tank_for(state, DataRegistry.species[id]) != null:
			continue
		var from := _world_to_scene(wader.stack_top_position())
		live_well.take_at(i)
		var art := wader.take_from_stack_at(i)
		var sea := _world_to_scene(Iso.to_screen(Vector2(wader.ground_position.x, SHORE_Y + 200.0)))
		Juice.fly_fish(_popups, art, from, sea, Wader.STACK_FISH_LENGTH * ZOOM, Sfx.play.bind(&"splash", 1.2, -8.0))
		if not _warned:
			_warned = true
			_announce(_world_to_scene(wader.stack_top_position() + Vector2(0.0, -110.0)),
					tr("No shop buys %s yet.\nLet go back into the sea.") % tr(DataRegistry.species[id].common_name), WARNING_COLOR, 1.2)
		_update_hud()
		return true
	return false


## Screen position of the coin counter, where earned coins fly to.
func _wallet_position() -> Vector2:
	return _coin_icon.get_global_rect().get_center() - _popups.get_global_rect().position


## Pays a slice of the price; completes the purchase once fully paid.
func _pay_into(target: ActionSquare) -> void:
	if GameState.state.money < 0.01:
		if not _warned:
			_warned = true
			_announce(_world_to_scene(target.position + Vector2(0.0, -110.0)), tr("Not enough coins"), WARNING_COLOR, 0.6)
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
	if target.id == "build_tank" or target.id == "build_tropical_tank":
		var tropical := target.id == "build_tropical_tank"
		var tank := GameState.build_next_tank("tropical" if tropical else "temperate")
		_add_tank_node(tank).bounce()
		message = tr("New tropical tank!") if tropical else tr("New tank!")
	elif target.id == "upgrade_backpack":
		GameState.upgrade_backpack()
		live_well.capacity = Aquarium.backpack_capacity(state)
		message = tr("Bigger backpack!\n%d fish") % live_well.capacity
	elif target.id == "buy_drone":
		GameState.buy_drone()
		_sync_drones()
		message = tr("New drone!\nIt fishes here: %s") % tr(Automation.drone_zone(state, state.drone_count - 1).name)
	elif target.id == "build_shop":
		GameState.build_shop()
		_sync_shops()
		_shop_nodes[-1].bounce()
		message = tr("New shop!")
	elif target.id == "hire_seller":
		GameState.hire_seller()
		_sync_shops()
		message = tr("Seller hired!\nSells grown fish for you")
	elif target.id == "upgrade_net":
		GameState.upgrade_net()
		wader.scoop_radius = Wader.SCOOP_RADIUS * (1.0 + NET_RADIUS_STEP * (state.net_level - 1))
		message = tr("%s!\nBig fish are landed faster") % tr(DataRegistry.net_levels[state.net_level - 1].name)
	elif target.id == "upgrade_gear":
		GameState.upgrade_gear()
		_apply_gear()
		var zone := Charting.deepest_open_zone(location.id, state.gear_level)
		message = tr("%s!\nNow you can reach: %s") % [tr(DataRegistry.gear_levels[state.gear_level - 1].name), tr(zone.name)]
	elif target.id.begins_with("upgrade_tank_"):
		var tank := state.tank_in_slot(target.id.trim_prefix("upgrade_tank_").to_int())
		GameState.upgrade_tank(tank)
		_tank_nodes[tank.slot].bounce()
		message = "%s!\n%s L" % [tr(DataRegistry.tank_levels[tank.level - 1].name), NumberFormat.compact(Aquarium.capacity(tank))]
	_announce(at, message, COMBO_COLOR, 1.0)
	Sfx.play(&"ding", 1.0)
	Sfx.play(&"ding", 1.5, -6.0)
	Juice.splash(_effects, target.position, 18)
	Haptics.bump()
	_shake = 10.0
	_action_count = 0
	_purchase_done = true
	_refresh_squares()
	GameState.check_achievements()
	_update_hud()
	SaveSystem.save_game()

#endregion


#region Shops

func _shop_position(slot: int) -> Vector2:
	return Vector2(COLUMN_FIRST_X + COLUMN_SPACING * slot, SHOP_ROW_Y)


## Matches the shop buildings to the shops built and shows who is staffed.
func _sync_shops() -> void:
	if not is_home:
		return
	var state := GameState.state
	while _shop_nodes.size() < state.shop_count:
		var shop := ShopNode.new()
		shop.tier = _shop_nodes.size() + 1
		shop.position = Iso.to_screen(_shop_position(_shop_nodes.size()))
		_entities.add_child(shop)
		_shop_nodes.append(shop)
	for i in _shop_nodes.size():
		_shop_nodes[i].staffed = i < state.seller_count
	_refresh_shop_displays()


## Puts the most valuable species each shop sells from the tanks on its counter.
func _refresh_shop_displays() -> void:
	if _shop_nodes.is_empty():
		return
	var best: Dictionary[String, float] = {}
	for tank in GameState.state.tanks:
		for fish in tank.fish:
			var price := Economy.sale_price(DataRegistry.species[fish.species_id], fish.growth)
			best[fish.species_id] = maxf(best.get(fish.species_id, 0.0), price)
	var ids := best.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return best[a] > best[b])
	for i in _shop_nodes.size():
		var display: Array[FishArt] = []
		for id: String in ids:
			if Selling.tier_of(id) == i + 1 and display.size() < 4:
				display.append(_art_for(id))
		_shop_nodes[i].display = display


## A hired seller sold a fish: coins pop up at their shop.
func _on_fish_sold_by_seller(species_id: String, price: float) -> void:
	var index := Selling.tier_of(species_id) - 1
	if not is_home or index >= _shop_nodes.size():
		return
	var shop := _shop_nodes[index]
	shop.bounce()
	var at := _world_to_scene(shop.counter_point())
	Juice.popup_text(_popups, at + Vector2(0.0, -40.0), "+" + NumberFormat.compact(price), 36, COIN_COLOR, 0.2)
	Juice.fly_coin(_popups, at, _wallet_position(), 9.0 * ZOOM)
	Sfx.play(&"coin", 1.3, -10.0)
	_update_hud()

#endregion


#region Drones

## Matches the drones to the number bought. Drones working in a zone of this location fly here;
## the others work elsewhere and send their catch home without being seen.
func _sync_drones() -> void:
	var state := GameState.state
	for drone in _drones:
		drone.queue_free()
	_drones.clear()
	_away_drone_progress.resize(state.drone_count)
	for i in state.drone_count:
		var zone := Automation.drone_zone(state, i)
		if zone == null or zone.location != location.id:
			continue
		var drone := Drone.new()
		drone.setup(DRONE_PAD, zone, _zone_areas[_zones.find(zone)], Automation.drone_capacity(i), 1.0 + DRONE_SIZE_STEP * i)
		drone.delivered.connect(_on_drone_delivered)
		_entities.add_child(drone)
		_drones.append(drone)


func _update_drones(delta: float) -> void:
	_update_away_drones(delta)
	for drone in _drones:
		var lifted := drone.simulate(delta, _fish, _drone_can_take)
		if drone.task == Drone.Task.LIFT and drone.target != null:
			# The fish wriggles in the drone's net.
			drone.target.hold_time = maxf(drone.target.hold_time, 0.1)
		if lifted != null:
			_fish.erase(lifted)
			lifted.play_caught(drone.net_position())
			Juice.splash(_effects, lifted.position, 6)
			Sfx.play(&"pop", 1.2, -12.0)


func _drone_can_take(species_id: String) -> bool:
	return Automation.drone_can_catch(GameState.state, species_id)


## Drones working at another location store a fish now and then (sold if no tank has room).
func _update_away_drones(delta: float) -> void:
	var state := GameState.state
	for i in state.drone_count:
		var zone := Automation.drone_zone(state, i)
		if zone == null or zone.location == location.id:
			continue
		_away_drone_progress[i] += delta * AWAY_DRONE_FISH_PER_SECOND
		if _away_drone_progress[i] < 1.0:
			continue
		_away_drone_progress[i] -= 1.0
		var species_id := Automation.pick_drone_catch(state, zone, rng)
		if species_id.is_empty():
			continue
		var tank := GameState.store_fish(species_id)
		if tank == null:
			GameState.sell_fish(species_id)
		elif _tank_nodes.has(tank.slot):
			_tank_nodes[tank.slot].bounce()


## A drone landed with its catch: into the tanks where there is room, the rest is sold.
func _on_drone_delivered(drone: Drone, species_ids: Array[String]) -> void:
	var from := _world_to_scene(drone.net_position())
	for id in species_ids:
		var tank := GameState.store_fish(id)
		if tank != null:
			# Away from home the catch goes into a crate on the pad.
			var node: TankNode = _tank_nodes.get(tank.slot)
			var to := node.drop_point() if node != null else Iso.to_screen(DRONE_PAD)
			Juice.fly_fish(_popups, _art_for(id), from, _world_to_scene(to), Drone.ICON_LENGTH * ZOOM,
					_on_fish_reached_tank.bind(node))
		else:
			GameState.sell_fish(id)
			Juice.fly_coin(_popups, from, _wallet_position(), 9.0 * ZOOM)
	Sfx.play(&"pop", 1.4, -10.0)
	_update_hud()

#endregion


#region Travel

## Travels to another location from the World map: unlocks it first if needed. The catch must
## be stored or sold before leaving.
func _on_travel_chosen(def: LocationDef) -> void:
	var state := GameState.state
	if live_well.count() > 0:
		world_map.hide()
		_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 200.0),
				tr("Store or sell your catch\nbefore you travel!"), WARNING_COLOR, 1.2)
		return
	if not Travel.is_unlocked(state, def) and not GameState.unlock_location(def):
		return
	GameState.travel_to(def)
	SaveSystem.save_game()
	world_map.hide()
	rebuild_requested.emit()

#endregion


#region Effects

## A goal was reached: banner, reward coins and a bump of the Goals button. Goals reached
## together are announced one after the other.
func _on_achievement_reached(def: AchievementDef) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var delay := maxf(_next_goal_banner_at - now, 0.0)
	_next_goal_banner_at = now + delay + GOAL_BANNER_SPACING_S
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(_show_goal_banner.bind(def))
	else:
		_show_goal_banner(def)


func _show_goal_banner(def: AchievementDef) -> void:
	var text := tr("Goal reached: %s") % tr(def.name)
	if def.reward > 0.0:
		text += "\n" + tr("+%s coins") % NumberFormat.compact(def.reward)
	_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 260.0), text, COMBO_COLOR, 1.2)
	Sfx.play(&"ding", 1.0)
	Sfx.play(&"ding", 1.5, -4.0)
	for i in 5:
		get_tree().create_timer(0.3 + i * 0.06).timeout.connect(Sfx.play.bind(&"coin", 1.0 + i * 0.06, -4.0))
	Haptics.bump()
	_bump(_goals_button)


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
	_backpack_label.text = tr("Backpack  %d / %d") % [live_well.count(), live_well.capacity]
	_backpack_bar.max_value = live_well.capacity
	_backpack_bar.value = live_well.count()
	var used := 0.0
	var capacity := 0.0
	for tank in state.tanks:
		used += Aquarium.used_space(tank)
		capacity += Aquarium.capacity(tank)
	var adults := Aquarium.adult_count(state)
	_tank_label.text = tr("Tanks  %s / %s L  ·  %d grown  ·  worth %s") % [
		NumberFormat.compact(used), NumberFormat.compact(capacity), adults, NumberFormat.compact(Aquarium.tank_value(state))]
	if live_well.is_full():
		_hint_label.text = tr("Backpack full! Store the fish in a tank or sell them at a shop.")
	elif live_well.count() > 0:
		_hint_label.text = tr("Walk up the beach to store or sell your catch.")
	elif Selling.unsellable_count(state) > 0 and Selling.next_shop_cost(state) >= 0.0:
		_hint_label.text = tr("Some fish in the tanks are from a deeper zone. Build the next shop to sell them!")
	elif adults > 0 and state.seller_count == 0:
		_hint_label.text = tr("Grown fish are worth 3 times as much. Sell them at a shop!")
	else:
		_hint_label.text = tr("Touch and hold to wade there and catch fish.")
	_refresh_shop_displays()


func _on_money_changed(money: float) -> void:
	if _money_tween:
		_money_tween.kill()
	_money_tween = create_tween()
	_money_tween.tween_method(_show_money, _shown_money, money, 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_update_hud()


func _show_money(value: float) -> void:
	_shown_money = value
	_money_label.text = NumberFormat.compact(value)


## The language button shows the flag of the language in use.
func _show_language() -> void:
	_language_button.icon = LANGUAGE_FLAGS.get(Settings.current_language(), LANGUAGE_FLAGS["en"])

#endregion
