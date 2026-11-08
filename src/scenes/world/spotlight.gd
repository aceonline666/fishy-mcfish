class_name Spotlight
extends RefCounted
## The submarine's spotlight, for what is lit as a whole (a fish or a seabed prop takes the light
## at its ground point): the same cone and pool as src/shaders/spotlight.gdshaderinc, which lights
## the water and the seabed per pixel. Keep the two in step.

const RANGE := 900.0
const COS_INNER := 0.94
const COS_OUTER := 0.8
const POOL := 220.0
## Lit, the water's tint lifts by this share and the deep sea's dark by DARK_LIFT (as in the
## shaders).
const DEPTH_LIFT := 0.6
const DARK_LIFT := 0.85


## 0 to 1, how brightly ground point `ground` is lit by a light at `origin` pointing along `dir`
## (a unit vector), switched on by `on` (0 to 1).
static func amount(ground: Vector2, origin: Vector2, dir: Vector2, on: float) -> float:
	if on <= 0.0:
		return 0.0
	var to := ground - origin
	var dist := to.length()
	var cone := smoothstep(COS_OUTER, COS_INNER, to.dot(dir) / maxf(dist, 1.0)) * (1.0 - smoothstep(RANGE * 0.5, RANGE, dist))
	var pool := (1.0 - smoothstep(POOL * 0.3, POOL, dist)) * 0.6
	return maxf(cone, pool) * on
