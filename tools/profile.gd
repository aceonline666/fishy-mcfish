extends SceneTree
## Finds what makes a frame slow. Runs the game in a window on a copy of a save (the player's
## autosave by default; the save itself is never written), measures the uncapped frame time and
## the memory, then measures again with each kind of node (script class) hidden and paused in
## turn, and lists how much time each kind costs.
##
## Usage (not headless, it needs to render):
##   godot --path . -s res://tools/profile.gd [-- --save=C:/path/to/save.json]
## Times are those of this PC; a phone takes several times as long, but the order is the same.

const SAMPLE_S := 2.0
const SETTLE_S := 3.0
const SANDBOX := "user://perf_profile/save.json"

var _save := "user://autosave.json"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save="):
			_save = arg.trim_prefix("--save=")
	_run.call_deferred()


func _run() -> void:
	var saves := root.get_node("SaveSystem")
	# Deferred so the autoloads are ready. The sandbox's autosave is what load_game() resumes.
	saves.use_sandbox(SANDBOX)
	var copy: String = saves.autosave_path()
	var error := DirAccess.copy_absolute(ProjectSettings.globalize_path(_save), ProjectSettings.globalize_path(copy))
	if error != OK:
		printerr("Could not copy the save %s: %s" % [_save, error_string(error)])
		quit(1)
		return
	saves.load_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await create_timer(SETTLE_S).timeout
	var base := await _measure()
	print("Frame     %.2f ms average, worst %.1f ms, %d of %d frames over 16 ms" % base)
	print("Rendering %d draw calls, %d primitives, %d nodes" % [
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	print("Memory    textures %.0f MB, video total %.0f MB, static %.0f MB" % [
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])
	var groups := _groups()
	var results: Array[Array] = []
	for name: String in groups:
		var nodes: Array = groups[name]
		_switch(nodes, false)
		var without := await _measure()
		_switch(nodes, true)
		results.append([name, nodes.size(), base[0] - without[0]])
	results.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2])
	print("\nTime each kind of node costs (hidden and paused; below about 0.3 ms is noise):")
	for result in results:
		print("  %-36s x%-4d %6.2f ms" % result)
	quit()


## The scene's drawn nodes with a script, by script class. Scenes containing others (main,
## fishing scene) include their children's time.
func _groups() -> Dictionary:
	var groups := {}
	for node: Node in _all(current_scene):
		var script: Script = node.get_script()
		if script == null or not node is CanvasItem:
			continue
		var name := String(script.get_global_name())
		if name.is_empty():
			name = script.resource_path.get_file()
		if name.is_empty():
			# An inner class: name it after the node it lives under.
			name = "%s in %s" % [node.get_class(), node.get_parent().name]
		if not groups.has(name):
			groups[name] = []
		groups[name].append(node)
	return groups


func _switch(nodes: Array, on: bool) -> void:
	for node: Variant in nodes:
		# Customers and effects come and go while measuring.
		if not is_instance_valid(node):
			continue
		var item: CanvasItem = node
		item.visible = on
		item.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


## Average frame time (ms), worst frame (ms), frames over 16 ms, frames.
func _measure() -> Array:
	for i in 30:
		await process_frame
	var start := Time.get_ticks_usec()
	var last := start
	var frames := 0
	var worst := 0
	var slow := 0
	while last - start < SAMPLE_S * 1e6:
		await process_frame
		var now := Time.get_ticks_usec()
		frames += 1
		worst = maxi(worst, now - last)
		if now - last > 16000:
			slow += 1
		last = now
	return [(last - start) / 1000.0 / frames, worst / 1000.0, slow, frames]


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
