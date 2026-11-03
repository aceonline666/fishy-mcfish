class_name GoalBanner
extends Control
## Celebrates a reached goal: a card with the goal's name pops in over turning sun rays, a burst of
## confetti and a fanfare, and the reward flies to the wallet as a shower of coins. Goals reached together are
## celebrated one after the other. Covers its parent and lets every touch through.

const GOLD := Color(1.0, 0.85, 0.2)
const CARD_COLOR := Color(0.1, 0.24, 0.4)
const CONFETTI_COLORS: Array[Color] = [
	Color(1.0, 0.85, 0.2), Color(1.0, 0.42, 0.42), Color(0.36, 0.85, 0.55),
	Color(0.35, 0.7, 1.0), Color(0.85, 0.5, 1.0), Color(1.0, 1.0, 1.0),
]
const POP_IN_S := 0.4
const HOLD_S := 2.0
const LEAVE_S := 0.35
const MAX_COINS := 10

## Distance of the card's centre from the top.
var top_offset := 430.0
## The wallet the reward coins fly to; no coins fly without one.
var wallet: Control
## Size of the flying coins.
var coin_radius := 18.0

var _queue: Array[AchievementDef] = []
var _showing := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func celebrate(def: AchievementDef) -> void:
	_queue.append(def)
	if not _showing:
		_show_next()


func is_showing() -> bool:
	return _showing


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var def: AchievementDef = _queue.pop_front()
	var center := Vector2(size.x * 0.5, top_offset)
	var rays := Rays.new()
	rays.position = center
	rays.scale = Vector2.ZERO
	add_child(rays)
	var card := _make_card(def)
	add_child(card)
	card.reset_size()
	card.pivot_offset = card.size * 0.5
	card.position = center - card.pivot_offset
	var fit := minf((size.x - 32.0) / card.size.x, 1.0) if size.x > 0.0 else 1.0
	card.scale = Vector2.ONE * 0.2 * fit
	card.rotation = deg_to_rad(-8.0)

	var tween := card.create_tween()
	tween.tween_property(card, "scale", Vector2.ONE * fit, POP_IN_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation", 0.0, POP_IN_S).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE * fit * 1.06, HOLD_S * 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(card, "scale", Vector2.ONE * fit, HOLD_S * 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(card, "position:y", card.position.y - 120.0, LEAVE_S).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(card, "modulate:a", 0.0, LEAVE_S)
	tween.tween_callback(card.queue_free)
	tween.tween_callback(_show_next)

	var radius := card.size.x * fit * 0.75
	var spin := rays.create_tween()
	spin.tween_property(rays, "scale", Vector2.ONE * radius, POP_IN_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spin.parallel().tween_property(rays, "rotation", PI * 0.5, POP_IN_S + HOLD_S + LEAVE_S)
	spin.parallel().tween_property(rays, "modulate:a", 0.0, LEAVE_S).set_delay(POP_IN_S + HOLD_S)
	spin.tween_callback(rays.queue_free)

	_confetti(center + Vector2(-card.size.x * 0.4 * fit, 0.0), Vector2(-0.4, -1.0))
	_confetti(center + Vector2(card.size.x * 0.4 * fit, 0.0), Vector2(0.4, -1.0))
	Sfx.play(&"fanfare")
	Haptics.bump()
	get_tree().create_timer(0.45).timeout.connect(Haptics.bump)
	if wallet and def.reward > 0.0:
		# From the reward line at the bottom of the card.
		_coin_shower(center + Vector2(0.0, card.size.y * 0.3 * fit), def.reward)


func _make_card(def: AchievementDef) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size.x = 640.0
	var style := StyleBoxTexture.new()
	style.texture = OverlayPanel.CARD_TEXTURE
	style.set_texture_margin_all(32.0)
	style.texture_margin_bottom = 40.0
	style.set_content_margin_all(48.0)
	style.content_margin_bottom = 52.0
	var grey := OverlayPanel.CARD_GREY
	style.modulate_color = Color(CARD_COLOR.r / grey, CARD_COLOR.g / grey, CARD_COLOR.b / grey)
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)

	column.add_child(_label(tr("Goal reached!"), 44, GOLD))
	var title := _label(tr(def.name), 92, Color.WHITE)
	title.theme_type_variation = &"TitleLabel"
	column.add_child(title)
	column.add_child(_label(tr(def.description), 38, OverlayPanel.MUTED))
	if def.reward > 0.0:
		column.add_child(_label(tr("+%s coins") % NumberFormat.compact(def.reward), 60, GOLD))
	return card


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Juice.OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", maxi(font_size / 5, 6))
	return label


## Paper bits shot out towards `direction`, tumbling as they fall.
func _confetti(at: Vector2, direction: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.position = at
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.amount = 48
	particles.lifetime = 1.8
	particles.direction = direction
	particles.spread = 30.0
	particles.gravity = Vector2(0.0, 900.0)
	particles.initial_velocity_min = 600.0
	particles.initial_velocity_max = 1100.0
	particles.damping_min = 300.0
	particles.damping_max = 500.0
	particles.angular_velocity_min = -540.0
	particles.angular_velocity_max = 540.0
	particles.angle_min = 0.0
	particles.angle_max = 360.0
	particles.scale_amount_min = 10.0
	particles.scale_amount_max = 18.0
	# A constant gradient picks one of the colors for each bit.
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	for i in CONFETTI_COLORS.size():
		offsets.append(float(i) / CONFETTI_COLORS.size())
	colors.offsets = offsets
	colors.colors = PackedColorArray(CONFETTI_COLORS)
	particles.color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	particles.color_ramp = fade
	particles.finished.connect(particles.queue_free)
	add_child(particles)
	particles.emitting = true


## Coins fly from the card to the wallet, one after the other, more for a bigger reward.
func _coin_shower(from: Vector2, reward: float) -> void:
	var count := clampi(int(log(reward) / log(10.0)) * 2, 3, MAX_COINS)
	var tween := create_tween()
	tween.tween_interval(POP_IN_S)
	for i in count:
		tween.tween_callback(_fly_coin.bind(from, 1.0 + i * 0.05))
		tween.tween_interval(0.08)


func _fly_coin(from: Vector2, pitch: float) -> void:
	if not is_instance_valid(wallet):
		return
	var to := wallet.get_global_rect().get_center() - get_global_rect().position
	var start := from + Vector2(randf_range(-120.0, 120.0), randf_range(-30.0, 30.0))
	Juice.fly_coin(self, start, to, coin_radius)
	Sfx.play(&"coin", pitch, -4.0)


## Light rays around the card, alternating with gaps. Drawn with radius 1, scaled to size.
class Rays extends Node2D:
	const COUNT := 14

	func _draw() -> void:
		var step := TAU / COUNT
		for i in COUNT:
			var a := i * step
			var b := a + step * 0.5
			draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a), Vector2.from_angle(b)]),
					Color(1.0, 0.9, 0.45, 0.35))
