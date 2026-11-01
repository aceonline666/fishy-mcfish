class_name Booth
extends Node2D
## A sales booth in the line up the beach, facing east: the buyer stands in front of its counter,
## the seller behind it on the west side. Booth 0 is the player's (no seller: the player sells
## from the "Sell fish" pad), the others are the hired sellers'. Every booth looks like the shop's
## level: painted booths assets/sprites/props/booth_N.png (cut from
## art_source/"Isometrische Fischmarkt-Stände im Set.png"), painted with the counter along the
## south edge and drawn mirrored, so it runs along the east edge. The seller is a PLACEHOLDER
## (seller_back.svg) until the final art exists. A booth stands in one cell of the layout grid
## (Grid), its counter along the cell's east edge and as long as it; the seller stands behind it in
## the same cell. The node sits at the middle of that edge.

const BOOTH_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/props/booth_1.png"), preload("res://assets/sprites/props/booth_2.png"),
	preload("res://assets/sprites/props/booth_3.png"), preload("res://assets/sprites/props/booth_4.png"),
	preload("res://assets/sprites/props/booth_5.png"), preload("res://assets/sprites/props/booth_6.png"),
]
const SELLER_TEXTURE: Texture2D = preload("res://assets/sprites/props/seller_back.svg")
## The feet of each booth's front legs in its sprite (pixels), left and right: the booth is drawn
## mirrored so that they stand on the cell's east corners.
const FRONT_FEET: Array[Array] = [
	[Vector2(10.0, 288.0), Vector2(309.0, 426.0)], [Vector2(6.0, 274.0), Vector2(309.0, 432.0)],
	[Vector2(14.0, 292.0), Vector2(320.0, 428.0)], [Vector2(17.0, 328.0), Vector2(316.0, 456.0)],
	[Vector2(24.0, 312.0), Vector2(332.0, 465.0)], [Vector2(28.0, 358.0), Vector2(335.0, 475.0)],
]
const SELLER_HEIGHT := 175.0
## Where the buyer and the seller stand, seen from the booth (ground units).
const BUYER_OFFSET := Vector2(140.0, 0.0)
const SELLER_OFFSET := Vector2(-115.0, 0.0)
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


## Where the sprite is drawn, relative to the node, before mirroring.
func _sprite_rect() -> Rect2:
	var texture := BOOTH_TEXTURES[level - 1]
	var left: Vector2 = FRONT_FEET[level - 1][0]
	var right: Vector2 = FRONT_FEET[level - 1][1]
	var scale_factor := Iso.to_screen(Vector2(0.0, Grid.UNIT)).length() / left.distance_to(right)
	return Rect2(-(left + right) * 0.5 * scale_factor, texture.get_size() * scale_factor)


## Where the sprite is drawn, relative to the node.
func sprite_bounds() -> Rect2:
	var rect := _sprite_rect()
	return Rect2(-rect.end.x, rect.position.y, rect.size.x, rect.size.y)


func _draw() -> void:
	draw_colored_polygon(Iso.ellipse(Vector2(-4.0, 4.0), SHADOW_RADIUS, 16), SHADOW)
	# The seller stands behind the counter.
	if not is_player:
		var seller := SELLER_TEXTURE.get_size() * (SELLER_HEIGHT / SELLER_TEXTURE.get_height())
		var foot := Iso.to_screen(SELLER_OFFSET)
		draw_texture_rect(SELLER_TEXTURE, Rect2(foot - Vector2(seller.x * 0.5, seller.y), seller), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect(BOOTH_TEXTURES[level - 1], _sprite_rect(), false)
	draw_set_transform(Vector2.ZERO)
