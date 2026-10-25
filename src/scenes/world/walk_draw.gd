class_name WalkDraw
extends RefCounted
## Walking for painted one-frame figures: the sprite is cut at the hips into the upper body and
## a left and a right leg. While walking, the legs swing from the hips in turn and shorten as the
## foot lifts (a bent knee), and the upper body bobs with every step.

## Share of the sprite's height above the hips; hands and bags held low stay with the body.
const HIP := 0.66
## At full stride: how far a leg swings (radians) and how much shorter a lifted leg gets.
const SWING := 0.16
const BEND := 0.14


## Draws `texture` into `rect` (feet at the bottom) on `canvas`, on top of the transform `base`
## (which is set again afterwards). `phase` advances with the distance walked (one step per half
## turn), `stride` is 0 standing to 1 at full speed, `bob` lifts the upper body.
static func figure(canvas: CanvasItem, base: Transform2D, texture: Texture2D, rect: Rect2, phase: float, stride: float, bob: float) -> void:
	canvas.draw_set_transform_matrix(base)
	if stride <= 0.01:
		canvas.draw_texture_rect(texture, Rect2(rect.position + Vector2(0.0, -bob), rect.size), false)
		return
	var source := texture.get_size()
	var scale := rect.size / source
	var hip := source.y * HIP
	for side in 2:
		var step := sin(phase + PI * side)
		var region := Rect2(source.x * 0.5 * side, hip, source.x * 0.5, source.y - hip)
		var top := rect.position + region.position * scale
		var size := region.size * scale
		# Pivot at the top middle of the leg, so it stays attached to the body.
		var pivot := top + Vector2(size.x * 0.5, 0.0)
		var leg := Transform2D(step * SWING * stride, Vector2(1.0, 1.0 - maxf(step, 0.0) * BEND * stride), 0.0, pivot)
		canvas.draw_set_transform_matrix(base * leg)
		canvas.draw_texture_rect_region(texture, Rect2(top - pivot, size), region)
	canvas.draw_set_transform_matrix(base)
	# The upper body reaches a little below the hips, so no gap shows above the legs.
	var upper := Rect2(0.0, 0.0, source.x, hip + source.y * 0.03)
	canvas.draw_texture_rect_region(texture, Rect2(rect.position + Vector2(0.0, -bob), upper.size * scale), upper)
