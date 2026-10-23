extends Control
## Root of the game. Holds the fishing spot and swaps in a fresh one after travelling.

const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")

var _spot: Control


func _ready() -> void:
	_spot = $FishingScene
	_spot.connect("travel_requested", _on_travel_requested)


## The player moved to another location: rebuild the spot for it.
func _on_travel_requested() -> void:
	_spot.queue_free()
	_spot = FishingSceneFile.instantiate()
	_spot.connect("travel_requested", _on_travel_requested)
	add_child(_spot)
