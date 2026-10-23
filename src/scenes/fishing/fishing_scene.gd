extends Control
## The fishing screen. Drag the net through the water to catch fish, lift your finger to land
## the haul in the live-well, then sell the catch.
## M1 greybox: one hard-coded layer, and "Sell catch" stands in for the harbour and tanks of M2.

const LAYER_TITLE := "North Sea · Pier"
## Spawn weights for the pier layer. Moves to data/layers.csv in M3.
const PIER_SPAWNS: Dictionary[String, float] = {
	"european_sprat": 50.0,
	"lesser_sand_eel": 30.0,
	"atlantic_herring": 30.0,
	"atlantic_mackerel": 6.0,
}
const TARGET_POPULATION := 16
const SPAWN_INTERVAL_S := 0.7
const NET_CAPACITY := 5
const LIVE_WELL_CAPACITY := 12
## On touch screens the net sits above the finger so it stays visible.
const TOUCH_NET_OFFSET := Vector2(0.0, -90.0)
const NET_FOLLOW_SHARPNESS := 30.0
## Fish start fleeing when the net comes within this many net radii.
const FLEE_RADIUS_FACTOR := 1.8
## How much faster an interrupted struggle drains than it builds up.
const HOLD_DECAY := 2.0
const TRAIL_SECONDS := 0.22
const SWIM_MARGIN_TOP := 220.0
const SWIM_MARGIN_BOTTOM := 420.0
const COMBO_COLOR := Color(1.0, 0.85, 0.2)
const NEW_SPECIES_COLOR := Color(0.6, 1.0, 0.7)
const COIN_COLOR := Color(1.0, 0.86, 0.3)

## Tests switch this off to control exactly which fish exist.
@export var auto_spawn := true

var rng := RandomNumberGenerator.new()
var live_well := LiveWell.new(LIVE_WELL_CAPACITY)

var _fish: Array[SwimmingFish] = []
var _spawns := SpawnTable.new(PIER_SPAWNS)
var _spawn_timer := 0.0
var _dragging := false
var _net_target := Vector2.ZERO
var _trail_ages := PackedFloat32Array()
var _shake := 0.0
var _shown_money := 0.0
var _money_tween: Tween
var _sell_pulse: Tween

@onready var _water: ColorRect = $Water
@onready var _world: Node2D = $World
@onready var _trail: Line2D = $World/Trail
@onready var _fish_layer: Node2D = $World/Fish
@onready var _effects: Node2D = $World/Effects
@onready var _net: FishingNet = $World/Net
@onready var _popups: Control = $Popups
@onready var _money_label: Label = %MoneyLabel
@onready var _location_label: Label = %LocationLabel
@onready var _live_well_label: Label = %LiveWellLabel
@onready var _live_well_bar: ProgressBar = %LiveWellBar
@onready var _sell_button: Button = %SellButton


func _ready() -> void:
	rng.randomize()
	_net.capacity = NET_CAPACITY
	_net.hide()
	_location_label.text = LAYER_TITLE
	_sell_button.pressed.connect(_on_sell_pressed)
	EventBus.money_changed.connect(_on_money_changed)
	resized.connect(_on_resized)
	_show_money(GameState.state.money)
	_update_hud()
	_populate.call_deferred()


func _process(delta: float) -> void:
	_update_shake(delta)
	if _dragging:
		var target := _net_target - _world.position
		_net.position = _net.position.lerp(target, 1.0 - exp(-NET_FOLLOW_SHARPNESS * delta))
	_update_trail(delta)

	var bounds := _swim_bounds()
	var threat_radius := _net.radius * FLEE_RADIUS_FACTOR if _dragging else 0.0
	for fish in _fish:
		fish.simulate(delta, bounds, _net.position, threat_radius, _fish)
	if _dragging:
		_check_catches(delta)

	if auto_spawn:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0 and _fish.size() < TARGET_POPULATION:
			_spawn_timer = SPAWN_INTERVAL_S
			_spawn_group(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index != 0:
			return
		if touch.pressed:
			_begin_drag(touch.position)
		else:
			_end_drag()
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == 0 and _dragging:
			_net_target = _net_point(drag.position)
			accept_event()


## Adds one fish. Public so tests can place fish precisely.
func spawn_fish(species_id: String, at: Vector2, heading: float) -> SwimmingFish:
	var fish := SwimmingFish.new()
	fish.setup(DataRegistry.species[species_id], at, heading)
	_fish_layer.add_child(fish)
	_fish.append(fish)
	return fish


func fish_count() -> int:
	return _fish.size()


#region Spawning

func _populate() -> void:
	if not auto_spawn:
		return
	while _fish.size() < TARGET_POPULATION:
		_spawn_group(true)


## Spawns a school (or a single big fish). Outside the swim area unless `inside` is set,
## so new fish swim in from the sides.
func _spawn_group(inside: bool) -> void:
	var id := _spawns.pick(rng)
	var def := DataRegistry.species[id]
	var bounds := _swim_bounds()
	var origin: Vector2
	var heading: float
	if inside:
		var area := bounds.grow(-100.0)
		origin = Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		heading = rng.randf() * TAU
	else:
		var from_left := rng.randf() < 0.5
		var x := bounds.position.x - 150.0 if from_left else bounds.end.x + 150.0
		origin = Vector2(x, rng.randf_range(bounds.position.y + 80.0, bounds.end.y - 80.0))
		heading = (0.0 if from_left else PI) + rng.randf_range(-0.4, 0.4)
	var spread := CatchRules.body_length_px(def)
	for i in CatchRules.school_size(def, rng):
		var jitter := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * spread
		spawn_fish(id, origin + jitter, heading + rng.randf_range(-0.2, 0.2))


## The water area fish stay in, between the top bar and the bottom panel.
func _swim_bounds() -> Rect2:
	var height := maxf(size.y - SWIM_MARGIN_TOP - SWIM_MARGIN_BOTTOM, 200.0)
	return Rect2(0.0, SWIM_MARGIN_TOP, size.x, height)

#endregion


#region Net and catching

func _net_point(touch_position: Vector2) -> Vector2:
	return touch_position + (TOUCH_NET_OFFSET if OS.has_feature("mobile") else Vector2.ZERO)


func _begin_drag(at: Vector2) -> void:
	_dragging = true
	_net_target = _net_point(at)
	_net.position = _net_target - _world.position
	_net.haul.clear()
	_net.appear()
	_trail.clear_points()
	_trail_ages.clear()
	Juice.ripple(_effects, _net.position, _net.radius * 1.3)
	Sfx.play(&"splash", rng.randf_range(0.9, 1.1), -8.0)


func _end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	_net.disappear()
	_net.struggle_progress = 0.0
	for fish in _fish:
		fish.hold_time = 0.0
	_land_haul()


func _check_catches(delta: float) -> void:
	var room := mini(NET_CAPACITY, live_well.free_space()) - _net.haul.size()
	var progress := 0.0
	# Iterate over a copy: catching removes fish from _fish.
	var candidates: Array[SwimmingFish] = _fish.duplicate()
	for fish in candidates:
		if fish.position.distance_to(_net.position) > _net.radius:
			fish.hold_time = maxf(fish.hold_time - delta * HOLD_DECAY, 0.0)
			continue
		if room <= 0:
			fish.hold_time = 0.0
			continue
		fish.hold_time += delta
		var needed := CatchRules.struggle_seconds(fish.species)
		if fish.hold_time >= needed:
			_catch(fish)
			room -= 1
		else:
			progress = maxf(progress, fish.hold_time / needed)
	_net.full = room <= 0
	_net.struggle_progress = progress


func _catch(fish: SwimmingFish) -> void:
	_fish.erase(fish)
	_net.haul.append(fish.species)
	_net.pulse()
	Juice.ripple(_effects, fish.position, fish.length_px * 0.6)
	fish.play_caught(_net.position)
	# Bigger fish make a deeper sound.
	var pitch := clampf(1.6 - fish.species.length_cm / 60.0, 0.6, 1.5)
	Sfx.play(&"pop", pitch * rng.randf_range(0.95, 1.05))
	Haptics.tick()
	if GameState.record_catch(fish.species.id):
		_announce_new_species(fish.species)


## Moves the net's contents into the live-well, with combo feedback for multi-fish hauls.
func _land_haul() -> void:
	var haul: Array[SpeciesDef] = _net.haul.duplicate()
	_net.haul.clear()
	if haul.is_empty():
		return
	for def in haul:
		live_well.add(def.id)
	GameState.record_best("best_combo", haul.size())

	var screen_at := _world.position + _net.position
	Juice.splash(_effects, _net.position, 10 + 4 * haul.size())
	Sfx.play(&"splash", 1.0, -3.0)
	if haul.size() >= 2:
		Juice.popup_text(_popups, screen_at + Vector2(0.0, -150.0),
				CatchRules.combo_name(haul.size()), 64 + 8 * haul.size(), COMBO_COLOR)
		# One whole tone higher for every extra fish.
		Sfx.play(&"ding", pow(2.0, (haul.size() - 2) * 2.0 / 12.0))
		Haptics.bump()
		if haul.size() >= 3:
			_shake = 6.0 * haul.size()

	var target := _live_well_bar.get_global_rect().get_center() - _popups.get_global_rect().position
	for i in haul.size():
		var scatter := Vector2(rng.randf_range(-40.0, 40.0), rng.randf_range(-40.0, 40.0))
		Juice.fly_dot(_popups, screen_at + scatter, target, haul[i].placeholder_color, i * 0.06, _bump_live_well)
	_update_hud()


func _announce_new_species(def: SpeciesDef) -> void:
	Juice.popup_text(_popups, Vector2(size.x * 0.5, SWIM_MARGIN_TOP + 120.0),
			"New species!\n" + def.common_name, 60, NEW_SPECIES_COLOR, 1.4)
	Sfx.play(&"ding", 1.5, -4.0)
	Haptics.bump()

#endregion


#region Effects

func _update_trail(delta: float) -> void:
	for i in _trail_ages.size():
		_trail_ages[i] += delta
	while not _trail_ages.is_empty() and _trail_ages[0] > TRAIL_SECONDS:
		_trail_ages.remove_at(0)
		_trail.remove_point(0)
	if _dragging:
		_trail.add_point(_net.position)
		_trail_ages.append(0.0)


func _update_shake(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 60.0, 0.0)
		_world.position = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * _shake
	elif _world.position != Vector2.ZERO:
		_world.position = Vector2.ZERO


func _bump_live_well() -> void:
	_live_well_bar.pivot_offset = _live_well_bar.size * 0.5
	_live_well_bar.scale = Vector2.ONE * 1.08
	create_tween().tween_property(_live_well_bar, "scale", Vector2.ONE, 0.12)
	Sfx.play(&"pop", 1.8, -10.0)

#endregion


#region HUD

func _update_hud() -> void:
	_live_well_label.text = "Live-well  %d / %d" % [live_well.count(), live_well.capacity]
	_live_well_bar.max_value = live_well.capacity
	_live_well_bar.value = live_well.count()
	if live_well.count() == 0:
		_sell_button.text = "Catch some fish!"
		_sell_button.disabled = true
	else:
		_sell_button.text = "Sell catch  +" + NumberFormat.compact(GameState.catch_value(live_well.species_ids))
		_sell_button.disabled = false
	_set_sell_pulse(live_well.is_full())


func _set_sell_pulse(on: bool) -> void:
	if on == (_sell_pulse != null):
		return
	if on:
		_sell_button.pivot_offset = _sell_button.size * 0.5
		_sell_pulse = create_tween().set_loops()
		_sell_pulse.tween_property(_sell_button, "scale", Vector2.ONE * 1.06, 0.35).set_trans(Tween.TRANS_SINE)
		_sell_pulse.tween_property(_sell_button, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
	else:
		_sell_pulse.kill()
		_sell_pulse = null
		_sell_button.scale = Vector2.ONE


func _on_sell_pressed() -> void:
	var sold := live_well.take_all()
	var earned := GameState.sell_catch(sold)
	var at := _sell_button.get_global_rect().get_center() - _popups.get_global_rect().position
	Juice.popup_text(_popups, at + Vector2(0.0, -130.0), "+%s coins" % NumberFormat.compact(earned), 64, COIN_COLOR)
	for i in mini(sold.size(), 8):
		get_tree().create_timer(i * 0.06).timeout.connect(Sfx.play.bind(&"coin", 1.0 + i * 0.05))
	Haptics.bump()
	_update_hud()


func _on_money_changed(money: float) -> void:
	if _money_tween:
		_money_tween.kill()
	_money_tween = create_tween()
	_money_tween.tween_method(_show_money, _shown_money, money, 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _show_money(value: float) -> void:
	_shown_money = value
	_money_label.text = "Coins  " + NumberFormat.compact(value)


func _on_resized() -> void:
	if size.x > 0.0:
		(_water.material as ShaderMaterial).set_shader_parameter("aspect", size.y / size.x)

#endregion
