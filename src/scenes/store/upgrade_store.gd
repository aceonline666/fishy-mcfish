class_name UpgradeStore
extends Control
## The gear shop of the current location (GameState.here()), entered through its door on the
## beach: a room in isometric view where the wader buys the upgrades by standing on their pads,
## as on the beach: diving gear and nets on the west side in front of their shelves, the backpack
## and drones on the east side, bigger tanks (in front of a shelf) and the market upgrade (at a
## desk) at the back, and the doormat back to the beach at the front. The pads keep wide gaps, so nothing is bought by accident on the way.
## Every location has one; the upgrades are bought for that location. The beach keeps running
## behind it (Main), and its drones keep fishing (GameState.in_store).

## The wader walked out through the door.
signal left
## The wader travelled to the next beach (GameState already points there).
signal travelled

const ZOOM := 1.5
const CAMERA_SMOOTHING := 6.0
const CAMERA_OVERSCROLL := 160.0
## Screen pixels covered by the HUD bars at the top and bottom.
const PLAY_MARGIN_TOP := 170.0
const PLAY_MARGIN_BOTTOM := 190.0
const WALK_SPEED := 1.5

#region Layout (on the layout grid, Grid; the front wall with the door is at row 0)
## The room covers whole cells of the layout grid (Grid), given by the cell at its north-west
## corner. The wader keeps one cell off the back walls (north and west), where the displays
## stand. The pads are one cell each but off the cell grid: each sits a quarter cell further
## towards the room's middle than the cell grid would put it, to leave the displays room. Their
## spots are their middles, in cells (Grid.center of cell 1,-4 is spot 1.5,-3.5). The doormat at
## the front (StoreRoom.MAT, about cell 3,-1) leads out.
##
##   spot y   x 1.75   3.5      5.25
##    -5.25     tank     market   travel
##    -3.5      gear     .        backpack
##    -1.75     net      .        drone
##    -1.5               entry (3.3)
##    -0.4               mat (3.3)
const ROOM_CELL := Vector2i(0, -7)
const ROOM_SIZE := Vector2i(7, 7)
const GEAR_SPOT := Vector2(1.75, -3.5)
const NET_SPOT := Vector2(1.75, -1.75)
const BACKPACK_SPOT := Vector2(5.25, -3.5)
const DRONE_SPOT := Vector2(5.25, -1.75)
const TANK_SPOT := Vector2(1.75, -5.25)
const SHOP_UPGRADE_SPOT := Vector2(3.5, -5.25)
## Travel to the next beach: unlocks it (paying its fee, once its goal is reached) and goes there.
## The other way is the World map on the beach.
const TRAVEL_SPOT := Vector2(5.25, -5.25)
## The wader comes in here, just north of the doormat.
const ENTRY := Vector2(3.3, -1.5) * Grid.UNIT
## Show the layout grid over the room, to lay things out.
const SHOW_GRID := false
## The displays behind the pads, showing what they sell: sprite (assets/sprites/props; the
## paintings from art_source/store/fixture_sprite_prompts.md, brought in by
## tools/import_store_art.py), where it stands on the
## floor (in cells, free of the grid: placed where it looks good), the point in the sprite that
## stands there, the sprite's pixels per cell edge across (its scale), and whether it is
## mirrored. The room's painted walls stand about a quarter cell inside the grid's room edge.
## The pads are drawn over the displays, so a display keeps clear of its pad on screen.
const FIXTURES: Array[Array] = [
	["gear_display.png", Vector2(0.6, -3.75), Vector2(652.0, 873.0), 430.0, false],
	["net_display.png", Vector2(0.75, -1.75), Vector2(628.0, 1102.0), 600.0, false],
	["tank_display.png", Vector2(0.75, -6.33), Vector2(635.0, 808.0), 590.0, false],
	["drone_display.png", Vector2(6.6, -1.5), Vector2(625.0, 812.0), 650.0, false],
	["basket_display.png", Vector2(6.55, -3.5), Vector2(510.0, 448.0), 650.0, false],
	["selling_display.png", Vector2(3.5, -6.6), Vector2(457.0, 772.0), 560.0, true],
]
## Screen pixels across one cell edge at ground scale.
const CELL_EDGE_ACROSS := Grid.UNIT * 0.70710678
#endregion

## Seconds the wader stands on the doormat before walking out.
const DOOR_DELAY_S := 0.3
## Seconds between payments on a pad; each pays this share of the price.
const PAY_INTERVAL_S := 0.05
const PAY_SHARE := 0.04
## Each better net is this much wider (as on the beach).
const NET_RADIUS_STEP := 0.12
const COMBO_COLOR := Color(1.0, 0.85, 0.2)
const COIN_COLOR := Color(1.0, 0.86, 0.3)
const WARNING_COLOR := Color(1.0, 0.55, 0.45)
const BACKGROUND := Color(0.1, 0.12, 0.18)
const COINS_ICON: Texture2D = preload("res://assets/ui/icon_coins.png")

var wader := Wader.new()
var walk_area: PlayArea

var _world := Node2D.new()
var _floor := StoreRoom.new()
var _squares_layer := Node2D.new()
var _entities := Node2D.new()
var _effects := Node2D.new()
var _popups := Control.new()
var _goal_banner := GoalBanner.new()
var tutorial := TutorialGuide.new()
var _squares: Array[ActionSquare] = []
var _money_label := Label.new()
var _coin_icon := TextureRect.new()
var _title_label := Label.new()
var _hint_label := Label.new()
var _camera := Vector2.ZERO
var _holding := false
var _current_square: ActionSquare
var _action_timer := 0.0
var _action_count := 0
var _warned := false
## After a purchase the pad turns into the next offer; it only takes coins again once the wader
## has stepped off and back on.
var _purchase_done := false
## Seconds the wader has stood on the doormat; it leaves once only.
var _mat_time := 0.0
var _left := false
var _shown_money := 0.0
var _money_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Layers.put(background, Layers.BACKGROUND)
	add_child(background)
	_world.scale = Vector2.ONE * ZOOM
	_world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_world)
	_floor.setup(Grid.rect(ROOM_CELL, ROOM_SIZE))
	Layers.put(_world, Layers.FLOOR)
	_world.add_child(_floor)
	Layers.put(_squares_layer, Layers.PADS)
	_world.add_child(_squares_layer)
	_entities.y_sort_enabled = true
	Layers.put(_entities, Layers.OBJECTS)
	_world.add_child(_entities)
	Layers.put(_effects, Layers.EFFECTS)
	_world.add_child(_effects)
	_entities.add_child(wader)
	_build_hud()
	_popups.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popups.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_popups)
	# At the bottom, clear of the tips over the pads.
	tutorial.bottom_offset = PLAY_MARGIN_BOTTOM + 10.0
	add_child(tutorial)
	_goal_banner.top_offset = PLAY_MARGIN_TOP + 260.0
	_goal_banner.wallet = _coin_icon
	_goal_banner.coin_radius = 12.0 * ZOOM
	add_child(_goal_banner)
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.achievement_reached.connect(_on_achievement_reached)
	left.connect(func() -> void: Tutorial.complete(GameState.state, Tutorial.Step.SHOP))
	resized.connect(_update_camera.bind(0.0, true))

	walk_area = PlayArea.new(Grid.rect(ROOM_CELL + Vector2i.ONE, ROOM_SIZE - Vector2i.ONE))
	if SHOW_GRID:
		var grid := GridOverlay.new()
		grid.setup(Rect2i(ROOM_CELL, ROOM_SIZE))
		_squares_layer.add_child(grid)
	_add_square("upgrade_gear", ActionSquare.Kind.BUY, GEAR_SPOT)
	_add_square("upgrade_net", ActionSquare.Kind.BUY, NET_SPOT)
	_add_square("upgrade_backpack", ActionSquare.Kind.BUY, BACKPACK_SPOT)
	_add_square("buy_drone", ActionSquare.Kind.BUY, DRONE_SPOT)
	_add_square("upgrade_tank", ActionSquare.Kind.BUY, TANK_SPOT)
	_add_square("upgrade_shop", ActionSquare.Kind.BUY, SHOP_UPGRADE_SPOT)
	_add_square("travel_next", ActionSquare.Kind.BUY, TRAVEL_SPOT)
	_place_fixtures()
	var site := GameState.here()
	wader.in_water = false
	wader.speed_multiplier = WALK_SPEED
	wader.gear_level = site.gear_level
	wader.net_level = site.net_level
	wader.scoop_radius = Wader.SCOOP_RADIUS * (1.0 + NET_RADIUS_STEP * (site.net_level - 1))
	for id in site.backpack:
		wader.carried.append(FishArt.for_species(DataRegistry.species[id]))
	wader.ground_position = ENTRY
	wader.facing = Vector2(0.0, -1.0)
	wader.position = Iso.to_screen(ENTRY)
	_refresh_squares()
	_show_money(GameState.state.money)
	_update_texts()
	_update_camera(0.0, true)


## The language changed: redo every text set in code.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_squares()
		_update_texts()


func _process(delta: float) -> void:
	wader.simulate(delta, walk_area)
	_update_camera(delta)
	_update_tutorial()
	_update_squares(delta)
	_update_mat(delta)


## Touch to walk towards the finger, drag to steer; the wader stops when the finger lifts.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index != 0:
			return
		_holding = touch.pressed
		if touch.pressed:
			wader.walk_to(scene_to_ground(touch.position))
		else:
			wader.stop()
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == 0 and _holding:
			wader.walk_to(scene_to_ground(drag.position))
			accept_event()


#region Public helpers (also used by tests)

## The visible pad with this id, or null.
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
	return _world.get_transform() * Iso.to_screen(ground)

#endregion


func _build_hud() -> void:
	var hud := SafeAreaContainer.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(layout)
	var top_bar := PanelContainer.new()
	layout.add_child(top_bar)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(row)
	_coin_icon.texture = COINS_ICON
	_coin_icon.custom_minimum_size = Vector2(100.0, 84.0)
	_coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_coin_icon)
	_money_label.theme_type_variation = &"TitleLabel"
	_money_label.add_theme_font_size_override("font_size", 56)
	_money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_money_label)
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_title_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(spacer)
	var bottom_bar := PanelContainer.new()
	layout.add_child(bottom_bar)
	_hint_label.add_theme_font_size_override("font_size", 32)
	_hint_label.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_bar.add_child(_hint_label)


func _update_texts() -> void:
	_title_label.text = "%s · %s" % [tr(GameState.here().location().name), tr("Fishing gear")]
	_hint_label.text = tr("Stand on a pad to buy. Upgrades are for this beach only.")


## The displays; they take part in the depth sorting, and the wader can walk behind them.
func _place_fixtures() -> void:
	for entry: Array in FIXTURES:
		var fixture := Sprite2D.new()
		fixture.texture = load("res://assets/sprites/props/%s" % entry[0])
		fixture.centered = false
		fixture.offset = -entry[2]
		fixture.scale = Vector2.ONE * CELL_EDGE_ACROSS / entry[3]
		fixture.flip_h = entry[4]
		if entry[4]:
			fixture.offset.x = -(fixture.texture.get_width() - entry[2].x)
		fixture.position = Iso.to_screen(entry[1] * Grid.UNIT)
		_entities.add_child(fixture)
		wader.covers.append(Layers.sprite_cover(fixture))


#region Camera

## Follows the wader, keeping the view over the room.
func _update_camera(delta: float, snap: bool = false) -> void:
	if size.x <= 0.0:
		return
	var focus := Iso.to_screen(wader.ground_position) + Vector2(0.0, -60.0)
	var view_center := Vector2(size.x * 0.5, (PLAY_MARGIN_TOP + size.y - PLAY_MARGIN_BOTTOM) * 0.5)
	var target := view_center - focus * ZOOM
	var bounds := _floor.screen_bounds().grow(CAMERA_OVERSCROLL)
	target.x = _clamp_axis(target.x, size.x - bounds.end.x * ZOOM, -bounds.position.x * ZOOM)
	target.y = _clamp_axis(target.y, size.y - PLAY_MARGIN_BOTTOM - bounds.end.y * ZOOM, PLAY_MARGIN_TOP - bounds.position.y * ZOOM)
	_camera = target if snap else _camera.lerp(target, 1.0 - exp(-CAMERA_SMOOTHING * delta))
	_world.position = _camera


## Clamps a camera offset; centres it if the room is smaller than the view on this axis.
func _clamp_axis(value: float, low: float, high: float) -> float:
	return clampf(value, low, high) if low <= high else (low + high) * 0.5

#endregion


#region Pads

## A pad with its middle on `spot` (in cells).
func _add_square(square_id: String, kind: ActionSquare.Kind, spot: Vector2) -> ActionSquare:
	var new_square := ActionSquare.new()
	new_square.setup(square_id, kind, "", spot * Grid.UNIT)
	_squares_layer.add_child(new_square)
	_squares.append(new_square)
	return new_square


func _square_by_id(square_id: String) -> ActionSquare:
	for s in _squares:
		if s.id == square_id:
			return s
	return null


## Titles and prices of what can be bought next. Pads with nothing left to buy are hidden.
func _refresh_squares() -> void:
	var state := GameState.state
	var site := GameState.here()
	var tank_square := _square_by_id("upgrade_tank")
	_set_purchase(tank_square, tr("Bigger tank"), Aquarium.tank_upgrade_cost(site), _prop("tank_%d" % (site.tank.level + 1)))
	if site.tank.level < DataRegistry.tank_levels.size():
		tank_square.subtitle = tr("Fish grow %s× as fast") % String.num(DataRegistry.tank_levels[site.tank.level].speed, 2)
	# Each shop level makes room for more sellers.
	var shop := _square_by_id("upgrade_shop")
	_set_purchase(shop, tr("More selling space"), Selling.shop_upgrade_cost(site), _prop("shop_%d" % (site.shop_level + 1)))
	if site.shop_level < DataRegistry.shop_levels.size():
		var more := int(DataRegistry.shop_levels[site.shop_level].capacity) - Selling.seller_slots(site)
		shop.subtitle = tr("+1 seller") if more == 1 else tr("+%d sellers") % more
	_set_purchase(_square_by_id("upgrade_backpack"), tr("Bigger basket"), Aquarium.backpack_upgrade_cost(site),
			_wader_prop("basket_%d" % (site.backpack_level + 1)))
	var next_net := DataRegistry.net_levels[mini(site.net_level, DataRegistry.net_levels.size() - 1)]
	_set_purchase(_square_by_id("upgrade_net"), tr(next_net.name), Aquarium.net_upgrade_cost(site),
			_wader_prop("net_%d" % (site.net_level + 1)))
	var next_gear := DataRegistry.gear_levels[mini(site.gear_level, DataRegistry.gear_levels.size() - 1)]
	_set_purchase(_square_by_id("upgrade_gear"), tr(next_gear.name), Aquarium.gear_upgrade_cost(site),
			_prop("gear_%d" % (site.gear_level + 1)))
	# Drone N fishes zone N, so it is greyed out until that zone is charted.
	var drone_square := _square_by_id("buy_drone")
	var drone_available := Automation.next_drone_available(state, site)
	_set_purchase(drone_square, tr("Buy drone"), Automation.next_drone_cost(site), _prop("drone_%d" % (site.drone_count + 1)))
	drone_square.disabled = not drone_available
	drone_square.subtitle = ""
	for zone in DataRegistry.zones_in(site.location_id):
		if zone.order == site.drone_count + 1:
			drone_square.subtitle = tr(zone.name) if drone_available else tr("Chart first: %s") % tr(zone.name)
	# The next beach: free once open, its travel fee once its goal is reached, greyed out before.
	var travel := _square_by_id("travel_next")
	var next := Travel.next_location(state)
	if next == null:
		_set_purchase(travel, "", -1.0)
	else:
		var open := Travel.is_unlocked(state, next)
		_set_purchase(travel, tr("Travel to next beach"), 0.0 if open else next.travel_cost, _prop("location_%s" % next.id))
		travel.disabled = not open and not Travel.can_unlock(state, next)
		travel.subtitle = tr("Goal: %s") % tr(Travel.unlock_goal(next).name) if travel.disabled else tr(next.name)


## A wader sprite from assets/sprites/wader by name, or null if there is none.
func _wader_prop(prop_name: String) -> Texture2D:
	var path := "res://assets/sprites/wader/%s.png" % prop_name
	return load(path) if ResourceLoader.exists(path) else null


## A painted prop from assets/sprites/props by name, or null if there is none.
func _prop(prop_name: String) -> Texture2D:
	var path := "res://assets/sprites/props/%s.png" % prop_name
	return load(path) if ResourceLoader.exists(path) else null


func _set_purchase(target: ActionSquare, title: String, price: float, icon: Texture2D = null) -> void:
	target.title = title
	target.icon = icon
	target.price = price
	target.paid = GameState.here().build_progress.get(target.id, 0.0)
	target.visible = price >= 0.0


## The visible pad the wader stands on.
func _square_under_wader() -> ActionSquare:
	for s in _squares:
		if s.visible and s.contains(wader.ground_position):
			return s
	return null


func _update_squares(delta: float) -> void:
	var on := _square_under_wader()
	for s in _squares:
		s.active = s == on
	if on != _current_square:
		_current_square = on
		_action_timer = 0.0
		_action_count = 0
		_warned = false
		_purchase_done = false
	if on == null or _purchase_done or on.disabled:
		return
	_action_timer -= delta
	if _action_timer > 0.0:
		return
	_action_timer = PAY_INTERVAL_S
	_pay_into(on)


## Standing on the doormat for DOOR_DELAY_S walks out to the beach.
func _update_mat(delta: float) -> void:
	if _left or not _floor.mat().has_point(wader.ground_position):
		_mat_time = 0.0
		return
	_mat_time += delta
	if _mat_time >= DOOR_DELAY_S:
		_left = true
		left.emit()


## Pays a slice of the price; completes the purchase once fully paid.
func _pay_into(target: ActionSquare) -> void:
	if target.price <= 0.0:
		_complete_purchase(target)
		return
	if GameState.state.money < 0.01:
		if not _warned:
			_warned = true
			_announce(ground_to_scene(target.ground_center) + Vector2(0.0, -110.0 * ZOOM), tr("Not enough coins"), WARNING_COLOR, 0.6)
		return
	var before := GameState.state.money
	var done := GameState.pay_into(target.id, maxf(target.price * PAY_SHARE, 1.0), target.price)
	if GameState.state.money < before:
		Juice.fly_coin(_popups, ground_to_scene(wader.ground_position) + Vector2(0.0, -120.0 * ZOOM),
				ground_to_scene(target.ground_center), 10.0 * ZOOM)
		_action_count += 1
		Sfx.play(&"coin", 0.9 + minf(_action_count, 25) * 0.02, -10.0)
	target.paid = GameState.here().build_progress.get(target.id, 0.0)
	if done:
		_complete_purchase(target)


func _complete_purchase(target: ActionSquare) -> void:
	if target.id == "travel_next":
		_travel_next()
		return
	var state := GameState.state
	var site := GameState.here()
	var message := ""
	match target.id:
		"upgrade_tank":
			GameState.upgrade_tank()
			message = "%s!\n%s L" % [tr(DataRegistry.tank_levels[site.tank.level - 1].name), NumberFormat.compact(Aquarium.capacity(site.tank))]
		"upgrade_backpack":
			GameState.upgrade_backpack()
			message = tr("Bigger basket!\n%d fish") % Aquarium.backpack_capacity(site)
		"buy_drone":
			GameState.buy_drone()
			message = tr("New drone!\nIt fishes here: %s") % tr(Automation.drone_zone(state, site, site.drone_count - 1).name)
		"upgrade_shop":
			GameState.upgrade_shop()
			var more := Selling.seller_slots(site) - int(DataRegistry.shop_levels[site.shop_level - 2].capacity)
			message = tr("More selling space!\nRoom for one more seller") if more == 1 \
					else tr("More selling space!\nRoom for %d more sellers") % more
		"upgrade_net":
			GameState.upgrade_net()
			wader.net_level = site.net_level
			wader.scoop_radius = Wader.SCOOP_RADIUS * (1.0 + NET_RADIUS_STEP * (site.net_level - 1))
			message = tr("%s!\nBig fish are landed faster") % tr(DataRegistry.net_levels[site.net_level - 1].name)
		"upgrade_gear":
			GameState.upgrade_gear()
			wader.gear_level = site.gear_level
			var zone := Charting.deepest_open_zone(site.location_id, site.gear_level)
			message = tr("%s!\nNow you can reach: %s") % [tr(DataRegistry.gear_levels[site.gear_level - 1].name), tr(zone.name)]
	_announce(ground_to_scene(target.ground_center) + Vector2(0.0, -130.0 * ZOOM), message, COMBO_COLOR, 1.0)
	Sfx.play(&"ding", 1.0)
	Sfx.play(&"ding", 1.5, -6.0)
	Juice.splash(_effects, target.position, 18)
	Haptics.bump()
	_action_count = 0
	_purchase_done = true
	Tutorial.complete(GameState.state, Tutorial.Step.SHOP)
	_refresh_squares()
	GameState.check_achievements()
	SaveSystem.save_game()


## The travel pad is paid (or free): opens the next beach and goes there.
func _travel_next() -> void:
	var state := GameState.state
	var next := Travel.next_location(state)
	_purchase_done = true
	if not Travel.is_unlocked(state, next):
		GameState.open_location(next)
	GameState.travel_to(next)
	GameState.check_achievements()
	SaveSystem.save_game()
	travelled.emit()

#endregion


#region Tutorial

## On the first visit (Tutorial.Step.SHOP) a card welcomes the player and a tip over each pad says
## what it is for, until something is bought or the player leaves.
func _update_tutorial() -> void:
	if GameState.state.tutorial_step != Tutorial.Step.SHOP:
		tutorial.hide_message()
		tutorial.clear_tips()
		return
	tutorial.allow_card(not _goal_banner.is_showing())
	tutorial.show_message(tr("Welcome to the gear shop!"),
			tr("Spend your coins here."))
	var tips: Array[Array] = []
	for s in _squares:
		if s.visible and not _pad_tip(s.id).is_empty():
			# Over the pad's north corner, the top one on screen, clear of its picture and text.
			tips.append([ground_to_scene(s.ground_center - Vector2.ONE * Grid.UNIT * 0.5), _pad_tip(s.id)])
	tutorial.show_tips(tips)


## What a pad is for, in a few words.
func _pad_tip(square_id: String) -> String:
	match square_id:
		"upgrade_backpack":
			return tr("More fish at once")
		"upgrade_net":
			return tr("Big fish faster")
		"upgrade_gear":
			return tr("Swim further out")
		"upgrade_tank":
			return tr("Room for more fish")
		"upgrade_shop":
			return tr("More sellers")
		"buy_drone":
			return tr("Fishes for you")
		"travel_next":
			return tr("A new beach to fish")
	return ""

#endregion


#region Effects

func _on_achievement_reached(def: AchievementDef) -> void:
	_goal_banner.celebrate(def)


func _announce(at: Vector2, text: String, color: Color, hold_s: float = 0.35) -> void:
	Juice.popup_text(_popups, at, text, 52, color, hold_s)


func _on_money_changed(money: float) -> void:
	if _money_tween:
		_money_tween.kill()
	_money_tween = create_tween()
	_money_tween.tween_method(_show_money, _shown_money, money, 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _show_money(value: float) -> void:
	_shown_money = value
	_money_label.text = NumberFormat.compact(value)

#endregion
