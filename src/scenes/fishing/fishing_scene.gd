extends Control
## A fishing spot (the player's current location), in isometric view: the sea at the bottom
## left, the beach at the top right, and a camera that follows the wader.
##
## The sea gets deeper further from the shore, in depth zones (data/zones.csv) marked by buoy
## lines; deeper zones need better diving gear and hold rarer fish. The wader scoops up fish into
## the backpack. On the beach, pads do things while the wader stands on them. Every location has
## its own beach business (GameState.here()): left of the pier the tank and the fish shop, joined
## by the sales pipe, with the shop's pads; right of it the gear shop, whose door leads into the
## upgrade store (UpgradeStore), and the drones' dock.
## Hired sellers sell on their own.
## The World map travels between locations.

## The spot must be rebuilt: after travelling, loading or starting a new game.
signal rebuild_requested
## The wader walked through the gear shop's door: show the upgrade store.
signal store_requested

## How much the world is magnified on screen.
const ZOOM := 1.5
const CAMERA_SMOOTHING := 6.0
## The camera may show this much (world pixels) beyond the spot's edges.
const CAMERA_OVERSCROLL := 120.0
## Screen pixels covered by the HUD bars at the top and bottom.
const PLAY_MARGIN_TOP := 270.0
const PLAY_MARGIN_BOTTOM := 330.0

#region Layout (ground units; the waterline is at y = 0, the beach at negative y)
## The beach part of the spot; the water reaches out to the end of the location's deepest zone.
## A boardwalk leads from the water up the beach and is kept free of pads, so the wader can walk
## up and down without buying anything by accident. Left of it is the business (art_source/
## "layout map.png"): the tank at the waterline with its store pad beside it towards the pier,
## the fish market behind the tank, the sales pipe from the tank up the west edge past the
## market, and at the back the sales booths, beyond which the beach cannot be walked on: the
## player's at the east end with the "Sell fish" pad in front and the buyers' queue coming down
## from the north, the sellers' towards the west with the "Hire seller" pad in front of the
## next free one. Right of it is the gear shop. Pads keep clear gaps.
const BEACH_TOP := -1650.0
const SPOT_WIDTH := 4320.0
## The zones' fish populations (data/zones.csv) are for a spot this wide; wider spots get more.
const POPULATION_WIDTH := 2920.0
const SHORE_Y := 0.0
## Fish stay this far out in the water.
const WATER_MARGIN := 50.0
## Fish keep this far from the waterline (ground units), clear of the pier.
const FISH_FREE_STRIP := 300.0
## Fish of a deeper zone keep this far below its buoy line, so they do not drift into the zone
## in front of it.
const ZONE_GAP := 150.0
## Fish further than this outside the view (world pixels) are hidden and skip schooling.
const CULL_MARGIN := 200.0
## Half the length (along the row) and depth of the pads.
const SQUARE_HALF := Vector2(180.0, 110.0)
## The boardwalk, in the middle of the beach.
const PATH_X := 2860.0
const PATH_HALF_WIDTH := 150.0
## The boardwalk's shore end, where its railing is: the wader walks no further up the beach.
const PIER_TOP := -930.0
## Right of the boardwalk, the gear shop fills the beach up to its east edge, leaving a strip by
## the water: the upgrades are bought inside (UpgradeStore). It cannot be walked on; walking into
## its door, at the west end of its front towards the boardwalk, goes inside. The drones start
## from and deliver to their dock on the strip.
const GEAR_SHOP_POSITION := Vector2(3780.0, -740.0)
const GEAR_SHOP_HALF := Vector2(540.0, 390.0)
const GEAR_SHOP_DOOR_X := 3390.0
const GEAR_SHOP_DOOR_HALF_WIDTH := 95.0
## How close the wader comes to the shop's walls.
const GEAR_SHOP_MARGIN := 40.0
const DRONE_PAD := Vector2(4050.0, -140.0)
const DRONE_DOCK_TEXTURE: Texture2D = preload("res://assets/sprites/props/drone_dock.svg")
## Where the dock's middle is in its sprite (PLACEHOLDER, drawn at ground scale).
const DRONE_DOCK_ANCHOR := Vector2(200.0, 110.0)
## Left of the boardwalk, close to it: the tank at the waterline with its store pad right
## beside it, turned to run along the tank. The fish market stands behind the player's booth,
## beyond the walkable beach, where it hides no pad; tall sprites hide what lies north of them.
const TANK_POSITION := Vector2(2160.0, -250.0)
const STORE_SQUARE := Vector2(2390.0, -250.0)
const STORE_HALF := Vector2(110.0, 160.0)
const SHOP_POSITION := Vector2(2050.0, -1420.0)
## The sales pipe runs from the tank up the beach into the market, between the "Sell fish" pad
## and the first seller's booth, holding the grown fish in the order they will be sold.
const PIPE_FROM := Vector2(2160.0, -400.0)
const PIPE_TO := Vector2(2080.0, -1250.0)
## Sunken ships on the seabed per location: prop sprite (assets/sprites/seabed), ground position.
const WRECKS: Dictionary[String, Array] = {
	"north_sea": ["wreck", Vector2(2400.0, 2520.0)],
	"coral_reef": ["galleon", Vector2(2400.0, 2520.0)],
}
## The sales booths stand in a row on the edge of the walkable beach, facing north, as big as
## the people: the player's at the east end, then one per seller towards the west, the first
## a bit further off so the "Sell fish" and "Hire seller" pads keep apart. Buyers come
## down from the north in one queue ending behind the player's booth; the first in line goes to the next free
## booth (the player's only while the player stands on the "Sell fish" pad), and each sale sends
## them off up the beach with a fish.
const FIRST_BOOTH := Vector2(2400.0, -1010.0)
const BOOTH_SPACING := 180.0
const FIRST_SELLER_GAP := 450.0
const CUSTOMER_ENTRY := Vector2(FIRST_BOOTH.x, -1900.0)
## Served buyers walk this far up the beach, out of view.
const CUSTOMER_EXIT_Y := -2050.0
## Ground distance between buyers in line.
const QUEUE_SPACING := 90.0
## The "Sell fish" and "Hire seller" pads are squares the size of a booth's place in the row,
## right in front of their booth: the player's, and the next free one for the seller to hire.
const BOOTH_PAD_HALF := Vector2(120.0, 120.0)
const BOOTH_PAD_OFFSET := Vector2(0.0, 260.0)
## Painted cashiers (assets/sprites/props/cashier_N), shown on the "Hire seller" pad.
const CASHIER_LOOKS := 3
## Buyers keep coming at this pace from the start, whether anyone sells or not.
const CUSTOMER_INTERVAL_S := 2.0
## Painted decoration on the beach: sprite (assets/sprites/props), ground position, screen
## height, and where it shows ("" everywhere, else only at locations with that water).
const DECOR: Array[Array] = [
	["signpost", Vector2(2650.0, -450.0), 120.0, ""],
	["seagull", Vector2(250.0, -1230.0), 55.0, "temperate"],
]
#endregion

const SPAWN_INTERVAL_S := 0.8
## Fish startle when the wader comes this close (ground units). Smaller than the net's reach
## (Wader.REACH + scoop radius), so walking straight at fish catches them.
const THREAT_RADIUS := 130.0
## How much faster an interrupted struggle drains than it builds up.
const HOLD_DECAY := 2.0
## Catches less than this far apart continue the combo.
const COMBO_WINDOW_S := 1.3
## Seconds between fish stored on the store square.
const UNLOAD_INTERVAL_S := 0.09
## Seconds the player needs to sell one fish at their booth while standing on the "Sell fish" pad.
## A hired seller is as quick (data/staff.csv: 30 fish a minute) at a booth of their own, and also
## works while the game is closed; with big tanks it takes several of them to keep up.
const SELL_INTERVAL_S := 2.0
## How often the pad looks again while no buyer is waiting at the counter.
const BUYER_WAIT_S := 0.1
## Walking on sand is faster than wading.
const BEACH_SPEED := 1.5
## Each further drone is this much bigger than the first; it carries more and bigger fish.
const DRONE_SIZE_STEP := 0.2
## Each better net is this much wider.
const NET_RADIUS_STEP := 0.12
## Seconds between payments on a build square; each pays this share of the price.
const PAY_INTERVAL_S := 0.05
const PAY_SHARE := 0.04
## Seconds between banners when several goals are reached at once.
const GOAL_BANNER_SPACING_S := 2.0
const WAKE_INTERVAL_S := 0.22
## How strongly the painted seabed shows through the shallow water.
const FLOOR_STRENGTH := 0.8
const COMBO_COLOR := Color(1.0, 0.85, 0.2)
const NEW_SPECIES_COLOR := Color(0.6, 1.0, 0.7)
const STORED_COLOR := Color(0.6, 0.9, 1.0)
const COIN_COLOR := Color(1.0, 0.86, 0.3)
const WARNING_COLOR := Color(1.0, 0.55, 0.45)

## Tests switch this off to control exactly which fish exist.
@export var auto_spawn := true

var rng := RandomNumberGenerator.new()
var live_well := LiveWell.new(10)
## Where the player is.
var location: LocationDef
var water_area: PlayArea
## Where the wader may go: the beach and the zones the gear allows. Updated with the gear.
var walk_area: PlayArea

var _spot_rect: Rect2
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
## The location's painted seabed and sand tiles (assets/sprites/seafloor, beach), or null.
var _floor_texture: Texture2D
var _sand_texture: Texture2D
var _tank_node: TankNode
var _pipe: SalesPipe
var _shop_node: ShopNode
## Buyers in the queue, first in line first; served ones are not in it.
var _queue: Array[Customer] = []
## The buyer at each booth, or null: booth 0 is the player's, booth 1 + n the n-th seller's.
var _booths: Array[Customer] = []
var _booth_nodes: Array[Booth] = []
var _customer_timer := 0.0
var _sell_square: ActionSquare
var _drones: Array[Drone] = []
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
## True from walking into the gear shop's door until back on the beach.
var _in_store := false
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
	add_child(game_menu)
	game_menu.game_replaced.connect(rebuild_requested.emit)
	_menu_button.pressed.connect(game_menu.open)
	EventBus.achievement_reached.connect(_on_achievement_reached)

	location = Travel.current(GameState.state)
	_zones = DataRegistry.zones_in(location.id)
	_spot_rect = Rect2(0.0, BEACH_TOP, SPOT_WIDTH, _zones[-1].depth_end - BEACH_TOP)
	water_area = PlayArea.new(Rect2(_spot_rect.position.x, SHORE_Y + WATER_MARGIN, _spot_rect.size.x, _spot_rect.end.y - SHORE_Y - WATER_MARGIN))
	walk_area = PlayArea.new(Rect2(_spot_rect.position.x, PIER_TOP, _spot_rect.size.x, _spot_rect.end.y - PIER_TOP))
	for zone in _zones:
		var top := maxf(zone.depth_start + (ZONE_GAP if zone.order > 1 else 0.0), SHORE_Y + FISH_FREE_STRIP)
		_zone_areas.append(PlayArea.new(Rect2(_spot_rect.position.x, top, _spot_rect.size.x, zone.depth_end - top)))
		_zone_spawns.append(SpawnTable.new(zone.spawns))
	var floor_path := "res://assets/sprites/seafloor/%s.png" % location.id
	_floor_texture = load(floor_path) if ResourceLoader.exists(floor_path) else null
	var sand_path := "res://assets/sprites/beach/%s.png" % location.id
	_sand_texture = load(sand_path) if ResourceLoader.exists(sand_path) else null
	_seabed.water = location.env
	_seabed.generate(water_area)
	if WRECKS.has(location.id):
		_seabed.add_wreck(WRECKS[location.id][0], WRECKS[location.id][1])
	EventBus.fish_sold_by_seller.connect(_on_fish_sold_by_seller)
	_build_squares()
	_place_decor()
	_rebuild_from_state()
	wader.ground_position = Vector2(PATH_X, 130.0)
	wader.position = Iso.to_screen(wader.ground_position)
	_update_camera(0.0, true)
	_show_money(GameState.state.money)
	_update_location_label()
	_populate.call_deferred()
	_show_offline_earnings.call_deferred()


## The language changed: redo every text set in code. Panels translate when they open.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_location_label()
		_refresh_squares()
		_update_hud()
		_show_money(_shown_money)


func _process(delta: float) -> void:
	_update_shake(delta)
	wader.simulate(delta, walk_area)
	_update_gear_shop()
	wader.in_water = wader.ground_position.y > SHORE_Y
	wader.speed_multiplier = DataRegistry.gear_levels[GameState.here().gear_level - 1].capacity if wader.in_water else BEACH_SPEED
	_update_zone()
	_update_camera(delta)
	_update_wake(delta)
	var view := Rect2(-_world.position / ZOOM, size / ZOOM).grow(CULL_MARGIN)
	for fish in _fish:
		fish.visible = view.has_point(fish.position)
		fish.simulate(delta, wader.ground_position, THREAT_RADIUS, _fish)
	_check_catches(delta)
	_combo_timer = maxf(_combo_timer - delta, 0.0)
	_update_drones(delta)
	_update_squares(delta)
	_update_customers(delta)
	refresh_sell_pad()

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
		var next_gear := GameState.here().gear_level
		if next_gear < DataRegistry.gear_levels.size():
			_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 330.0),
					tr("Buy at the gear shop: %s\nto swim further out!") % tr(DataRegistry.gear_levels[next_gear].name), WARNING_COLOR, 1.2)
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
	fish.set_water_colors(location.shallow_color, location.deep_color, FLOOR_STRENGTH)
	_entities.add_child(fish)
	_fish.append(fish)
	return fish


func fish_count() -> int:
	return _fish.size()


## The "Sell fish" pad is greyed out until a fish in the tank is grown: grow first, then sell.
func refresh_sell_pad() -> void:
	var grown := Aquarium.adult_count(GameState.here())
	_sell_square.disabled = grown == 0
	_sell_square.subtitle = tr("No grown fish") if grown == 0 else tr("%d grown") % grown


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


## Recreates everything that mirrors the saved state: tanks, squares, backpack size, gear.
func _rebuild_from_state() -> void:
	var site := GameState.here()
	if _tank_node != null:
		_tank_node.queue_free()
	_tank_node = TankNode.new()
	_tank_node.setup(site.tank, TANK_POSITION, _art_for)
	_tank_node.smallest_fish_l = Aquarium.smallest_space(site.location().env)
	_entities.add_child(_tank_node)
	if _pipe != null:
		_pipe.queue_free()
	_pipe = SalesPipe.new()
	_pipe.setup(site.tank, PIPE_FROM, PIPE_TO, _art_for)
	_entities.add_child(_pipe)
	live_well.capacity = Aquarium.backpack_capacity(site)
	# The backpack is this location's: the catch waits here while the player is elsewhere.
	live_well.species_ids = site.backpack
	wader.carried.clear()
	for id in site.backpack:
		wader.carried.append(_art_for(id))
	wader.scoop_radius = Wader.SCOOP_RADIUS * (1.0 + NET_RADIUS_STEP * (site.net_level - 1))
	wader.net_level = site.net_level
	_sync_shops()
	_apply_gear()
	_sync_drones()
	_refresh_squares()
	_update_hud()


## Opens the zones the gear allows and updates the buoys and the wader's look.
func _apply_gear() -> void:
	var gear := GameState.here().gear_level
	var deepest := Charting.deepest_open_zone(location.id, gear)
	walk_area = PlayArea.new(Rect2(_spot_rect.position.x, PIER_TOP, _spot_rect.size.x, deepest.depth_end - PIER_TOP))
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
	wader.zone_order = zone.order if zone != null else 0
	if zone == _wader_zone:
		return
	_wader_zone = zone
	_update_location_label()
	if zone != null:
		_announce(Vector2(size.x * 0.5, PLAY_MARGIN_TOP + 120.0),
				"%s\n%s" % [tr(zone.name), Charting.progress_text(GameState.state, zone)], STORED_COLOR, 0.8)


func _update_location_label() -> void:
	_location_label.text = "%s · %s" % [tr(location.name), tr(_wader_zone.name) if _wader_zone != null else tr("Beach")]


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
	water.set_shader_parameter("depth_range", SeaDepth.DEPTH_RANGE)
	water.set_shader_parameter("abyss_start", SeaDepth.ABYSS_START)
	water.set_shader_parameter("abyss_end", SeaDepth.ABYSS_END)
	water.set_shader_parameter("dunes_y", _spot_rect.position.y)
	water.set_shader_parameter("shallow_color", location.shallow_color)
	water.set_shader_parameter("deep_color", location.deep_color)
	water.set_shader_parameter("sand_color", location.sand_color)
	water.set_shader_parameter("wet_sand_color", location.sand_color.darkened(0.15))
	water.set_shader_parameter("dune_color", location.sand_color.darkened(0.1).lerp(Color(0.6, 0.7, 0.35), 0.35))
	water.set_shader_parameter("floor_texture", _floor_texture)
	water.set_shader_parameter("floor_strength", FLOOR_STRENGTH if _floor_texture != null else 0.0)
	water.set_shader_parameter("sand_texture", _sand_texture)
	_seabed.set_water_colors(location.shallow_color, location.deep_color, FLOOR_STRENGTH)
	wader.set_water_colors(location.shallow_color, location.deep_color, FLOOR_STRENGTH)
	water.set_shader_parameter("sand_strength", 1.0 if _sand_texture != null else 0.0)

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


## Fish a zone holds (data/zones.csv).
func _zone_population(zone_index: int) -> int:
	return roundi(_zones[zone_index].population * SPOT_WIDTH / POPULATION_WIDTH)


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
	var gear := GameState.here().gear_level
	for fish in candidates:
		# The net reaches past the buoy line, but fish behind a closed line stay out of reach.
		if fish.zone.gear_level > gear \
				or fish.ground_position.distance_to(scoop) > wader.scoop_radius + fish.catch_radius():
			fish.hold_time = maxf(fish.hold_time - delta * HOLD_DECAY, 0.0)
			continue
		# The net lets fish through that the tank cannot hold yet; they still count as caught.
		if not Aquarium.can_ever_hold(GameState.here(), fish.species):
			fish.hold_time = 0.0
			if not fish.has_meta(&"counted"):
				fish.set_meta(&"counted", true)
				_count_too_big(fish)
			continue
		if live_well.is_full():
			fish.hold_time = 0.0
			continue
		fish.hold_time += delta
		var needed := CatchRules.struggle_seconds(fish.species, Aquarium.net_speed(GameState.here()))
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
	_record_catch(fish)


## A fish the tank cannot hold yet slips through the net: it counts for the Fishpedia, charting
## and goals, but stays in the water, and a bubble says which tank it needs.
func _count_too_big(fish: SwimmingFish) -> void:
	Juice.ripple(_effects, fish.position, fish.body_length * 0.5)
	_announce(_world_to_scene(fish.position + Vector2(0.0, -80.0)),
			tr("Needs a %s L tank") % NumberFormat.compact(Aquarium.tank_needed(fish.species)), WARNING_COLOR, 1.0)
	_record_catch(fish)


## Counts a catch: new species, charted zones and goals are announced.
func _record_catch(fish: SwimmingFish) -> void:
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
	var boardwalk := Boardwalk.new()
	boardwalk.setup(Rect2(PATH_X - PATH_HALF_WIDTH, PIER_TOP, PATH_HALF_WIDTH * 2.0, SHORE_Y - 30.0 - PIER_TOP))
	_squares_layer.add_child(boardwalk)
	_add_square("store", ActionSquare.Kind.STORE, STORE_SQUARE, STORE_HALF)
	_sell_square = _add_square("sell", ActionSquare.Kind.SELL, _booth_pad_center(0), BOOTH_PAD_HALF)
	_add_square("hire_seller", ActionSquare.Kind.BUY, _booth_pad_center(1), BOOTH_PAD_HALF)
	var dock := Sprite2D.new()
	dock.texture = DRONE_DOCK_TEXTURE
	dock.centered = false
	dock.offset = -DRONE_DOCK_ANCHOR
	dock.position = Iso.to_screen(DRONE_PAD)
	_squares_layer.add_child(dock)


## Painted props on the sand and in the water; they take part in the depth sorting.
func _place_decor() -> void:
	for entry: Array in DECOR:
		var water: String = entry[3]
		if not water.is_empty() and water != location.env:
			continue
		var texture: Texture2D = load("res://assets/sprites/props/%s.png" % entry[0])
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.offset = Vector2(0.0, -texture.get_height() * 0.5)
		sprite.scale = Vector2.ONE * (float(entry[2]) / texture.get_height())
		sprite.position = Iso.to_screen(entry[1])
		_entities.add_child(sprite)
	var gear_shop := GearShopNode.new()
	gear_shop.position = Iso.to_screen(GEAR_SHOP_POSITION)
	_entities.add_child(gear_shop)


## Titles and prices are set by _refresh_squares().
func _add_square(square_id: String, kind: ActionSquare.Kind, center: Vector2, half: Vector2 = SQUARE_HALF) -> ActionSquare:
	var new_square := ActionSquare.new()
	new_square.setup(square_id, kind, "", center, half)
	_squares_layer.add_child(new_square)
	_squares.append(new_square)
	return new_square


## Updates the pads: titles and prices of what can be bought next. Pads with nothing left to
## buy are hidden.
func _refresh_squares() -> void:
	var site := GameState.here()
	square_by_id("store").title = tr("Put in tank")
	var sell := square_by_id("sell")
	sell.title = tr("Sell fish")
	var hire := square_by_id("hire_seller")
	hire.ground_center = _booth_pad_center(1 + site.seller_count)
	hire.position = Iso.to_screen(hire.ground_center)
	_set_purchase(hire, "hire_seller", tr("Hire seller"), Selling.next_seller_cost(site),
			_prop("cashier_%d" % (site.seller_count % CASHIER_LOOKS + 1)))


## A painted prop from assets/sprites/props by name, or null if there is none.
func _prop(prop_name: String) -> Texture2D:
	var path := "res://assets/sprites/props/%s.png" % prop_name
	return load(path) if ResourceLoader.exists(path) else null


## `icon` is a picture of what is bought (see _prop()), or null.
func _set_purchase(target: ActionSquare, square_id: String, title: String, price: float, icon: Texture2D = null) -> void:
	target.id = square_id
	target.title = title
	target.icon = icon
	target.price = price
	target.paid = GameState.here().build_progress.get(square_id, 0.0)
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
			_action_timer = SELL_INTERVAL_S if _sell_one(on) else BUYER_WAIT_S
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
			_announce(at, tr("%d stored!") % _action_count, STORED_COLOR)
		ActionSquare.Kind.SELL:
			_announce(at, tr("%d sold\n+%s coins") % [_action_count, NumberFormat.compact(_action_total)], COIN_COLOR)
	_action_count = 0
	_action_total = 0.0


## Moves the topmost fish that fits into the tank, flying it there.
func _store_one() -> void:
	var site := GameState.here()
	var index := -1
	for i in range(live_well.count() - 1, -1, -1):
		if Aquarium.tank_for(site, DataRegistry.species[live_well.species_ids[i]]) != null:
			index = i
			break
	if index < 0:
		_finish_square_action()
		if live_well.count() > 0 and not _warned:
			_warned = true
			_announce(_world_to_scene(square_by_id("store").position + Vector2(0.0, -110.0)),
					tr("No room in the tank!") + "\n" + tr("Upgrade the tank."), WARNING_COLOR, 1.2)
			Haptics.bump()
		return
	var species_id := live_well.take_at(index)
	var art := wader.take_from_stack_at(index)
	var from := _world_to_scene(wader.stack_top_position())
	GameState.store_fish(species_id)
	_action_count += 1
	Juice.fly_fish(_popups, art, from, _world_to_scene(_tank_node.drop_point()), Wader.STACK_FISH_LENGTH * ZOOM,
			_on_fish_reached_tank)
	Sfx.play(&"pop", 1.0 + _action_count * 0.05, -6.0)
	if live_well.count() == 0:
		_finish_square_action()
	_update_hud()


func _on_fish_reached_tank() -> void:
	if not is_instance_valid(_tank_node):
		return
	Juice.splash(_effects, _tank_node.drop_point(), 5)
	_tank_node.bounce()
	Sfx.play(&"splash", 1.4, -10.0)
	Haptics.tick()


## Sells one grown fish from the tank on the "Sell fish" pad to the buyer waiting first in line,
## who walks off with it. Fish in the backpack are too young to sell: they must grow in the tank
## first. Returns true if a fish was sold.
func _sell_one(target: ActionSquare) -> bool:
	if Aquarium.adult_count(GameState.here()) == 0:
		_finish_square_action()
		if not _warned and _action_count == 0:
			_warned = true
			_announce(_world_to_scene(target.position + Vector2(0.0, -110.0)),
					tr("Only grown fish can be sold.\nGrow your catch in the tank first."), WARNING_COLOR, 1.2)
		return false
	var buyer: Customer = _booths[0] if not _booths.is_empty() else null
	if buyer == null or not buyer.is_waiting():
		return false
	var sale := GameState.sell_from_tank()
	_action_count += 1
	_action_total += sale[1]
	Juice.fly_coin(_popups, _world_to_scene(_tank_node.drop_point()), _wallet_position(), 12.0 * ZOOM)
	Sfx.play(&"coin", 1.0 + minf(_action_count, 20) * 0.04, -4.0)
	_tank_node.bounce()
	_shop_node.bounce()
	_serve_at(0)
	_update_hud()
	return true


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
	target.paid = GameState.here().build_progress.get(target.id, 0.0)
	if done:
		_complete_purchase(target)


func _complete_purchase(target: ActionSquare) -> void:
	var at := _world_to_scene(target.position + Vector2(0.0, -130.0))
	var message := ""
	if target.id == "hire_seller":
		GameState.hire_seller()
		_sync_shops()
		message = tr("Seller hired!\nSells grown fish for you")
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

## Shows the shop at its level, with a cashier for each seller.
func _sync_shops() -> void:
	var site := GameState.here()
	if _shop_node == null:
		_shop_node = ShopNode.new()
		_shop_node.position = Iso.to_screen(SHOP_POSITION)
		_entities.add_child(_shop_node)
	_shop_node.level = site.shop_level
	# One booth for the player and one per seller.
	while _booths.size() < 1 + site.seller_count:
		var booth := Booth.new()
		booth.setup(Vector2(_booth_x(_booths.size()), FIRST_BOOTH.y), _booths.size())
		_entities.add_child(booth)
		_booth_nodes.append(booth)
		_booths.append(null)
	for booth in _booth_nodes:
		booth.level = site.shop_level
	_move_queue()


## A seller sold a fish: coins pop up at the shop and the buyer at a seller's booth leaves with it.
func _on_fish_sold_by_seller(_species_id: String, price: float) -> void:
	var at_booth := 1
	for booth in range(1, _booths.size()):
		if _booths[booth] != null and _booths[booth].is_waiting():
			at_booth = booth
			break
	var at := _world_to_scene(_booth_nodes[mini(at_booth, _booth_nodes.size() - 1)].position + Vector2(0.0, -60.0))
	Juice.popup_text(_popups, at + Vector2(0.0, -40.0), "+" + NumberFormat.compact(price), 36, COIN_COLOR, 0.2)
	Juice.fly_coin(_popups, at, _wallet_position(), 9.0 * ZOOM)
	Sfx.play(&"coin", 1.3, -10.0)
	if at_booth < _booths.size() and _booths[at_booth] != null and _booths[at_booth].is_waiting():
		_serve_at(at_booth)
	_update_hud()


## The buyer at `booth` takes the fish just sold and walks off up the beach; the booth is free
## again.
func _serve_at(booth: int) -> void:
	_booths[booth].serve(Vector2(_booths[booth].ground_position.x, CUSTOMER_EXIT_Y))
	_booths[booth] = null
	_booth_nodes[booth].bounce()


## Buyers line up at the shop from the start at a steady pace, sellers or not, until the line
## reaches past the edge of the screen. The first in line goes to the next free booth.
func _update_customers(delta: float) -> void:
	_customer_timer -= delta
	if _customer_timer <= 0.0 and _queue.size() < _queue_capacity():
		_customer_timer = CUSTOMER_INTERVAL_S
		add_buyer()
	for booth in _booths.size():
		if _queue.is_empty() or not _queue[0].is_waiting():
			return
		# The player's booth only takes buyers while the player is there to sell.
		if _booths[booth] != null or (booth == 0 and _current_square != _sell_square):
			continue
		var buyer: Customer = _queue.pop_front()
		buyer.move_to(_booth_spot(booth))
		_booths[booth] = buyer
		_move_queue()


## A new buyer walks up to the end of the line. Returns them.
func add_buyer() -> Customer:
	var customer := Customer.new()
	var entry := CUSTOMER_ENTRY + Vector2(0.0, -rng.randf_range(0.0, 200.0))
	customer.setup(rng.randi(), entry, _queue_spot(_queue.size()), Vector2(entry.x, CUSTOMER_EXIT_Y))
	_entities.add_child(customer)
	_queue.append(customer)
	return customer


## How many buyers fit in line: it goes on up the beach until it is out of view behind its top.
func _queue_capacity() -> int:
	var count := 1
	while _queue_spot(count).y > BEACH_TOP - CAMERA_OVERSCROLL - QUEUE_SPACING * 2.0:
		count += 1
	return count


## Ground position of place `index` in the queue: coming down from the north, the first one
## behind the player's booth.
func _queue_spot(index: int) -> Vector2:
	return Vector2(FIRST_BOOTH.x, FIRST_BOOTH.y + Booth.BUYER_OFFSET.y - QUEUE_SPACING * (index + 1))


## Centre of the pad in front of booth `index` (which need not be built yet).
func _booth_pad_center(index: int) -> Vector2:
	return Vector2(_booth_x(index), FIRST_BOOTH.y) + BOOTH_PAD_OFFSET


## Ground x of booth `index`: the player's at FIRST_BOOTH, the sellers' further west.
func _booth_x(index: int) -> float:
	return FIRST_BOOTH.x if index == 0 else FIRST_BOOTH.x - FIRST_SELLER_GAP - BOOTH_SPACING * (index - 1)


## Ground position where the buyer stands at `booth`: behind its desk, facing the player.
func _booth_spot(booth: int) -> Vector2:
	return _booth_nodes[booth].buyer_spot()


## Everyone in line moves up to their place (also when the shop got bigger).
func _move_queue() -> void:
	for i in _queue.size():
		_queue[i].move_to(_queue_spot(i))

#endregion


#region Drones

## Matches the drones to the number bought here; each flies over its charted zone. Drones at
## other locations keep working there (GameState).
func _sync_drones() -> void:
	var state := GameState.state
	var site := GameState.here()
	for drone in _drones:
		drone.queue_free()
	_drones.clear()
	for i in site.drone_count:
		var zone := Automation.drone_zone(state, site, i)
		if zone == null:
			continue
		var drone := Drone.new()
		drone.setup(DRONE_PAD, zone, _zone_areas[_zones.find(zone)], Automation.drone_capacity(i), 1.0 + DRONE_SIZE_STEP * i, i)
		drone.delivered.connect(_on_drone_delivered)
		_entities.add_child(drone)
		_drones.append(drone)


func _update_drones(delta: float) -> void:
	for drone in _drones:
		var lifted := drone.simulate(delta, _fish, _drone_can_take, _drone_tank_full)
		if drone.task == Drone.Task.LIFT and drone.target != null:
			# The fish wriggles in the drone's net.
			drone.target.hold_time = maxf(drone.target.hold_time, 0.1)
		if lifted != null:
			_fish.erase(lifted)
			lifted.play_caught(drone.net_position())
			Juice.splash(_effects, lifted.position, 6)
			Sfx.play(&"pop", 1.2, -12.0)
	if is_instance_valid(_tank_node):
		_tank_node.drones_resting = _drones.any(func(drone: Drone) -> bool: return drone.task == Drone.Task.REST)


## Drones only take known species that still fit into the tank next to what all drones carry.
func _drone_can_take(species_id: String) -> bool:
	return Automation.drone_can_catch(GameState.state, species_id) 			and Automation.drone_fits(GameState.here(), DataRegistry.species[species_id], _drone_cargo_litres())


func _drone_tank_full(zone: ZoneDef) -> bool:
	return Automation.drone_tank_full(GameState.state, GameState.here(), zone, _drone_cargo_litres())


## Tank space the fish in the drones' nets will take.
func _drone_cargo_litres() -> float:
	var litres := 0.0
	for drone in _drones:
		for art in drone.cargo:
			litres += art.species.space_l
	return litres


## A drone landed with its catch: into the tank while there is room, the rest is sold.
func _on_drone_delivered(drone: Drone, species_ids: Array[String]) -> void:
	var from := _world_to_scene(drone.net_position())
	for id in species_ids:
		if GameState.store_fish(id) != null:
			Juice.fly_fish(_popups, _art_for(id), from, _world_to_scene(_tank_node.drop_point()), Drone.ICON_LENGTH * ZOOM,
					_on_fish_reached_tank)
		else:
			GameState.sell_fish(id)
			Juice.fly_coin(_popups, from, _wallet_position(), 9.0 * ZOOM)
	Sfx.play(&"pop", 1.4, -10.0)
	_update_hud()

#endregion


#region Gear shop

## The gear shop cannot be walked on: the wader is pushed back out to the nearest wall. Walking
## into its door goes inside.
func _update_gear_shop() -> void:
	var shop := Rect2(GEAR_SHOP_POSITION - GEAR_SHOP_HALF, GEAR_SHOP_HALF * 2.0).grow(GEAR_SHOP_MARGIN)
	var at := wader.ground_position
	if _in_store or not shop.has_point(at):
		return
	if absf(at.x - GEAR_SHOP_DOOR_X) <= GEAR_SHOP_DOOR_HALF_WIDTH and at.y > shop.end.y - GEAR_SHOP_MARGIN:
		_in_store = true
		wader.stop()
		store_requested.emit()
		return
	var to_west := at.x - shop.position.x
	var to_east := shop.end.x - at.x
	var to_north := at.y - shop.position.y
	var to_south := shop.end.y - at.y
	var nearest := minf(minf(to_west, to_east), minf(to_north, to_south))
	if nearest == to_west:
		at.x = shop.position.x
	elif nearest == to_east:
		at.x = shop.end.x
	elif nearest == to_north:
		at.y = shop.position.y
	else:
		at.y = shop.end.y
	wader.ground_position = at
	wader.position = Iso.to_screen(at)


## Back from the upgrade store: shows what was bought and puts the wader in front of the door.
func return_from_store() -> void:
	_in_store = false
	_rebuild_from_state()
	wader.stop()
	wader.ground_position = Vector2(GEAR_SHOP_DOOR_X, GEAR_SHOP_POSITION.y + GEAR_SHOP_HALF.y + GEAR_SHOP_MARGIN + 120.0)
	wader.position = Iso.to_screen(wader.ground_position)
	_update_camera(0.0, true)

#endregion


#region Travel

## Travels to another location from the World map: unlocks it first if needed. The backpack
## stays at this location's beach until the player comes back.
func _on_travel_chosen(def: LocationDef) -> void:
	var state := GameState.state
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
	# In the upgrade store, the store shows the banner.
	if not is_visible_in_tree():
		return
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


## Little rings around the legs while wading (not under water).
func _update_wake(delta: float) -> void:
	if not wader.is_walking() or wader.waterline() <= Wader.SUBMERGED or wader.waterline() >= Wader.DRY:
		_wake_timer = 0.0
		return
	_wake_timer -= delta
	if _wake_timer <= 0.0:
		_wake_timer = WAKE_INTERVAL_S
		Juice.ripple(_effects, wader.position + Vector2(0.0, wader.waterline()), 60.0)
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
	var site := GameState.here()
	_backpack_label.text = tr("Backpack  %d / %d") % [live_well.count(), live_well.capacity]
	_backpack_bar.max_value = live_well.capacity
	_backpack_bar.value = live_well.count()
	var adults := Aquarium.adult_count(site)
	_tank_label.text = tr("Tank  %s / %s L  ·  %d grown  ·  worth %s") % [
		NumberFormat.compact(Aquarium.used_space(site.tank)), NumberFormat.compact(Aquarium.capacity(site.tank)), adults,
		NumberFormat.compact(Aquarium.tank_value(site))]
	if live_well.is_full():
		_hint_label.text = tr("Backpack full! Grow the fish in the tank, then sell them.")
	elif live_well.count() > 0:
		_hint_label.text = tr("Grow your catch in the tank. Only grown fish can be sold.")
	elif adults > 0 and site.seller_count == 0:
		_hint_label.text = tr("Grown fish are worth 3 times as much. Sell them at the shop!")
	else:
		_hint_label.text = tr("Touch and hold to wade there and catch fish.")


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


#endregion
