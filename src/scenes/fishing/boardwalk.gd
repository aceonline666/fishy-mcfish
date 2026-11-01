class_name Boardwalk
extends Node2D
## The wooden boardwalk on the beach: a painted pier on posts (assets/sprites/props/boardwalk.png,
## flipped from art_source/pier.png so its steps face the water and the lantern the shops). It
## marks the free path from the water up to the shops. It is drawn at any length, one cell per
## section: the painting is cut (tools/cut_boardwalk.py) into the steps, a section that repeats
## and the lantern end.

const STEPS := preload("res://assets/sprites/props/boardwalk_steps.png")
const SECTION := preload("res://assets/sprites/props/boardwalk_section.png")
const LANTERN := preload("res://assets/sprites/props/boardwalk_lantern.png")
## Top-left corners of the pieces in the uncut painting (pixels), as tools/cut_boardwalk.py
## prints them.
const STEPS_AT := Vector2(0.0, 508.0)
const SECTION_AT := Vector2(335.0, 373.0)
const LANTERN_AT := Vector2(561.0, 0.0)
## The deck's two ends in the painting (pixels): the middle of the step end and of the lantern end.
## The pier is drawn so that this line runs along the walk (turned by the few degrees its
## drawing differs from the iso grid).
const WATER_END := Vector2(194.0, 722.0)
const SHORE_END := Vector2(1134.0, 202.0)
## The painting is this many sections long; one of them is SECTION.
const SECTIONS := 4
const SECTION_STEP := (SHORE_END - WATER_END) / SECTIONS

## Ground rectangle covered by the walk.
var area := Rect2()


func setup(ground_area: Rect2) -> void:
	area = ground_area
	queue_redraw()


func _draw() -> void:
	var water := Iso.to_screen(Vector2(area.get_center().x, area.end.y))
	var shore := Iso.to_screen(Vector2(area.get_center().x, area.position.y))
	var sections := maxi(roundi(area.size.y / Grid.UNIT), SECTIONS - 1)
	var scale_factor := water.distance_to(shore) / (SECTION_STEP.length() * sections)
	var turn := (shore - water).angle() - SECTION_STEP.angle()
	draw_set_transform(water, turn, Vector2.ONE * scale_factor)
	# From the shore end down, so the nearer piece covers the overlap.
	var extra := sections - SECTIONS
	draw_texture(LANTERN, LANTERN_AT - WATER_END + SECTION_STEP * extra)
	for i in range(extra, -1, -1):
		draw_texture(SECTION, SECTION_AT - WATER_END + SECTION_STEP * i)
	draw_texture(STEPS, STEPS_AT - WATER_END)
	draw_set_transform(Vector2.ZERO)
