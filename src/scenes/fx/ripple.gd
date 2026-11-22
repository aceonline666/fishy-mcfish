class_name Ripple
extends Node2D
## An expanding, fading ring on the water surface, drawn in isometric perspective.
## Frees itself when done.

var max_radius := 80.0
var duration := 0.5
var color := Color(1.0, 1.0, 1.0, 0.75)
## Glowing (on an additive material): a soft light fills the ring and sparks fleck it.
var glow := false

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
	if not glow:
		return
	var radius := lerpf(max_radius * 0.2, max_radius, eased)
	Glow.draw(self, Vector2.ZERO, radius * 1.1, Color(color, color.a * 0.35 * (1.0 - k)), 0.5)
	# Sparks on the ring, the same every frame (seeded by the ring's place).
	var scatter := float(int(absf(position.x * 7.0 + position.y * 13.0)) % 97)
	for i in 9:
		var angle := TAU * (float(i) + fposmod(scatter * 0.13 * float(i + 1), 1.0)) / 9.0
		var spark := Vector2(cos(angle), sin(angle) * 0.5) * radius * 0.9
		draw_circle(spark, lerpf(4.0, 1.5, k), Color(color, color.a * (1.0 - k)))
