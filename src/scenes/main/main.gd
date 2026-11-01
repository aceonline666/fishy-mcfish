extends Control
## Root of the game. Holds the fishing spot and swaps in a fresh one after travelling, loading
## or starting a new game. The upgrade store opens over the spot, which waits behind it.

const FishingSceneFile := preload("res://src/scenes/fishing/fishing_scene.tscn")
## The boot splash (project settings) fades into the game instead of cutting to it.
const SPLASH := preload("res://assets/ui/splash.png")
const SPLASH_HOLD_S := 0.3
const SPLASH_FADE_S := 0.6

var _spot: Control
var _store: UpgradeStore


func _ready() -> void:
	_spot = $FishingScene
	_connect_spot()
	_fade_from_splash()


func _fade_from_splash() -> void:
	var cover := TextureRect.new()
	cover.texture = SPLASH
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	var tween := create_tween()
	tween.tween_interval(SPLASH_HOLD_S)
	tween.tween_property(cover, "modulate:a", 0.0, SPLASH_FADE_S)
	tween.tween_callback(cover.queue_free)


## The player moved to another location or the game state was replaced: rebuild the spot.
func _on_rebuild_requested() -> void:
	_spot.queue_free()
	_spot = FishingSceneFile.instantiate()
	_connect_spot()
	add_child(_spot)


func _connect_spot() -> void:
	_spot.connect("rebuild_requested", _on_rebuild_requested)
	_spot.connect("store_requested", _on_store_requested)


## The wader went into the gear shop: the beach stops (its drones fish unwatched) and hides.
func _on_store_requested() -> void:
	_spot.hide()
	_spot.process_mode = Node.PROCESS_MODE_DISABLED
	GameState.in_store = true
	_store = UpgradeStore.new()
	_store.left.connect(_on_store_left)
	add_child(_store)


func _on_store_left() -> void:
	_store.queue_free()
	_store = null
	GameState.in_store = false
	_spot.process_mode = Node.PROCESS_MODE_INHERIT
	_spot.show()
	_spot.call("return_from_store")
