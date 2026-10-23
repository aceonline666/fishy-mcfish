class_name CatchRules
extends RefCounted
## Catch tuning derived from species data, so new species need no extra CSV columns.

## Fish shorter than this are scooped instantly; longer ones struggle in the net.
const INSTANT_BELOW_CM := 25.0
const MIN_STRUGGLE_S := 0.3
const MAX_STRUGGLE_S := 2.0
const MAX_STRUGGLE_AT_CM := 150.0
## Extra struggle time per rarity tier.
const RARITY_STRUGGLE_BONUS := 0.15
## Extra swim speed per rarity tier.
const RARITY_SPEED_BONUS := 0.12
const SCHOOLING_BELOW_CM := 25.0
const MAX_BODY_PX := 640.0

const COMBO_NAMES: Array[String] = ["", "", "Double!", "Triple!", "Quad!"]
const MEGA_COMBO_NAME := "Mega haul!"


## Seconds the net must stay on the fish to catch it. 0 means instant.
static func struggle_seconds(def: SpeciesDef) -> float:
	if def.length_cm < INSTANT_BELOW_CM:
		return 0.0
	var size_t := clampf(inverse_lerp(INSTANT_BELOW_CM, MAX_STRUGGLE_AT_CM, def.length_cm), 0.0, 1.0)
	return lerpf(MIN_STRUGGLE_S, MAX_STRUGGLE_S, size_t) * (1.0 + RARITY_STRUGGLE_BONUS * def.rarity)


## On-screen body length in pixels (viewport is 1080 wide).
static func body_length_px(def: SpeciesDef) -> float:
	return minf(60.0 + def.length_cm * 6.0, MAX_BODY_PX)


static func cruise_speed(def: SpeciesDef) -> float:
	return (80.0 + body_length_px(def) * 0.4) * (1.0 + RARITY_SPEED_BONUS * def.rarity)


## Small fish arrive in schools, bigger ones alone.
static func school_size(def: SpeciesDef, rng: RandomNumberGenerator) -> int:
	return rng.randi_range(3, 5) if def.length_cm < SCHOOLING_BELOW_CM else 1


## Name shown when several fish are landed in one drag. Empty for a single fish.
static func combo_name(count: int) -> String:
	if count < COMBO_NAMES.size():
		return COMBO_NAMES[count]
	return MEGA_COMBO_NAME
