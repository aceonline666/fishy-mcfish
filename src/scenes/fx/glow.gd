class_name Glow
extends RefCounted
## Soft light in the dark: a round glow drawn additively, so it shines through the deep sea's
## darkness that tints everything else (SeaDepth). Draw it on a node with `material()`, which is
## not affected by the water shaders of the props and the fish.

static var _texture: GradientTexture2D
static var _material: CanvasItemMaterial


## A white disc fading out from the middle.
static func texture() -> Texture2D:
	if _texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		gradient.add_point(0.25, Color(1.0, 1.0, 1.0, 0.55))
		_texture = GradientTexture2D.new()
		_texture.gradient = gradient
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		_texture.width = 128
		_texture.height = 128
	return _texture


## Additive blending, shared by every node that draws glows.
static func material() -> CanvasItemMaterial:
	if _material == null:
		_material = CanvasItemMaterial.new()
		_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _material


## A glow of `radius` around `at`, flattened to `squash` of its height.
static func draw(canvas: CanvasItem, at: Vector2, radius: float, color: Color, squash: float = 1.0) -> void:
	canvas.draw_texture_rect(texture(), Rect2(at - Vector2(radius, radius * squash), Vector2(radius * 2.0, radius * 2.0 * squash)), false, color)
