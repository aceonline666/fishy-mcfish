class_name ShopNode
extends Node2D
## A fish shop on the beach, drawn in code: a wooden stall with a striped awning, a sign on the
## roof with the number of the zone it sells fish from, fish on ice at the counter, and a seller
## behind it once one is hired. About as big as a large tank. The node sits at the centre of the
## base.

const HALF := Vector2(120.0, 80.0)
const HEIGHT := 118.0
const WOOD := Color(0.74, 0.52, 0.3)
const WOOD_DARK := Color(0.56, 0.37, 0.2)
const AWNING_A := Color(0.2, 0.55, 0.95)
const AWNING_B := Color(0.98, 0.97, 0.94)
const WINDOW := Color(0.18, 0.14, 0.12)
const ICE := Color(0.85, 0.95, 1.0)
const SIGN := Color(1.0, 0.85, 0.3)
const SKIN := Color(1.0, 0.82, 0.66)
const APRON := Color(0.95, 0.95, 0.95)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)
const STRIPES := 6
const BADGE := Color(0.2, 0.55, 0.95)

## Shop N sells the fish of zone N; shown on the sign.
var tier := 1

## Shows a seller in the window.
var staffed := false:
	set(value):
		staffed = value
		queue_redraw()
## Fish shown on the ice; set by the scene.
var display: Array[FishArt] = []:
	set(value):
		display = value
		queue_redraw()

var _bounce := 0.0


## Quick hop when something is sold.
func bounce() -> void:
	scale = Vector2(1.05, 0.95)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Where coins pop up when something is sold, relative to the parent.
func counter_point() -> Vector2:
	return position + Vector2(0.0, -HEIGHT * 0.7)


func _draw() -> void:
	draw_colored_polygon(Iso.ellipse(Vector2(10.0, 8.0), (HALF.x + HALF.y) * 0.95, 24), SHADOW)
	IsoDraw.box_front(self, Vector2.ZERO, HALF, HEIGHT, WOOD_DARK, WOOD, WOOD.lightened(0.18))
	var c := IsoDraw.footprint(Vector2.ZERO, HALF)

	# Counter window on the front face, with a seller behind it.
	var left := c[3].lerp(c[2], 0.15)
	var right := c[3].lerp(c[2], 0.85)
	var window := PackedVector2Array([
		left + Vector2(0.0, -46.0), right + Vector2(0.0, -46.0), right + Vector2(0.0, -96.0), left + Vector2(0.0, -96.0),
	])
	IsoDraw.fill_outlined(self, window, WINDOW, 3.0)
	if staffed:
		_draw_seller(left.lerp(right, 0.5) + Vector2(0.0, -70.0))

	# Fish on crushed ice along the counter.
	var tray := PackedVector2Array([
		left + Vector2(0.0, -40.0), right + Vector2(0.0, -40.0), right + Vector2(10.0, -28.0), left + Vector2(10.0, -28.0),
	])
	IsoDraw.fill_outlined(self, tray, ICE, 3.0)
	for i in mini(display.size(), 4):
		var at := left.lerp(right, 0.17 + i * 0.22) + Vector2(4.0, -38.0)
		var view := Transform2D(Vector2(1.0 if i % 2 == 0 else -1.0, 0.0), Vector2(0.0, 1.0), at)
		display[i].draw(self, view, 46.0)

	# Striped awning over the front.
	for i in STRIPES:
		var a := c[3].lerp(c[2], float(i) / STRIPES) + Vector2(0.0, -HEIGHT - 4.0)
		var b := c[3].lerp(c[2], float(i + 1) / STRIPES) + Vector2(0.0, -HEIGHT - 4.0)
		IsoDraw.fill_outlined(self, PackedVector2Array([a, b, b + Vector2(10.0, 34.0), a + Vector2(10.0, 34.0)]),
				AWNING_A if i % 2 == 0 else AWNING_B, 3.0)

	# Sign on the roof.
	var top := Vector2(0.0, -HEIGHT - (HALF.x + HALF.y) * 0.18)
	var board := PackedVector2Array([
		top + Vector2(-78.0, -58.0), top + Vector2(78.0, -58.0), top + Vector2(78.0, -14.0), top + Vector2(-78.0, -14.0),
	])
	draw_line(top + Vector2(-50.0, -14.0), top + Vector2(-50.0, 6.0), IsoDraw.OUTLINE, 6.0)
	draw_line(top + Vector2(50.0, -14.0), top + Vector2(50.0, 6.0), IsoDraw.OUTLINE, 6.0)
	IsoDraw.fill_outlined(self, board, SIGN, 4.0)
	IsoDraw.label(self, top + Vector2(-12.0, -36.0), tr("FISH"), 34, Color(0.25, 0.15, 0.08))
	var badge := top + Vector2(66.0, -58.0)
	draw_circle(badge, 21.0, IsoDraw.OUTLINE)
	draw_circle(badge, 17.0, BADGE)
	IsoDraw.label(self, badge, str(tier), 26)


func _draw_seller(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-20.0, 4.0), at + Vector2(20.0, 4.0), at + Vector2(24.0, 30.0), at + Vector2(-24.0, 30.0)]), APRON)
	draw_circle(at, 17.0, IsoDraw.OUTLINE)
	draw_circle(at, 14.0, SKIN)
	draw_circle(at + Vector2(-5.0, 1.0), 2.2, IsoDraw.OUTLINE)
	draw_circle(at + Vector2(5.0, 1.0), 2.2, IsoDraw.OUTLINE)
	draw_arc(at + Vector2(0.0, 6.0), 5.0, 0.4, PI - 0.4, 6, IsoDraw.OUTLINE, 1.8, true)
	# A paper cap.
	draw_colored_polygon(PackedVector2Array([at + Vector2(-15.0, -6.0), at + Vector2(15.0, -6.0), at + Vector2(0.0, -24.0)]), APRON)
	draw_polyline(PackedVector2Array([at + Vector2(-15.0, -6.0), at + Vector2(0.0, -24.0), at + Vector2(15.0, -6.0)]), IsoDraw.OUTLINE, 2.0, true)
