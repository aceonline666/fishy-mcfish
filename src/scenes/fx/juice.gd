class_name Juice
extends RefCounted
## Small reusable feedback effects: ripples, droplet splashes, pop-up text and flying dots.

const OUTLINE_COLOR := Color(0.07, 0.09, 0.15)
const DROPLET_TEXTURE := preload("res://src/scenes/fx/droplet_texture.tres")


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
	particles.texture = DROPLET_TEXTURE
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


## A fish sprite flying in an arc from `from` to `to`, flipping over on the way;
## calls `on_arrive` when it lands.
static func fly_fish(parent: Node, art: FishArt, from: Vector2, to: Vector2, length: float, on_arrive: Callable) -> void:
	var icon := FishIcon.new()
	icon.art = art
	icon.length = length
	icon.position = from
	parent.add_child(icon)
	var peak := from.lerp(to, 0.5) + Vector2(0.0, -160.0)
	var arc := func(t: float) -> void:
		icon.position = from.lerp(peak, t).lerp(peak.lerp(to, t), t)
	var tween := icon.create_tween()
	tween.tween_method(arc, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(icon, "rotation", PI * signf(to.x - from.x + 0.01), 0.45)
	tween.parallel().tween_property(icon, "scale", Vector2.ONE * 0.7, 0.45)
	tween.tween_callback(on_arrive)
	tween.tween_callback(icon.queue_free)


## A coin flying in a small arc from `from` to `to`, then vanishing.
static func fly_coin(parent: Node, from: Vector2, to: Vector2, radius: float = 12.0) -> void:
	var coin := CoinIcon.new()
	coin.radius = radius
	coin.position = from
	parent.add_child(coin)
	var peak := from.lerp(to, 0.5) + Vector2(0.0, -70.0)
	var arc := func(t: float) -> void:
		coin.position = from.lerp(peak, t).lerp(peak.lerp(to, t), t)
	var tween := coin.create_tween()
	tween.tween_method(arc, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(coin.queue_free)


class CoinIcon extends Node2D:
	var radius := 12.0

	func _draw() -> void:
		IsoDraw.coin(self, Vector2.ZERO, radius)


class FishIcon extends Node2D:
	var art: FishArt
	var length := 50.0

	func _draw() -> void:
		art.draw(self, Transform2D.IDENTITY, length)
