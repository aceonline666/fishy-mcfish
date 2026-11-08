extends Node
## Takes the raw Play Store screenshots: for each shot it builds a game state (gear, tank, shop,
## sellers, Fishpedia), runs the real game in an off-screen 1080 x 1920 viewport (the
## project's base size), places the wader and saves a PNG. Captions and the frame are added by
## tools/make_play_store_art.py.
##
## Started by tools/store_screenshots.gd, which also explains the arguments. A node of its own, so
## that it compiles after the autoloads exist.

const MAIN_SCENE := "res://src/scenes/main/main.tscn"
const SIZE := Vector2i(1080, 1920)
## Boot splash fade plus time for the fish to spread out.
const SETTLE_S := 2.5
## Where the wader stands for the business shot: east of the booths, with the queue in view.
const BUSINESS_VIEW := Vector2(1450.0, -1900.0)

var _out_dir := "user://store_shots"
var _lang := "en"
var _only := ""
## --view=x,y: instead of the store shots, one shot of the developed beach (the business shot's
## state) with the wader at this ground point, to look at art in the game.
var _view := Vector2.INF
## --frames=N: with --view, N shots one --every=S seconds apart, to watch something move.
var _frames := 1
## --location=id: with --view, the location to look at (the North Sea by default).
var _location := "north_sea"
## --full: with --view, the tank is filled to the brim (it overflows and fish jump out).
var _full := false
var _every := 1.0
var _viewport: SubViewport
var _main: Node


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--lang="):
			_lang = arg.trim_prefix("--lang=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg.begins_with("--view="):
			var parts := arg.trim_prefix("--view=").split(",")
			_view = Vector2(parts[0].to_float(), parts[1].to_float())
		elif arg == "--full":
			_full = true
		elif arg.begins_with("--location="):
			_location = arg.trim_prefix("--location=")
		elif arg.begins_with("--frames="):
			_frames = arg.trim_prefix("--frames=").to_int()
		elif arg.begins_with("--every="):
			_every = arg.trim_prefix("--every=").to_float()
	DirAccess.make_dir_recursive_absolute(_out_dir)
	# Keep Godot from importing the shots (and the export from shipping them).
	FileAccess.open(_out_dir.path_join(".gdignore"), FileAccess.WRITE)
	_run.call_deferred()


func _run() -> void:
	SaveSystem.use_sandbox("user://store_shots/save.json")
	TranslationServer.set_locale(_lang)
	_viewport = SubViewport.new()
	_viewport.size = SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	if _view != Vector2.INF:
		await _shot_view()
		get_tree().quit()
		return
	var shots: Array[Callable] = [_shot_catch, _shot_business, _shot_gear_shop, _shot_open_sea,
			_shot_deep_sea, _shot_reef, _shot_fishpedia, _shot_map, _shot_top_view_test]
	for shot in shots:
		if _only.is_empty() or shot.get_method().ends_with(_only):
			await shot.call()
	get_tree().quit()


#region Shots

## Wading in the North Sea shallows with a basket full of fish.
func _shot_catch() -> void:
	var state := _state(["north_sea"], 1)
	state.here().backpack.assign(["european_sprat", "atlantic_herring", "european_sprat", "lesser_sand_eel", "atlantic_herring"])
	var spot := await _start(state)
	var wader: Wader = spot.wader
	_place(spot, Vector2(900.0, 520.0))
	for i in 7:
		spot.spawn_fish(["european_sprat", "atlantic_herring", "atlantic_mackerel"][i % 3],
				Vector2(1200.0 + i * 70.0, 420.0 + (i % 3) * 90.0), PI)
	wader.walk_to(Vector2(1500.0, 560.0))
	await get_tree().create_timer(1.1).timeout
	await _capture("01_catch")


## The beach business: a big tank, booths with sellers and buyers queueing.
func _shot_business() -> void:
	var state := _state(["north_sea"], 3)
	var site := state.here()
	site.tank.level = 5
	site.shop_level = 4
	site.seller_count = 4
	var spot := await _start(state)
	_place(spot, BUSINESS_VIEW)
	await get_tree().create_timer(3.0).timeout
	await _capture("02_business")


## The developed beach around a ground point (--view).
func _shot_view() -> void:
	var state := _state([_location], 3)
	var site := state.here()
	site.tank.level = 5
	site.shop_level = 4
	site.seller_count = 4
	site.drone_count = 3
	if _full:
		# Nobody sells, so it stays full.
		site.seller_count = 0
		_fill_tank(site, site.tank.fish.map(func(fish: TankFish) -> String: return fish.species_id), RandomNumberGenerator.new(), 1.0)
		# Small fish close the last gaps, so the tank counts as full.
		_fill_tank(site, ["european_sprat"], RandomNumberGenerator.new(), 1.0)
	site.backpack.assign(["atlantic_cod", "atlantic_mackerel", "lumpsucker", "atlantic_herring", "european_plaice"])
	var spot := await _start(state)
	_place(spot, _view)
	await get_tree().create_timer(3.0).timeout
	for frame in _frames:
		if frame > 0:
			await get_tree().create_timer(_every).timeout
		await _capture("view_%d_%d%s" % [_view.x, _view.y, "" if _frames == 1 else "_%d" % frame])


## Inside the gear shop.
func _shot_gear_shop() -> void:
	var state := _state(["north_sea"], 2)
	state.money = 48500.0
	var spot := await _start(state)
	spot.emit_signal("store_requested")
	await get_tree().create_timer(1.5).timeout
	await _capture("03_gear_shop")


## Rebreather diver in the open sea with big fish.
func _shot_open_sea() -> void:
	var state := _state(["north_sea"], 4)
	var spot := await _start(state)
	var at := Vector2(1000.0, 3250.0)
	_place(spot, at)
	_spawn_around(spot, at, ["ocean_sunfish", "basking_shark", "atlantic_bluefin_tuna", "lions_mane_jellyfish",
			"atlantic_bluefin_tuna", "lions_mane_jellyfish"])
	await get_tree().create_timer(1.0).timeout
	await _capture("04_open_sea")


## The species drawn from above (FishArt.top, art_source/fish/top_view) swimming every way,
## among the rest (with --no-top: all from the side), to compare the views.
func _shot_top_view_test() -> void:
	var state := _state(["north_sea"], 3)
	var spot := await _start(state)
	var at := Vector2(1000.0, 1500.0)
	_place(spot, at)
	var species: Array[String] = ["european_sprat", "atlantic_herring", "atlantic_mackerel", "lumpsucker",
			"atlantic_cod", "atlantic_wolffish", "roundnose_grenadier", "rabbit_fish"]
	for i in species.size():
		var angle := TAU * i / species.size() + 0.3
		spot.spawn_fish(species[i], at + Vector2(cos(angle), sin(angle)) * (300.0 + 90.0 * (i % 2)), angle * 1.7)
	# Three shots a fraction of a beat apart, to see the tails move.
	for frame in 3:
		await get_tree().create_timer(0.6 if frame == 0 else 0.12).timeout
		await _capture("top_view_test_%d" % frame)


## Submersible in the deep sea.
func _shot_deep_sea() -> void:
	var state := _state(["north_sea"], 6)
	var spot := await _start(state)
	var at := Vector2(1000.0, 5150.0)
	_place(spot, at)
	_spawn_around(spot, at, ["humpback_anglerfish", "giant_squid", "atlantic_footballfish", "humpback_anglerfish", "sperm_whale"])
	await get_tree().create_timer(1.0).timeout
	await _capture("05_deep_sea")


## Snorkelling on the Coral Reef.
func _shot_reef() -> void:
	var state := _state(["north_sea", "coral_reef"], 3)
	state.current_location = "coral_reef"
	state.here().gear_level = 2
	var spot := await _start(state)
	var at := Vector2(1000.0, 1350.0)
	_place(spot, at)
	_spawn_around(spot, at, ["ocellaris_clownfish", "blue_tang", "red_lionfish", "mandarinfish",
			"ocellaris_clownfish", "blue_tang", "blue_green_chromis", "blue_green_chromis"])
	spot.wader.walk_to(at + Vector2(250.0, 60.0))
	await get_tree().create_timer(1.0).timeout
	await _capture("06_reef")


## The Fishpedia, then the page of one species.
func _shot_fishpedia() -> void:
	var state := _state(["north_sea", "coral_reef", "australia"], 4)
	var spot := await _start(state)
	var pedia: Fishpedia = spot.fishpedia
	pedia.open()
	await get_tree().create_timer(0.8).timeout
	await _capture("07_fishpedia")
	pedia.call("_show_detail", DataRegistry.species["ocean_sunfish"])
	await get_tree().create_timer(0.8).timeout
	await _capture("08_fishpedia_detail")


## The world map.
func _shot_map() -> void:
	var state := _state(["north_sea", "coral_reef", "australia"], 4)
	var spot := await _start(state)
	spot.world_map.open()
	await get_tree().create_timer(0.8).timeout
	await _capture("10_map")

#endregion


#region Helpers

## A game past the tutorial with the given locations opened. Every species of the zones up to
## `depth` there is known and those zones are charted; the gear opens them and the tank there is
## half full. Every goal counts as reached, so no banner covers the shot.
func _state(locations: Array[String], depth: int) -> PlayerState:
	var state := PlayerState.new_game()
	state.tutorial_step = Tutorial.Step.DONE
	state.money = 1250.0 * pow(8.0, depth)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for location_id in locations:
		if location_id != DataRegistry.home().id:
			state.unlocked_locations.append(location_id)
		var site := state.site(location_id)
		site.gear_level = depth
		site.tank.level = mini(depth + 1, DataRegistry.tank_levels.size())
		var known: Array[String] = []
		for zone: ZoneDef in DataRegistry.zones_in(location_id):
			if zone.order > depth:
				continue
			state.zone_catches[zone.id] = Charting.catches_needed(zone) + 40
			for id: String in zone.spawns:
				state.species_caught[id] = 3
				known.append(id)
		_fill_tank(site, known, rng)
	state.current_location = locations[0]
	for def in DataRegistry.achievements:
		state.achievements.append(def.id)
	return state


## Fills up to `share` of the site's tank (about half by default) with known species at mixed
## growth.
func _fill_tank(site: Site, species: Array, rng: RandomNumberGenerator, share: float = 0.55) -> void:
	var capacity := DataRegistry.tank_levels[site.tank.level - 1].capacity
	var litres := 0.0
	for fish in site.tank.fish:
		litres += DataRegistry.species[fish.species_id].space_l
	for attempt in 4000:
		var def: SpeciesDef = DataRegistry.species[species[rng.randi() % species.size()]]
		if def.min_tank_l > capacity or litres + def.space_l > capacity * share:
			continue
		site.tank.fish.append(TankFish.new(def.id, 1.0 if rng.randf() < 0.4 else rng.randf_range(0.3, 0.95)))
		litres += def.space_l


## Starts the game in the viewport with the given state; returns the fishing scene.
func _start(state: PlayerState) -> Control:
	if _main != null:
		_main.queue_free()
		await get_tree().process_frame
	GameState.replace_state(state)
	_main = (load(MAIN_SCENE) as PackedScene).instantiate()
	_viewport.add_child(_main)
	await get_tree().create_timer(SETTLE_S).timeout
	return _main.get("_spot")


## Puts the wader on a ground point and points the camera at it.
func _place(spot: Control, ground: Vector2) -> void:
	var wader: Wader = spot.wader
	wader.ground_position = ground
	wader.position = Iso.to_screen(ground)
	spot.call("_update_camera", 0.0, true)


## Spawns the species in a loose ring around a ground point, swimming different ways.
func _spawn_around(spot: Control, center: Vector2, species: Array) -> void:
	for i in species.size():
		var angle := TAU * i / species.size() + 0.4
		var radius := 260.0 + 90.0 * (i % 3)
		spot.spawn_fish(species[i], center + Vector2(cos(angle), sin(angle)) * radius, angle + PI * 0.5)


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _out_dir.path_join(shot_name + ".png")
	_viewport.get_texture().get_image().save_png(path)
	print("Saved ", path)

#endregion

