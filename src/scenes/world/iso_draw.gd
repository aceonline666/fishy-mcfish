class_name IsoDraw
extends RefCounted
## Drawing helpers for isometric objects drawn in code (tanks, booth, squares).

const OUTLINE := Color(0.07, 0.09, 0.15)


static func fill_outlined(canvas: CanvasItem, points: PackedVector2Array, fill: Color, width: float = 4.0) -> void:
	canvas.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, OUTLINE, width, true)


## The screen corners of a ground rectangle centred on `base`: back, right, front, left.
static func footprint(base: Vector2, half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		base + Iso.to_screen(Vector2(-half.x, -half.y)),
		base + Iso.to_screen(Vector2(half.x, -half.y)),
		base + Iso.to_screen(Vector2(half.x, half.y)),
		base + Iso.to_screen(Vector2(-half.x, half.y)),
	])


## The screen outline of a ground rectangle with rounded corners, centred on `base`: `half` is its
## half size and `radius` the corner radius, both in ground units.
static func rounded_footprint(base: Vector2, half: Vector2, radius: float, corner_points: int = 8) -> PackedVector2Array:
	var points := PackedVector2Array()
	var inner := half - Vector2(radius, radius)
	var centers: Array[Vector2] = [Vector2(inner.x, inner.y), Vector2(-inner.x, inner.y), Vector2(-inner.x, -inner.y), Vector2(inner.x, -inner.y)]
	for i in 4:
		for step in corner_points + 1:
			var angle := (i + float(step) / corner_points) * PI * 0.5
			points.append(base + Iso.to_screen(centers[i] + Vector2(cos(angle), sin(angle)) * radius))
	return points


## The two faces of a box that point away from the camera (draw these first).
static func box_back(canvas: CanvasItem, base: Vector2, half: Vector2, height: float, color: Color) -> void:
	var c := footprint(base, half)
	var up := Vector2(0.0, -height)
	fill_outlined(canvas, PackedVector2Array([c[0], c[1], c[1] + up, c[0] + up]), color)
	fill_outlined(canvas, PackedVector2Array([c[0], c[3], c[3] + up, c[0] + up]), color)


## The two faces of a box that point towards the camera, and its top.
static func box_front(canvas: CanvasItem, base: Vector2, half: Vector2, height: float,
		right_color: Color, front_color: Color, top_color: Color) -> void:
	var c := footprint(base, half)
	var up := Vector2(0.0, -height)
	fill_outlined(canvas, PackedVector2Array([c[1], c[2], c[2] + up, c[1] + up]), right_color)
	fill_outlined(canvas, PackedVector2Array([c[3], c[2], c[2] + up, c[3] + up]), front_color)
	fill_outlined(canvas, PackedVector2Array([c[0] + up, c[1] + up, c[2] + up, c[3] + up]), top_color)


## The comic display font of the theme (Luckiest Guy), as on buttons and titles.
static func title_font() -> Font:
	var theme := ThemeDB.get_project_theme()
	return theme.get_font(&"font", &"Button") if theme != null else ThemeDB.fallback_font


## The body font of the theme (Fredoka).
static func body_font() -> Font:
	var theme := ThemeDB.get_project_theme()
	return theme.default_font if theme != null and theme.default_font != null else ThemeDB.fallback_font


## `points` filled with a vertical gradient from `top_color` at the highest point to
## `bottom_color` at the lowest.
static func fill_vertical_gradient(canvas: CanvasItem, points: PackedVector2Array, top_color: Color, bottom_color: Color) -> void:
	var top := INF
	var bottom := -INF
	for point in points:
		top = minf(top, point.y)
		bottom = maxf(bottom, point.y)
	var colors := PackedColorArray()
	for point in points:
		colors.append(top_color.lerp(bottom_color, inverse_lerp(top, bottom, point.y)))
	canvas.draw_polygon(points, colors)


## Outlined text centred on `at`, in the body font or, with `title`, in the comic display font.
static func label(canvas: CanvasItem, at: Vector2, text: String, size: int, color: Color = Color.WHITE, title: bool = false) -> void:
	var font := title_font() if title else body_font()
	var width := 600.0
	var origin := at + Vector2(-width * 0.5, (font.get_ascent(size) - font.get_descent(size)) * 0.5)
	canvas.draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, maxi(size / 4, 6), OUTLINE)
	canvas.draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)


## A gold coin seen at an angle.
static func coin(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	canvas.draw_colored_polygon(Iso.ellipse(at + Vector2(0.0, radius * 0.18), radius, 16), Color(0.75, 0.5, 0.1))
	var face := Iso.ellipse(at, radius, 16)
	canvas.draw_colored_polygon(face, Color(1.0, 0.82, 0.25))
	face.append(face[0])
	canvas.draw_polyline(face, OUTLINE, 2.5, true)
	canvas.draw_polyline(Iso.ellipse(at, radius * 0.6, 12), Color(0.85, 0.6, 0.12), 2.0, true)
