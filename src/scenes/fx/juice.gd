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
## A comic coin that pops out at `from`, spins along an arc and shrinks into `to`.
static func fly_coin(parent: Node, from: Vector2, to: Vector2, radius: float = 12.0) -> void:
	var coin := CoinIcon.new()
	coin.radius = radius * CoinIcon.FLY_SCALE
	coin.position = from
	coin.spin = randf() * TAU
	coin.scale = Vector2.ONE * 0.4
	parent.add_child(coin)
	var peak := from.lerp(to, 0.5) + Vector2(0.0, -90.0)
	var arc := func(t: float) -> void:
		coin.position = from.lerp(peak, t).lerp(peak.lerp(to, t), t)
	var tween := coin.create_tween()
	tween.tween_property(coin, "scale", Vector2.ONE * 1.15, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(arc, 0.0, 1.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(coin, "scale", Vector2.ONE * 0.7, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(coin.queue_free)


## A gold coin seen face on, spinning about its upright axis: thick outline, a raised star and a
## shine, its rim showing when it turns edge on.
class CoinIcon extends Node2D:
	## Flying coins are drawn this much bigger than the radius the callers ask for.
	const FLY_SCALE := 1.6
	## Turns per second.
	const SPIN_SPEED := 2.2
	const GOLD := Color(1.0, 0.82, 0.22)
	const GOLD_DARK := Color(0.85, 0.55, 0.08)
	const RIM := Color(0.7, 0.42, 0.05)
	const SHINE := Color(1.0, 0.98, 0.85, 0.9)
	const OUTLINE := Color(0.07, 0.09, 0.15)

	var radius := 12.0
	var spin := 0.0

	func _process(delta: float) -> void:
		spin += delta * TAU * SPIN_SPEED
		queue_redraw()

	func _draw() -> void:
		var turn := cos(spin)
		var width := maxf(absf(turn), 0.12) * radius
		var edge := radius * 0.22 * signf(sin(spin))
		var line := maxf(radius * 0.12, 2.0)
		# The rim, seen beside the face while it turns.
		var rim := _oval(Vector2(edge * (1.0 - absf(turn)), 0.0), width)
		draw_colored_polygon(rim, RIM)
		_outline(rim, line)
		var face := _oval(Vector2.ZERO, width)
		draw_colored_polygon(face, GOLD if turn >= 0.0 else GOLD_DARK.lerp(GOLD, 0.5))
		_outline(face, line)
		if absf(turn) < 0.3:
			return
		# The raised star and the inner ring, squeezed with the face.
		var squeeze := Vector2(width / radius, 1.0)
		var ring := PackedVector2Array()
		for i in 21:
			ring.append(Vector2.from_angle(TAU * i / 20.0) * radius * 0.68 * squeeze)
		draw_polyline(ring, GOLD_DARK, maxf(line * 0.6, 1.5), true)
		var star := PackedVector2Array()
		for i in 10:
			var r := radius * (0.42 if i % 2 == 0 else 0.18)
			star.append(Vector2.from_angle(-PI * 0.5 + PI * i / 5.0) * r * squeeze)
		draw_colored_polygon(star, GOLD_DARK)
		# A shine on the upper left.
		var shine := PackedVector2Array()
		for i in 7:
			shine.append(Vector2.from_angle(PI * 1.05 + PI * 0.35 * i / 6.0) * radius * 0.8 * squeeze)
		draw_polyline(shine, SHINE, maxf(line * 0.7, 1.5), true)

	func _oval(center: Vector2, width: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in 24:
			var angle := TAU * i / 24.0
			points.append(center + Vector2(cos(angle) * width, sin(angle) * radius))
		return points

	func _outline(points: PackedVector2Array, width: float) -> void:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, OUTLINE, width, true)


class FishIcon extends Node2D:
	var art: FishArt
	var length := 50.0

	func _draw() -> void:
		art.draw(self, Transform2D.IDENTITY, length)
