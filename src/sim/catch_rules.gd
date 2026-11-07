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
## Ground units. The wader is about 190 px tall; only whales and giant squid get much longer.
const MAX_BODY_LENGTH := 760.0
## Giants cruise rather than dart.
const MAX_CRUISE_SPEED := 280.0
## Drifters and crawlers move slower than their size suggests: share of the usual cruise speed.
const SPEED_FACTORS: Dictionary[String, float] = {
	"moon_jellyfish": 0.3, "lions_mane_jellyfish": 0.3, "blubber_jellyfish": 0.3,
	"nomuras_jellyfish": 0.25, "portuguese_man_o_war": 0.3,
	"japanese_spider_crab": 0.35, "giant_sea_spider": 0.5,
}


## Seconds the net must stay on the fish to catch it. 0 means instant. A better net
## (`net_speed` > 1) lands fish faster.
static func struggle_seconds(def: SpeciesDef, net_speed: float = 1.0) -> float:
	if def.length_cm < INSTANT_BELOW_CM:
		return 0.0
	var size_t := clampf(inverse_lerp(INSTANT_BELOW_CM, MAX_STRUGGLE_AT_CM, def.length_cm), 0.0, 1.0)
	return lerpf(MIN_STRUGGLE_S, MAX_STRUGGLE_S, size_t) * (1.0 + RARITY_STRUGGLE_BONUS * def.rarity) / net_speed


## Body length in ground units. Grows with the square root of the real length, so a cod is
## clearly bigger than a sprat but still fits next to the wader.
static func body_length(def: SpeciesDef) -> float:
	return minf(35.0 + 14.0 * sqrt(def.length_cm), MAX_BODY_LENGTH)


## Ground units per second.
static func cruise_speed(def: SpeciesDef) -> float:
	var speed := minf((70.0 + body_length(def) * 0.5) * (1.0 + RARITY_SPEED_BONUS * def.rarity), MAX_CRUISE_SPEED)
	return speed * SPEED_FACTORS.get(def.id, 1.0)


## Small fish arrive in schools, bigger ones alone.
static func school_size(def: SpeciesDef, rng: RandomNumberGenerator) -> int:
	return rng.randi_range(3, 5) if def.length_cm < SCHOOLING_BELOW_CM else 1


## Name shown when several fish are caught in quick succession. Empty for a single fish.
static func combo_name(count: int) -> String:
	match count:
		0, 1:
			return ""
		2:
			return Lang.text("Double!")
		3:
			return Lang.text("Triple!")
		4:
			return Lang.text("Quad!")
	return Lang.text("Mega haul!")
