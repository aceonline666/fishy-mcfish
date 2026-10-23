class_name Iso
extends RefCounted
## 2:1 isometric projection, as in Diablo II. Game logic runs in flat ground coordinates;
## only drawing converts to screen coordinates. Ground +x points down-right on screen,
## ground +y down-left. A ground circle of radius r appears as an ellipse r wide and r/2 high.

const BASIS := Transform2D(Vector2(0.70710678, 0.35355339), Vector2(-0.70710678, 0.35355339), Vector2.ZERO)


static func to_screen(ground: Vector2) -> Vector2:
	return BASIS.basis_xform(ground)


static func to_ground(screen: Vector2) -> Vector2:
	var a := screen.x / 0.70710678
	var b := screen.y / 0.35355339
	return Vector2(a + b, b - a) * 0.5


## Screen outline of a ground circle.
static func ellipse(center: Vector2, radius: float, segments: int = 24) -> PackedVector2Array:
	return ellipse_arc(center, radius, 0.0, TAU, segments)


## Part of a ground circle's screen outline. Angles are screen angles (0 = right, clockwise).
static func ellipse_arc(center: Vector2, radius: float, from_angle: float, to_angle: float, segments: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments + 1:
		var angle := lerpf(from_angle, to_angle, float(i) / segments)
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.5))
	return points
