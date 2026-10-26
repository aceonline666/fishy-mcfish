class_name Boardwalk
extends Node2D
## The wooden boardwalk on the beach: a painted pier on posts (assets/sprites/props/boardwalk.png,
## flipped from art_source/pier.png so its steps face the water and the lantern the shops). It
## marks the free path from the water up to the shops.

const TEXTURE := preload("res://assets/sprites/props/boardwalk.png")
## The deck's two ends in the sprite (pixels): the middle of the step end and of the lantern end.
## The sprite is drawn so that this line runs along the walk (turned by the few degrees its
## drawing differs from the iso grid).
const WATER_END := Vector2(194.0, 722.0)
const SHORE_END := Vector2(1134.0, 202.0)

## Ground rectangle covered by the walk.
var area := Rect2()


func setup(ground_area: Rect2) -> void:
	area = ground_area
	queue_redraw()


func _draw() -> void:
	var water := Iso.to_screen(Vector2(area.get_center().x, area.end.y))
	var shore := Iso.to_screen(Vector2(area.get_center().x, area.position.y))
	var scale_factor := water.distance_to(shore) / WATER_END.distance_to(SHORE_END)
	var turn := (shore - water).angle() - (SHORE_END - WATER_END).angle()
	draw_set_transform(water, turn, Vector2.ONE * scale_factor)
	draw_texture(TEXTURE, -WATER_END)
	draw_set_transform(Vector2.ZERO)
