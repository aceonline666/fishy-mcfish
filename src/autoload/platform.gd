extends Node
## Facade for platform-specific services, so game code never checks the OS directly.
## Cloud saves (Play Games / iCloud) will be added here later.


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
