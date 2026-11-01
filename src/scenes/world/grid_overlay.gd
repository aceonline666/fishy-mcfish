class_name GridOverlay
extends Node2D
## Draws the layout grid (Grid) over an area with each cell's coordinates, to lay things out.
## Shown when a scene's SHOW_GRID is set.

const LINE_COLOR := Color(1.0, 0.2, 1.0, 0.55)
const TEXT_COLOR := Color(1.0, 1.0, 1.0, 0.8)

## The cells to draw.
var cells := Rect2i()


func setup(area: Rect2i) -> void:
	cells = area
	queue_redraw()


func _draw() -> void:
	for x in range(cells.position.x, cells.end.x + 1):
		draw_line(Iso.to_screen(Vector2(x, cells.position.y) * Grid.UNIT), Iso.to_screen(Vector2(x, cells.end.y) * Grid.UNIT), LINE_COLOR, 3.0)
	for y in range(cells.position.y, cells.end.y + 1):
		draw_line(Iso.to_screen(Vector2(cells.position.x, y) * Grid.UNIT), Iso.to_screen(Vector2(cells.end.x, y) * Grid.UNIT), LINE_COLOR, 3.0)
	for x in range(cells.position.x, cells.end.x):
		for y in range(cells.position.y, cells.end.y):
			IsoDraw.label(self, Iso.to_screen(Grid.center(Vector2i(x, y))), "%d,%d" % [x, y], 22, TEXT_COLOR)
