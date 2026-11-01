class_name Grid
extends RefCounted
## The layout grid of the beach and the gear shop's room: square cells of ground, each as wide as
## the pier's walkable deck. Pads, booths, tanks and buildings cover whole cells: their place is
## the cell at their north-west corner, their size is in cells, east-west (ground x) by
## north-south (ground y). Cell (0, 0) has its north-west corner at the ground origin, so rows
## north of it (up the beach) are negative, as the ground y there.

## Side of a cell in ground units.
const UNIT := 240.0


## Ground rectangle covered by `size` cells from `cell` on.
static func rect(cell: Vector2i, size: Vector2i = Vector2i.ONE) -> Rect2:
	return Rect2(Vector2(cell) * UNIT, Vector2(size) * UNIT)


## Ground centre of `size` cells from `cell` on.
static func center(cell: Vector2i, size: Vector2i = Vector2i.ONE) -> Vector2:
	return rect(cell, size).get_center()


## Scale at which a sprite fits a footprint of `size` cells. `left`, `bottom` and `right` are the
## corners of the sprite's own footprint (pixels): its west, south and east corners on screen.
## A sprite whose footprint has other proportions is drawn as big as fits inside.
static func fit_scale(left: Vector2, bottom: Vector2, right: Vector2, size: Vector2i) -> float:
	var width := Iso.to_screen(Vector2(size.x * UNIT, 0.0)).length() / left.distance_to(bottom)
	var depth := Iso.to_screen(Vector2(0.0, size.y * UNIT)).length() / bottom.distance_to(right)
	return minf(width, depth)
