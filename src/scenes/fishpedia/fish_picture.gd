class_name FishPicture
extends Control
## Draws one species side-on, centred and scaled to fit. Unknown species appear as a silhouette.

const SILHOUETTE := Color(0.08, 0.12, 0.2, 0.85)

var art: FishArt:
	set(value):
		art = value
		queue_redraw()
var known := true:
	set(value):
		known = value
		queue_redraw()
## Fraction of the width a large fish fills; small fish are drawn smaller.
var fill := 0.85


func _draw() -> void:
	if art == null:
		return
	# Size relative to the biggest fish, so a sprat looks small next to a conger.
	var relative := clampf(CatchRules.body_length(art.species) / 240.0, 0.55, 1.0)
	var length := minf(size.x * fill * relative, size.y * 2.2)
	var view := Transform2D(Vector2(1.0, 0.0), Vector2(0.0, 1.0), size * 0.5)
	art.draw(self, view, length, 0.0, 0.0, Color.WHITE if known else SILHOUETTE)
