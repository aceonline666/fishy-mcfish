class_name PlayArea
extends RefCounted
## The water region of a fishing spot, in ground coordinates: the visible screen area between
## the HUD bars, cut off by the shoreline. Fish swim and the wader walks inside it.

var screen_rect: Rect2
## Ground y of the waterline. Water is where ground y is larger; the beach is beyond.
var shore_y: float


func _init(visible_rect: Rect2, waterline_y: float) -> void:
	screen_rect = visible_rect
	shore_y = waterline_y


## True if the point is in the water, at least `margin` away from the edges and the shore.
func contains(ground: Vector2, margin: float = 0.0) -> bool:
	return screen_rect.grow(-margin).has_point(Iso.to_screen(ground)) and ground.y >= shore_y + margin


## The nearest point that is in the water with the given margin.
func clamp_point(ground: Vector2, margin: float = 0.0) -> Vector2:
	var inner := screen_rect.grow(-margin)
	var clamped := Iso.to_ground(Iso.to_screen(ground).clamp(inner.position, inner.end))
	clamped.y = maxf(clamped.y, shore_y + margin)
	return clamped


## A point in open water, used as the "come back here" target for fish near the edges.
func center() -> Vector2:
	var middle := Vector2(screen_rect.get_center().x, screen_rect.position.y + screen_rect.size.y * 0.6)
	return clamp_point(Iso.to_ground(middle), 150.0)


func random_point(rng: RandomNumberGenerator, margin: float = 0.0) -> Vector2:
	for attempt in 50:
		var screen := Vector2(
			rng.randf_range(screen_rect.position.x, screen_rect.end.x),
			rng.randf_range(screen_rect.position.y, screen_rect.end.y))
		var ground := Iso.to_ground(screen)
		if contains(ground, margin):
			return ground
	return center()
