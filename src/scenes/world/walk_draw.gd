class_name WalkDraw
extends RefCounted
## Walking for painted one-frame figures: the sprite is cut at the hips into the upper body and
## a left and a right leg. While walking, the legs swing from the hips in turn and shorten as the
## foot lifts (a bent knee), and the upper body bobs and rocks a little with every step. With a
## legs width, only the middle columns below the hips are legs: what hangs beside them (a bag in
## the hand) stays with the body.

## Share of the sprite's height above the hips; hands and bags held low stay with the body.
const HIP := 0.66
## At full stride: how far a leg swings (radians) and how much shorter a lifted leg gets.
const SWING := 0.16
const BEND := 0.14
## How far the upper body rocks from side to side at full stride (radians).
const ROCK := 0.035


## Draws `texture` into `rect` (feet at the bottom) on `canvas`, on top of the transform `base`
## (which is set again afterwards). `phase` advances with the distance walked (one step per half
## turn), `stride` is 0 standing to 1 at full speed, `bob` lifts the upper body. `hip` is the share
## of the height above the hips; 0 for a sprite of legs only. `legs` is the legs' half width as a
## share of the height, around the sprite's middle (0: the whole width below the hips).
static func figure(canvas: CanvasItem, base: Transform2D, texture: Texture2D, rect: Rect2, phase: float, stride: float, bob: float, hip: float = HIP, legs: float = 0.0) -> void:
	canvas.draw_set_transform_matrix(base)
	if stride <= 0.01:
		canvas.draw_texture_rect(texture, Rect2(rect.position + Vector2(0.0, -bob), rect.size), false)
		return
	var source := texture.get_size()
	var scale := rect.size / source
	var hip_y := source.y * hip
	var half := minf(source.y * legs, source.x * 0.5) if legs > 0.0 else source.x * 0.5
	var middle := source.x * 0.5
	for side in 2:
		var step := sin(phase + PI * side)
		var region := Rect2(middle - half + half * side, hip_y, half, source.y - hip_y)
		var top := rect.position + region.position * scale
		var size := region.size * scale
		# Pivot at the top middle of the leg, so it stays attached to the body.
		var pivot := top + Vector2(size.x * 0.5, 0.0)
		var leg := Transform2D(step * SWING * stride, Vector2(1.0, 1.0 - maxf(step, 0.0) * BEND * stride), 0.0, pivot)
		canvas.draw_set_transform_matrix(base * leg)
		canvas.draw_texture_rect_region(texture, Rect2(top - pivot, size), region)
	if hip_y <= 0.0:
		canvas.draw_set_transform_matrix(base)
		return
	# The upper body rocks about the hips with the steps.
	var hip_point := rect.position + Vector2(middle, hip_y) * scale
	var rock := Transform2D(sin(phase) * ROCK * stride, hip_point + Vector2(0.0, -bob)) * Transform2D(0.0, -hip_point)
	canvas.draw_set_transform_matrix(base * rock)
	# The upper body reaches a little below the hips, so no gap shows above the legs; what hangs
	# beside the legs goes with it.
	var upper := Rect2(0.0, 0.0, source.x, hip_y + source.y * 0.03)
	canvas.draw_texture_rect_region(texture, Rect2(rect.position, upper.size * scale), upper)
	for strip: Rect2 in [Rect2(0.0, hip_y, middle - half, source.y - hip_y), Rect2(middle + half, hip_y, source.x - middle - half, source.y - hip_y)]:
		if strip.size.x > 0.0:
			canvas.draw_texture_rect_region(texture, Rect2(rect.position + strip.position * scale, strip.size * scale), strip)
	canvas.draw_set_transform_matrix(base)
