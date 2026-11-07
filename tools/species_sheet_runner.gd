extends Node
## Draws the species contact sheets (see tools/species_sheet.gd) in an off-screen viewport.

const PHASES := 4
const CELL := Vector2(300.0, 150.0)
const LABEL_WIDTH := 260.0
const ROWS_PER_SHEET := 22
const FISH_LENGTH := 230.0
const BACKGROUND := Color(0.78, 0.87, 0.92)

var _out_dir := "user://species"
var _only: PackedStringArray = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	var ids: Array[String] = []
	for id: String in DataRegistry.species:
		if _only.is_empty() or Array(_only).any(func(part: String) -> bool: return id.contains(part)):
			ids.append(id)
	ids.sort()
	var sheet := 0
	while sheet * ROWS_PER_SHEET < ids.size():
		await _draw_sheet(ids.slice(sheet * ROWS_PER_SHEET, (sheet + 1) * ROWS_PER_SHEET), sheet)
		sheet += 1
	get_tree().quit()


func _draw_sheet(ids: Array[String], index: int) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(int(LABEL_WIDTH + CELL.x * PHASES), int(CELL.y * ids.size()))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)
	var canvas := Sheet.new()
	canvas.ids = ids
	viewport.add_child(canvas)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var path := _out_dir.path_join("species_%d.png" % index)
	viewport.get_texture().get_image().save_png(path)
	print("Saved ", path)
	viewport.queue_free()


class Sheet:
	extends Node2D

	var ids: Array[String] = []
	## Kept so the textures live until the frame is drawn.
	var _arts: Array[FishArt] = []

	func _draw() -> void:
		var size := Vector2(LABEL_WIDTH + CELL.x * PHASES, CELL.y * ids.size())
		draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
		var font := ThemeDB.fallback_font
		for row in ids.size():
			var def: SpeciesDef = DataRegistry.species[ids[row]]
			var art := FishArt.for_species(def)
			_arts.append(art)
			var y := CELL.y * (row + 0.5)
			draw_string(font, Vector2(8.0, y - 4.0), def.id, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.BLACK)
			draw_string(font, Vector2(8.0, y + 18.0), FishArt.Motion.keys()[art.motion].to_lower(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.2, 0.4))
			for phase in PHASES:
				var center := Vector2(LABEL_WIDTH + CELL.x * (phase + 0.5), y)
				var angle := TAU * phase / PHASES
				# Waves, pulses and jets run slower than a tail beat: spread their phases over their cycle.
				if art.motion == FishArt.Motion.WAVE:
					angle /= FishArt.WAVE_RATE
				elif art.motion == FishArt.Motion.PADDLE:
					angle /= FishArt.PADDLE_RATE
				elif art.is_jellyfish:
					angle /= FishArt.JELLY_RATE
				elif art.motion != FishArt.Motion.TAIL:
					angle /= FishArt.PULSE_RATE
				art.draw(self, Transform2D(0.0, center), FISH_LENGTH, angle, 1.0)
			draw_line(Vector2(0.0, CELL.y * (row + 1)), Vector2(size.x, CELL.y * (row + 1)), Color(0.0, 0.0, 0.0, 0.15))
