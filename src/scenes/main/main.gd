extends Control
## Root of the game. Holds the fishing spot and swaps in a fresh one after travelling, loading
## or starting a new game.

const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")

var _spot: Control


func _ready() -> void:
	_spot = $FishingScene
	_spot.connect("rebuild_requested", _on_rebuild_requested)


## The player moved to another location or the game state was replaced: rebuild the spot.
func _on_rebuild_requested() -> void:
	_spot.queue_free()
	_spot = FishingSceneFile.instantiate()
	_spot.connect("rebuild_requested", _on_rebuild_requested)
	add_child(_spot)
