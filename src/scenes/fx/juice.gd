class_name Juice
extends RefCounted
## Small reusable feedback effects: ripples, droplet splashes, pop-up text and flying dots.

const OUTLINE_COLOR := Color(0.07, 0.09, 0.15)

static var _droplet_texture: Texture2D


static func ripple(parent: Node, at: Vector2, radius: float, color: Color = Color(1.0, 1.0, 1.0, 0.75)) -> void:
	var ring := Ripple.new()
	ring.position = at
	ring.max_radius = radius
	ring.color = color
	parent.add_child(ring)


## A burst of droplets that frees itself when done.
static func splash(parent: Node, at: Vector2, amount: int) -> void:
	var particles := CPUParticles2D.new()
	particles.position = at
	particles.texture = _droplet()
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = amount
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 140.0
	particles.initial_velocity_max = 380.0
	particles.damping_min = 250.0
	particles.damping_max = 400.0
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.8
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.95))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = fade
	particles.finished.connect(particles.queue_free)
	parent.add_child(particles)
	particles.emitting = true


## Outlined text that pops in at `at` (its centre), floats up and fades out.
static func popup_text(parent: Control, at: Vector2, text: String, font_size: int, color: Color, hold_s: float = 0.35) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", maxi(font_size / 5, 6))
	parent.add_child(label)
	label.size = label.get_minimum_size()
	label.position = at - label.size * 0.5
	if parent.size.x > label.size.x:
		label.position.x = clampf(label.position.x, 16.0, parent.size.x - label.size.x - 16.0)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 0.3

	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_s)
	tween.tween_property(label, "position:y", label.position.y - 90.0, 0.5).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


## A coloured dot flying from `from` to `to`; calls `on_arrive` when it lands.
static func fly_dot(parent: Node, from: Vector2, to: Vector2, color: Color, delay: float, on_arrive: Callable) -> void:
	var dot := Dot.new()
	dot.color = color
	dot.position = from
	parent.add_child(dot)
	var tween := dot.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(dot, "position", to, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(dot, "scale", Vector2.ONE * 0.6, 0.45)
	tween.tween_callback(on_arrive)
	tween.tween_callback(dot.queue_free)


static func _droplet() -> Texture2D:
	if _droplet_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		gradient.add_point(0.55, Color.WHITE)
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 32
		texture.height = 32
		_droplet_texture = texture
	return _droplet_texture


class Dot extends Node2D:
	var color := Color.WHITE

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 20.0, Juice.OUTLINE_COLOR)
		draw_circle(Vector2.ZERO, 15.0, color)
