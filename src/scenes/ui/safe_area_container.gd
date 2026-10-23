class_name SafeAreaContainer
extends MarginContainer
## Keeps its content clear of notches and gesture bars, plus a fixed edge padding.

@export var edge_padding := 24


func _ready() -> void:
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var insets := Platform.safe_area_margins(get_viewport())
	add_theme_constant_override("margin_left", edge_padding + int(insets.x))
	add_theme_constant_override("margin_top", edge_padding + int(insets.y))
	add_theme_constant_override("margin_right", edge_padding + int(insets.z))
	add_theme_constant_override("margin_bottom", edge_padding + int(insets.w))
