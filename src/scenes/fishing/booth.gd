class_name Booth
extends Node2D
## A sales booth on the edge of the walkable beach, facing north: the buyer stands behind it
## facing the player, the seller in front of it, seen from behind. Booth 0 is the player's (no
## seller: the player sells from the "Sell fish" pad), the others are the hired sellers'. Every
## booth looks like the shop's level: painted booths assets/sprites/props/booth_N.png (cut from
## art_source/"Isometrische Fischmarkt-Upgrade-Stände.png"), seen from the seller's side. The
## seller is a PLACEHOLDER (seller_back.svg) until the final art exists. The node sits at the
## foot of the booth.

const BOOTH_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/booth_1.png"), preload("res://assets/sprites/props/booth_2.png"),
	preload("res://assets/sprites/props/booth_3.png"), preload("res://assets/sprites/props/booth_4.png"),
	preload("res://assets/sprites/props/booth_5.png"), preload("res://assets/sprites/props/booth_6.png"),
]
const SELLER_TEXTURE: Texture2D = preload("res://assets/sprites/props/seller_back.svg")
## The booths are drawn at this share of their painted size (all levels alike, so the counters
## stay at the same height), and the seller this tall.
const BOOTH_SCALE := 0.6
const SELLER_HEIGHT := 175.0
## Where the buyer and the seller stand, seen from the booth (ground units).
const BUYER_OFFSET := Vector2(0.0, -140.0)
const SELLER_OFFSET := Vector2(0.0, 115.0)
const SHADOW := Color(0.0, 0.06, 0.14, 0.2)
const SHADOW_RADIUS := 130.0

var ground_position := Vector2.ZERO
## True for the player's booth: no seller.
var is_player := false
## The shop's level (data/shop_levels.csv), which the booth looks like.
var level := 1:
	set(value):
		level = clampi(value, 1, BOOTH_TEXTURES.size())
		queue_redraw()


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
	draw_colored_polygon(Iso.ellipse(Vector2(4.0, 4.0), SHADOW_RADIUS, 16), SHADOW)
	var texture := BOOTH_TEXTURES[level - 1]
	var size := texture.get_size() * BOOTH_SCALE
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), false)
	if not is_player:
		var seller := SELLER_TEXTURE.get_size() * (SELLER_HEIGHT / SELLER_TEXTURE.get_height())
		var foot := Iso.to_screen(SELLER_OFFSET)
		draw_texture_rect(SELLER_TEXTURE, Rect2(foot - Vector2(seller.x * 0.5, seller.y), seller), false)
