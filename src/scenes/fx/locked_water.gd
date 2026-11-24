class_name LockedWater
extends Node2D
## Marks the zones the wader's gear cannot reach yet: the water beyond the barrier glows red for a
## moment, with a lock in it. Lives in the world (ground drawn with Iso); show() starts it again.

const COLOR := Color(1.0, 0.18, 0.12, 0.3)
const FADE_IN_S := 0.2
const HOLD_S := 1.2
const FADE_OUT_S := 0.6
## The lock's size in the world, relative to its size on screen.
const LOCK_SCALE := 1.4

## The locked water (ground rect) and where the lock goes (ground point).
var area := Rect2()
var lock_at := Vector2.ZERO

var _tween: Tween
var _lock: LockPopup


func flash(locked: Rect2, lock_ground: Vector2) -> void:
	area = locked
	lock_at = lock_ground
	if _tween:
		_tween.kill()
	if _lock:
		_lock.queue_free()
	_lock = LockPopup.new()
	_lock.full_scale = LOCK_SCALE
	_lock.position = Iso.to_screen(lock_at)
	add_child(_lock)
	queue_redraw()
	show()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_S)
	_tween.tween_interval(HOLD_S)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_S)
	_tween.tween_callback(hide)


func is_showing() -> bool:
	return visible and modulate.a > 0.0


func _draw() -> void:
	if not area.has_area():
		return
	draw_colored_polygon(PackedVector2Array([
		Iso.to_screen(area.position), Iso.to_screen(Vector2(area.end.x, area.position.y)),
		Iso.to_screen(area.end), Iso.to_screen(Vector2(area.position.x, area.end.y)),
	]), COLOR)
