extends Node
## Short vibrations for game feedback. Respects the player's setting.

var enabled := true


## Light feedback, e.g. one fish caught.
func tick() -> void:
	_vibrate(15)


## Strong feedback, e.g. a rare fish or a combo.
func bump() -> void:
	_vibrate(45)


func _vibrate(duration_ms: int) -> void:
	if enabled and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)
