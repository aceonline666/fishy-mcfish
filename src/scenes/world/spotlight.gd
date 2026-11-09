class_name Spotlight
extends RefCounted
## The submarine's spotlight, for what is lit as a whole (a fish or a seabed prop takes the light
## at its ground point): the same cone and pool as src/shaders/spotlight.gdshaderinc, which lights
## the water and the seabed per pixel. Keep the two in step. The cone's tip lies BACK behind the
## sub and its near end fades in over FADE_IN (from the sub), so it has no sharp point; the
## headlamp's beam (Wader) leads down into it.

const RANGE := 1050.0
const COS_INNER := 0.95
const COS_OUTER := 0.74
const POOL := 260.0
const BACK := 150.0
const FADE_IN := Vector2(60.0, 420.0)
## Lit, the water's tint lifts by this share and the deep sea's dark by DARK_LIFT (as in the
## shaders).
const DEPTH_LIFT := 0.6
const DARK_LIFT := 0.85


## 0 to 1, how brightly ground point `ground` is lit by a light at `origin` pointing along `dir`
## (a unit vector), switched on by `on` (0 to 1).
static func amount(ground: Vector2, origin: Vector2, dir: Vector2, on: float) -> float:
	if on <= 0.0:
		return 0.0
	var to := ground - (origin - dir * BACK)
	var dist := to.length()
	var along := to.dot(dir)
	var cone := smoothstep(COS_OUTER, COS_INNER, along / maxf(dist, 1.0)) * (1.0 - smoothstep(RANGE * 0.5, RANGE, dist)) 			* smoothstep(BACK + FADE_IN.x, BACK + FADE_IN.y, along)
	var pool := (1.0 - smoothstep(0.0, POOL, ground.distance_to(origin))) * 0.45
	return maxf(cone, pool) * on
