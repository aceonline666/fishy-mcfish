class_name PlayArea
extends RefCounted
## A rectangle of ground: the water fish swim in, or the whole walkable spot.

var rect: Rect2


func _init(ground_rect: Rect2) -> void:
	rect = ground_rect


## True if the point is inside, at least `margin` away from the edges.
func contains(ground: Vector2, margin: float = 0.0) -> bool:
	return rect.grow(-margin).has_point(ground)


## The nearest point that is inside with the given margin.
func clamp_point(ground: Vector2, margin: float = 0.0) -> Vector2:
	var inner := rect.grow(-margin)
	return ground.clamp(inner.position, inner.end)


func center() -> Vector2:
	return rect.get_center()


func random_point(rng: RandomNumberGenerator, margin: float = 0.0) -> Vector2:
	var inner := rect.grow(-margin)
	return Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
