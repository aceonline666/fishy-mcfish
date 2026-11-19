class_name SafeAreaContainer
extends MarginContainer
## Keeps its content clear of notches and gesture bars, plus a fixed edge padding. With a
## max_content_width, wide screens (landscape) get wider side margins, so the content stays a
## centred column.

@export var edge_padding := 24
## The widest the content may get (pixels); 0 for no limit.
@export var max_content_width := 0.0


func _ready() -> void:
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var insets := Platform.safe_area_margins(get_viewport())
	var left := edge_padding + int(insets.x)
	var right := edge_padding + int(insets.z)
	if max_content_width > 0.0:
		var width := get_viewport().get_visible_rect().size.x
		var extra := int(maxf(0.0, (width - left - right - max_content_width) * 0.5))
		left += extra
		right += extra
	add_theme_constant_override("margin_left", left)
	add_theme_constant_override("margin_top", edge_padding + int(insets.y))
	add_theme_constant_override("margin_right", right)
	add_theme_constant_override("margin_bottom", edge_padding + int(insets.w))
