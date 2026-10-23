extends SceneTree
## Runs the main scene in a window, optionally performs a scripted net drag with the mouse
## (through the real input routing), and saves screenshots as PNGs.
##
## Usage (not headless, it needs to render):
##   godot --path . -s res://tools/screenshot.gd -- --out=C:/temp/shots [--drag] [--tap=0.65,0.22]
## --tap taps once at the given fraction of the window after the drag and captures twice while
## the game reacts (e.g. walking onto the store square).

const SETTLE_SECONDS := 1.5
const DRAG_FRAMES := 150

var _out_dir := "user://screenshots"
var _drag := false
var _tap := Vector2(-1.0, -1.0)


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg == "--drag":
			_drag = true
		elif arg.begins_with("--tap="):
			var parts := arg.trim_prefix("--tap=").split(",")
			_tap = Vector2(parts[0].to_float(), parts[1].to_float())
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	# Start from a fresh game in a separate save, never the player's. Deferred so the
	# autoloads are ready.
	root.get_node("SaveSystem").use_sandbox("user://screenshots/save.json")
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await create_timer(SETTLE_SECONDS).timeout
	await _capture("01_idle")
	if _drag:
		await _scripted_drag()
	if _tap.x >= 0.0:
		# A real finger always moves a little; the motion also refreshes the emulated touch
		# position, which can otherwise be stale for a lone press.
		var at := _tap * Vector2(DisplayServer.window_get_size())
		_mouse_button(at, true)
		var motion := InputEventMouseMotion.new()
		motion.position = at
		motion.global_position = at
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await process_frame
		_mouse_button(at, false)
		await create_timer(1.2).timeout
		await _capture("05_tap_arrived")
		await create_timer(1.2).timeout
		await _capture("06_tap_after")
	quit()


## Sweeps the mouse in a wide S-curve across the water, capturing mid-drag and after landing.
func _scripted_drag() -> void:
	var window := Vector2(DisplayServer.window_get_size())
	var path := func(t: float) -> Vector2:
		return Vector2(lerpf(0.15, 0.85, t), 0.45 + 0.12 * sin(t * TAU)) * window
	_mouse_button(path.call(0.0), true)
	for frame in DRAG_FRAMES:
		var t := float(frame) / DRAG_FRAMES
		var motion := InputEventMouseMotion.new()
		motion.position = path.call(t)
		motion.global_position = motion.position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await process_frame
		if frame == DRAG_FRAMES / 2:
			await _capture("02_dragging")
	_mouse_button(path.call(1.0), false)
	await create_timer(0.15).timeout
	await _capture("03_landed")
	await create_timer(1.0).timeout
	await _capture("04_after")


func _mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _out_dir.path_join(shot_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("Saved ", path)
