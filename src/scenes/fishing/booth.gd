class_name Booth
extends Node2D
## A sales booth on the edge of the walkable beach, facing north: the buyer stands behind it
## facing the player, the seller in front of it, seen from behind. Booth 0 is the player's (no
## seller: the player sells from the "Sell fish" pad), the others are the hired sellers'.
## PLACEHOLDER sprites (assets/sprites/props/booth.svg, seller_back.svg) until the final art
## exists. The node sits at the foot of the booth.

const BOOTH_TEXTURE: Texture2D = preload("res://assets/sprites/props/booth.svg")
const SELLER_TEXTURE: Texture2D = preload("res://assets/sprites/props/seller_back.svg")
## Screen width of the booth and height of the seller.
const BOOTH_WIDTH := 150.0
const SELLER_HEIGHT := 175.0
## Where the buyer and the seller stand, seen from the booth (ground units).
const BUYER_OFFSET := Vector2(0.0, -95.0)
const SELLER_OFFSET := Vector2(0.0, 80.0)
## The player's booth is tinted in the colour of the "Sell fish" pad.
const PLAYER_TINT := Color(1.0, 0.75, 0.5)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)

var ground_position := Vector2.ZERO
## True for the player's booth: no seller.
var is_player := false


## `index` 0 is the player's booth, n the n-th seller's.
func setup(foot: Vector2, index: int) -> void:
	ground_position = foot
	position = Iso.to_screen(foot)
	is_player = index == 0
	queue_redraw()


## Ground position where the buyer at this booth stands.
func buyer_spot() -> Vector2:
	return ground_position + BUYER_OFFSET


## Quick hop when something is sold here.
func bounce() -> void:
	scale = Vector2(1.06, 0.94)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	draw_colored_polygon(Iso.ellipse(Vector2(4.0, 4.0), BOOTH_WIDTH * 0.55, 16), SHADOW)
	var size := BOOTH_TEXTURE.get_size() * (BOOTH_WIDTH / BOOTH_TEXTURE.get_width())
	draw_texture_rect(BOOTH_TEXTURE, Rect2(Vector2(-size.x * 0.5, -size.y), size), false,
			PLAYER_TINT if is_player else Color.WHITE)
	if not is_player:
		var seller := SELLER_TEXTURE.get_size() * (SELLER_HEIGHT / SELLER_TEXTURE.get_height())
		var foot := Iso.to_screen(SELLER_OFFSET)
		draw_texture_rect(SELLER_TEXTURE, Rect2(foot - Vector2(seller.x * 0.5, seller.y), seller), false)
