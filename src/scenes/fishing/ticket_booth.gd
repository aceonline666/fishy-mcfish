class_name TicketBooth
extends Node2D
## The ticket booth where visitors pay. Drawn in code: a wooden hut with a striped awning.

const HALF := Vector2(55.0, 45.0)
const HEIGHT := 80.0
const WOOD := Color(0.72, 0.5, 0.28)
const WOOD_DARK := Color(0.55, 0.36, 0.19)
const ROOF_RED := Color(0.9, 0.28, 0.24)
const ROOF_WHITE := Color(0.98, 0.95, 0.9)
const WINDOW := Color(0.2, 0.15, 0.12)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)


func _draw() -> void:
	draw_colored_polygon(Iso.ellipse(Vector2(8.0, 6.0), 90.0, 20), SHADOW)
	IsoDraw.box_front(self, Vector2.ZERO, HALF, HEIGHT, WOOD_DARK, WOOD, WOOD.lightened(0.15))
	# Counter window on the front face.
	var c := IsoDraw.footprint(Vector2.ZERO, HALF)
	var left := c[3].lerp(c[2], 0.2)
	var right := c[3].lerp(c[2], 0.8)
	IsoDraw.fill_outlined(self, PackedVector2Array([
		left + Vector2(0.0, -30.0), right + Vector2(0.0, -30.0), right + Vector2(0.0, -64.0), left + Vector2(0.0, -64.0),
	]), WINDOW, 3.0)
	# Striped awning above the window.
	var stripes := 5
	for i in stripes:
		var a := c[3].lerp(c[2], float(i) / stripes) + Vector2(0.0, -HEIGHT - 6.0)
		var b := c[3].lerp(c[2], float(i + 1) / stripes) + Vector2(0.0, -HEIGHT - 6.0)
		IsoDraw.fill_outlined(self, PackedVector2Array([a, b, b + Vector2(6.0, 26.0), a + Vector2(6.0, 26.0)]),
				ROOF_RED if i % 2 == 0 else ROOF_WHITE, 3.0)
	IsoDraw.label(self, Vector2(0.0, -HEIGHT - 44.0), "Tickets", 26)
