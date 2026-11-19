extends Node
## Facade for platform-specific services, so game code never checks the OS directly.
## Cloud saves (Play Games / iCloud) will be added here later.
##
## Also keeps the screen layout right when the device turns: the base size is 1080 x 1920 in
## portrait and 1920 x 1080 in landscape, so the short side is always 1080 pixels and the UI
## keeps its size. Scenes read is_landscape() on their own `resized`.

## The screen turned between portrait and landscape.
signal layout_changed(landscape: bool)

## True while the window is wider than high.
var landscape := false

var _portrait_size := Vector2i(1080, 1920)


func _ready() -> void:
	_portrait_size = Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 1080)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 1920)),
	)
	get_tree().root.size_changed.connect(_update_layout)
	_update_layout()
	# Settings is loaded by now (it comes first among the autoloads).
	set_orientation(Settings.orientation)


## Whether a view of `view_size` is laid out in landscape.
static func is_landscape(view_size: Vector2) -> bool:
	return view_size.x > view_size.y


## The base size (content scale size) for a window of `window_size`: portrait_size, turned in
## landscape.
static func base_size(window_size: Vector2, portrait_size: Vector2i) -> Vector2i:
	return Vector2i(portrait_size.y, portrait_size.x) if is_landscape(window_size) else portrait_size


## Turns the screen the way the player chose (Settings.ORIENTATIONS): with the device, or held
## in portrait or landscape. Only on phones and tablets.
func set_orientation(orientation: String) -> void:
	if not OS.has_feature("mobile"):
		return
	match orientation:
		"portrait":
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT)
		"landscape":
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
		_:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)


## Insets for notches and gesture bars in viewport pixels:
## x = left, y = top, z = right, w = bottom. Zero on desktop.
func safe_area_margins(viewport: Viewport) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var scale := viewport.get_visible_rect().size / window_size
	return Vector4(
		safe.position.x * scale.x,
		safe.position.y * scale.y,
		(window_size.x - safe.end.x) * scale.x,
		(window_size.y - safe.end.y) * scale.y,
	)


func _update_layout() -> void:
	var root := get_tree().root
	var window_size := Vector2(root.size)
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return
	var base := base_size(window_size, _portrait_size)
	if root.content_scale_size != base:
		root.content_scale_size = base
	var wide := is_landscape(window_size)
	if wide != landscape:
		landscape = wide
		layout_changed.emit(wide)
