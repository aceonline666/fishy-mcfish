class_name LockPopup
extends Node2D
## A golden padlock with a dark outline (in the look of the tutorial's arrows) that pops in at its
## position, holds, then floats up and fades: the way on is locked. Frees itself when done.

const GOLD := Color(1.0, 0.85, 0.2)
const SHADE := Color(0.85, 0.62, 0.1)
## Height of the whole lock (shackle and body), in pixels.
const HEIGHT := 96.0
const OUTLINE := 7.0
const POP_IN_S := 0.25
const HOLD_S := 0.9
const LEAVE_S := 0.5


static func pop(parent: Node, at: Vector2) -> LockPopup:
	var lock := LockPopup.new()
	lock.position = at
	parent.add_child(lock)
	return lock


func _ready() -> void:
	scale = Vector2.ONE * 0.3
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, POP_IN_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_S)
	tween.tween_property(self, "position:y", position.y - 70.0, LEAVE_S).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, LEAVE_S)
	tween.tween_callback(queue_free)


## Centred on the position: the shackle on top, the body below with a keyhole.
func _draw() -> void:
	var h := HEIGHT
	var body := Rect2(-h * 0.4, -h * 0.1, h * 0.8, h * 0.6)
	var shackle_center := Vector2(0.0, -h * 0.1)
	var shackle_radius := h * 0.24
	var shackle_width := h * 0.11
	# The shackle: an arch whose legs reach down into the body.
	var arch := PackedVector2Array()
	arch.append(shackle_center + Vector2(-shackle_radius, h * 0.05))
	for i in 17:
		arch.append(shackle_center + Vector2.from_angle(PI + PI * i / 16.0) * shackle_radius)
	arch.append(shackle_center + Vector2(shackle_radius, h * 0.05))
	draw_polyline(arch, Juice.OUTLINE_COLOR, shackle_width + OUTLINE * 2.0, true)
	draw_polyline(arch, SHADE, shackle_width, true)
	# The body: a rounded box, darker at the bottom.
	var box := _rounded(body, h * 0.1)
	var outline := box.duplicate()
	outline.append(box[0])
	draw_polyline(outline, Juice.OUTLINE_COLOR, OUTLINE * 2.0, true)
	draw_colored_polygon(box, GOLD)
	draw_colored_polygon(_rounded(Rect2(body.position.x, body.end.y - h * 0.16, body.size.x, h * 0.16), h * 0.08), SHADE)
	draw_colored_polygon(_rounded(Rect2(body.position.x + OUTLINE * 0.5, body.position.y + OUTLINE * 0.5, body.size.x - OUTLINE, h * 0.12), h * 0.06),
			GOLD.lightened(0.35))
	# The keyhole.
	var key := body.get_center() + Vector2(0.0, -h * 0.04)
	draw_circle(key, h * 0.07, Juice.OUTLINE_COLOR)
	draw_colored_polygon(PackedVector2Array([key + Vector2(-h * 0.035, 0.0), key + Vector2(h * 0.035, 0.0),
			key + Vector2(h * 0.05, h * 0.16), key + Vector2(-h * 0.05, h * 0.16)]), Juice.OUTLINE_COLOR)


## The outline of `rect` with corners rounded by `radius`.
static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners: Array[Vector2] = [
		rect.position + Vector2(rect.size.x - radius, radius), rect.end - Vector2(radius, radius),
		rect.position + Vector2(radius, rect.size.y - radius), rect.position + Vector2(radius, radius),
	]
	for c in 4:
		for i in 5:
			points.append(corners[c] + Vector2.from_angle(-PI * 0.5 + PI * 0.5 * (c + i / 4.0)) * radius)
	return points
