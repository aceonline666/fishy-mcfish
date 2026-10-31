class_name ShopNode
extends Node2D
## The fish shop on the beach: a painted building that gets bigger with its level
## (assets/sprites/props). The sales booths stand apart (Booth). The node sits at the centre of
## the base.

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/shop_1.png"), preload("res://assets/sprites/props/shop_2.png"),
	preload("res://assets/sprites/props/shop_3.png"), preload("res://assets/sprites/props/shop_4.png"),
	preload("res://assets/sprites/props/shop_5.png"), preload("res://assets/sprites/props/shop_6.png"),
]
## Screen width of the shop per level.
const WIDTHS: Array[float] = [280.0, 330.0, 370.0, 470.0, 500.0, 620.0]
## How far below the node the bottom of the sprite reaches, as a share of its height.
const BASE_DROP := 0.15
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)

var level := 1:
	set(value):
		level = value
		queue_redraw()


## Quick hop when something is sold.
func bounce() -> void:
	scale = Vector2(1.04, 0.96)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _texture() -> Texture2D:
	return TEXTURES[clampi(level, 1, TEXTURES.size()) - 1]


func _sprite_rect() -> Rect2:
	var texture := _texture()
	var width := WIDTHS[clampi(level, 1, WIDTHS.size()) - 1]
	var size := texture.get_size() * (width / texture.get_width())
	return Rect2(Vector2(-size.x * 0.5, -size.y * (1.0 - BASE_DROP)), size)


func _draw() -> void:
	var rect := _sprite_rect()
	draw_colored_polygon(Iso.ellipse(Vector2(12.0, 8.0), rect.size.x * 0.45, 24), SHADOW)
	draw_texture_rect(_texture(), rect, false)
