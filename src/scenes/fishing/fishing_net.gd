class_name FishingNet
extends Node2D
## The player's net. Follows the finger and holds the haul until the finger lifts.
## Drawn in code until real art arrives in M6.

const OUTLINE_COLOR := Color(0.07, 0.09, 0.15)
const RIM_COLOR := Color(0.93, 0.78, 0.5)
const RIM_FULL_COLOR := Color(1.0, 0.45, 0.3)
const FILL_COLOR := Color(1.0, 1.0, 1.0, 0.1)
const MESH_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const SHADOW_COLOR := Color(0.0, 0.06, 0.14, 0.18)
const PROGRESS_COLOR := Color(1.0, 0.85, 0.2)
const MESH_SPACING := 26.0
const LABEL_FONT_SIZE := 36

@export var radius := 130.0

var capacity := 5
var haul: Array[SpeciesDef] = []
## How close the furthest-along struggling fish is to being caught, 0..1.
var struggle_progress := 0.0
## True when no more fish fit (net or live-well).
var full := false


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func appear() -> void:
	show()
	scale = Vector2.ONE * 0.5
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 0.2, 0.12).set_ease(Tween.EASE_IN)
	tween.tween_callback(hide)


## Quick squash when a fish goes in.
func pulse() -> void:
	scale = Vector2.ONE * 1.12
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	draw_circle(Vector2(10.0, 18.0), radius, SHADOW_COLOR)
	draw_circle(Vector2.ZERO, radius, FILL_COLOR)
	_draw_mesh()
	_draw_haul()

	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, OUTLINE_COLOR, 16.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, RIM_FULL_COLOR if full else RIM_COLOR, 9.0, true)

	if struggle_progress > 0.0:
		var end_angle := -PI * 0.5 + TAU * struggle_progress
		draw_arc(Vector2.ZERO, radius + 18.0, -PI * 0.5, end_angle, 48, OUTLINE_COLOR, 14.0, true)
		draw_arc(Vector2.ZERO, radius + 18.0, -PI * 0.5, end_angle, 48, PROGRESS_COLOR, 8.0, true)

	var text := "FULL" if full else "%d/%d" % [haul.size(), capacity]
	var font := ThemeDB.fallback_font
	var at := Vector2(-radius, radius + 56.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, LABEL_FONT_SIZE, 10, OUTLINE_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, LABEL_FONT_SIZE)


## Diagonal cross-hatch clipped to the circle.
func _draw_mesh() -> void:
	for direction: Vector2 in [Vector2(1.0, 1.0).normalized(), Vector2(1.0, -1.0).normalized()]:
		var across := direction.orthogonal()
		var offset := -radius + MESH_SPACING * 0.5
		while offset < radius:
			var half_chord := sqrt(radius * radius - offset * offset)
			draw_line(across * offset - direction * half_chord, across * offset + direction * half_chord, MESH_COLOR, 2.0, true)
			offset += MESH_SPACING


## One coloured blob per fish already in the net.
func _draw_haul() -> void:
	for i in haul.size():
		var at := Vector2.from_angle(TAU * i / maxf(capacity, 1) + 0.4) * radius * 0.45
		draw_circle(at, 16.0, haul[i].placeholder_color)
		draw_arc(at, 16.0, 0.0, TAU, 20, OUTLINE_COLOR, 3.0, true)
