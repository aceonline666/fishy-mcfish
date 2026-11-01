class_name Layers
extends RefCounted
## Drawing layers of the beach and the gear shop's room, bottom to top (z_index). Within OBJECTS
## things are depth-sorted: what stands further south or east is drawn in front. The wader is on
## its own layer above the pads and their texts, except while an object stands in front of it
## (Cover): then it is sorted in among the objects, behind that one, and a see-through copy of it
## shows on its own layer. All layers are below 0, so the HUD, popups and panels (z_index 0)
## stay in front of the world.

## The scene's background behind the world: the water colour, the store's wall colour.
const BACKGROUND := -8
## Sand, sea, seabed, buoys, the pier, the drones' dock and the sales belt.
const FLOOR := -7
## The sprites standing on the ground: buildings, the tank, the market's backdrop, booths, props,
## buyers and sellers, and the fish in the sea.
const OBJECTS := -6
## The pads' slabs.
const PADS := -5
## The pads' pictures and texts.
const PAD_TEXT := -4
## The wader, its see-through copy and its catch ring.
const WADER := -3
## Drones.
const FLYING := -2
## Splashes, ripples and other effects.
const EFFECTS := -1


## Something on the ground the wader can walk behind: the screen rectangle its sprite covers and
## the screen y it is depth-sorted by (its node's), both in the coordinates of the node's parent.
class Cover:
	var bounds: Rect2
	var sort_y: float

	func _init(cover_bounds: Rect2, cover_sort_y: float) -> void:
		bounds = cover_bounds
		sort_y = cover_sort_y


## Draws `item` on `layer`, whatever its parent's layer.
static func put(item: CanvasItem, layer: int) -> void:
	item.z_as_relative = false
	item.z_index = layer


## The cover of a node whose sprite covers `local_bounds` (relative to the node).
static func cover(node: Node2D, local_bounds: Rect2) -> Cover:
	return Cover.new(Rect2(node.position + local_bounds.position, local_bounds.size), node.position.y)


## The cover of a Sprite2D.
static func sprite_cover(sprite: Sprite2D) -> Cover:
	var rect := sprite.get_rect()
	return cover(sprite, Rect2(rect.position * sprite.scale, rect.size * sprite.scale))
