class_name GearShopNode
extends Node2D
## The gear shop on the beach, where the upgrades are bought (UpgradeStore): a big building with
## its door at the west end of its front, towards the boardwalk, and a sign on the roof.
## PLACEHOLDER sprite (assets/sprites/props/gear_shop.svg, drawn at ground scale) until the final
## art exists; the sign's text is drawn in code so it is translated. The node sits at the middle
## of the building's footprint.

const TEXTURE: Texture2D = preload("res://assets/sprites/props/gear_shop.svg")
## Where the middle of the footprint and the sign are in the sprite.
const ANCHOR := Vector2(740.0, 720.0)
const SIGN := Vector2(0.0, -470.0)
const SIGN_TEXT_COLOR := Color(0.25, 0.14, 0.05)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _draw() -> void:
	draw_texture(TEXTURE, -ANCHOR)
	IsoDraw.label(self, SIGN + Vector2(0.0, 14.0), tr("Fishing gear"), 64, SIGN_TEXT_COLOR, true)
