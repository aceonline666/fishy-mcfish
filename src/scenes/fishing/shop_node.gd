class_name ShopNode
extends Node2D
## The fish shop on the beach: a painted building that gets bigger with its level
## (assets/sprites/props), with a cashier at a counter in front once a seller is hired. The node
## sits at the centre of the base.

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/shop_1.png"), preload("res://assets/sprites/props/shop_2.png"),
	preload("res://assets/sprites/props/shop_3.png"), preload("res://assets/sprites/props/shop_4.png"),
	preload("res://assets/sprites/props/shop_5.png"), preload("res://assets/sprites/props/shop_6.png"),
]
## Screen width of the shop per level.
const WIDTHS: Array[float] = [280.0, 330.0, 370.0, 470.0, 500.0, 620.0]
## How far below the node the bottom of the sprite reaches, as a share of its height.
const BASE_DROP := 0.15
const CASHIERS: Array[Texture2D] = [
	preload("res://assets/sprites/props/cashier_1.png"), preload("res://assets/sprites/props/cashier_2.png"),
	preload("res://assets/sprites/props/cashier_3.png"),
]
const CASHIER_HEIGHT := 150.0
## Screen offset between neighbouring counters (one step along the ground x axis), and where a
## buyer stands in front of a counter, seen from its foot.
const COUNTER_STEP := Vector2(72.0, 36.0)
const BUYER_OFFSET := Vector2(-55.0, 40.0)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)

var level := 1:
	set(value):
		level = value
		queue_redraw()
## Sellers at work: one cashier each, up to three counters.
var sellers := 0:
	set(value):
		sellers = value
		queue_redraw()


## Quick hop when something is sold.
func bounce() -> void:
	scale = Vector2(1.04, 0.96)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Where the buyer at counter `index` stands, relative to the parent. The places continue in a
## line along the counters, so the queue goes on past the last one.
func counter_front(index: int) -> Vector2:
	return position + _counter_foot(index) + BUYER_OFFSET


## Where coins pop up when something is sold, relative to the parent.
func counter_point() -> Vector2:
	return position + Vector2(0.0, -_sprite_rect().size.y * 0.45)


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
	# The counters stand in a row in front of the shop, on the side of the queue.
	for i in mini(sellers, CASHIERS.size()):
		var texture := CASHIERS[i]
		var size := texture.get_size() * (CASHIER_HEIGHT / texture.get_height())
		var foot := _counter_foot(i)
		draw_texture_rect(texture, Rect2(foot - Vector2(size.x * 0.5, size.y), size), false)


## The foot of counter `index`, relative to the shop.
func _counter_foot(index: int) -> Vector2:
	var rect := _sprite_rect()
	return Vector2(rect.size.x * 0.12, rect.size.y * 0.05 + 30.0) + COUNTER_STEP * index
