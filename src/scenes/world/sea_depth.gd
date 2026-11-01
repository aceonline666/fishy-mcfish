class_name SeaDepth
extends RefCounted
## How the sea looks with depth (ground y below the waterline): the water and everything seen
## through it fade from the shallow to the deep colour over DEPTH_RANGE, then into the dark of
## the deep sea between ABYSS_START and ABYSS_END. Shared by the water shader, the seabed props
## and the fish. The zones are 4 cells of the layout grid (Grid) deep: the colour has faded by the
## end of the third, the dark starts with the fourth and is darkest near the end of the sixth.

const DEPTH_RANGE := 13 * Grid.UNIT
const ABYSS_START := 12 * Grid.UNIT
const ABYSS_END := 23 * Grid.UNIT


## 0 at the waterline to 1 at DEPTH_RANGE.
static func depth(ground_y: float) -> float:
	return clampf(ground_y / DEPTH_RANGE, 0.0, 1.0)


## 0 above the deep sea to 1 at its darkest.
static func abyss(ground_y: float) -> float:
	return smoothstep(ABYSS_START, ABYSS_END, ground_y)
