class_name SizeComparison
extends Control
## The animal's silhouette next to the wader, both to true scale, so a krill is a speck and a
## blue whale dwarfs the person.

const PERSON := preload("res://assets/sprites/wader/wader_front.png")
## Walk frames plus the standing one, side by side in the sprite.
const PERSON_FRAMES := 5
## The wader sprite's height in real life.
const PERSON_CM := 180.0
const GAP_CM_SHARE := 0.08
## Animals are never drawn smaller than this, so a krill stays visible.
const MIN_ANIMAL_PX := 10.0

var art: FishArt:
	set(value):
		art = value
		queue_redraw()


func _draw() -> void:
	if art == null:
		return
	var frame := Vector2(PERSON.get_width() / float(PERSON_FRAMES), PERSON.get_height())
	var person_width_cm := PERSON_CM * frame.x / frame.y
	var animal_cm := art.species.length_cm
	var animal_height_cm := art.drawn_height(animal_cm)
	var gap_cm := maxf(person_width_cm, animal_cm) * GAP_CM_SHARE
	var px_per_cm := minf(size.y / maxf(PERSON_CM, animal_height_cm),
			size.x / (person_width_cm + gap_cm + animal_cm))
	var person_size := Vector2(person_width_cm, PERSON_CM) * px_per_cm
	var animal_length := maxf(animal_cm * px_per_cm, MIN_ANIMAL_PX)
	var total_width := person_size.x + gap_cm * px_per_cm + animal_length
	var left := (size.x - total_width) * 0.5
	draw_texture_rect_region(PERSON, Rect2(Vector2(left, size.y - person_size.y), person_size),
			Rect2(Vector2.ZERO, frame))
	# The animal floats beside the person, centred on half the person's height (or the row's,
	# when it is taller).
	var animal_height := art.drawn_height(animal_length)
	var center_y := size.y - maxf(person_size.y, animal_height) * 0.5
	var center := Vector2(left + person_size.x + gap_cm * px_per_cm + animal_length * 0.5, center_y)
	art.draw(self, Transform2D(0.0, center), animal_length)
