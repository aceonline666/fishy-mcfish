class_name Ripple
extends Node2D
## An expanding, fading ring on the water surface, drawn in isometric perspective.
## Frees itself when done.

var max_radius := 80.0
var duration := 0.5
var color := Color(1.0, 1.0, 1.0, 0.75)

var _elapsed := 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _elapsed / duration
	var eased := 1.0 - pow(1.0 - k, 3.0)
	var ring_color := Color(color, color.a * (1.0 - k))
	var ring := Iso.ellipse(Vector2.ZERO, lerpf(max_radius * 0.2, max_radius, eased), 32)
	draw_polyline(ring, ring_color, lerpf(6.0, 2.0, k), true)
