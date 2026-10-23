class_name Economy
extends RefCounted
## Prices and income. A fish's value grows from its base value (juvenile) to
## GROWN_VALUE_MULT times that (adult); visitors pay for what is on display.

const GROWN_VALUE_MULT := 3.0
## Coins per second a displayed fish brings in, per coin of its current value.
const APPEAL_PER_VALUE := 0.01


static func growth_mult(growth: float) -> float:
	return lerpf(1.0, GROWN_VALUE_MULT, clampf(growth, 0.0, 1.0))


static func sale_price(def: SpeciesDef, growth: float = 0.0) -> float:
	return def.base_value * growth_mult(growth)


## Coins per second this fish brings in through visitors.
static func appeal_per_second(def: SpeciesDef, growth: float) -> float:
	return sale_price(def, growth) * APPEAL_PER_VALUE


## Exact income of one fish over `seconds`, starting at `growth`, while it keeps growing
## (linearly until adult). Large offline steps give the same result as many small ones.
static func income_over(def: SpeciesDef, growth: float, seconds: float) -> float:
	var rate_per_growth := def.base_value * APPEAL_PER_VALUE * (GROWN_VALUE_MULT - 1.0)
	var base_rate := def.base_value * APPEAL_PER_VALUE
	var until_adult := maxf((1.0 - growth) * def.growth_time_s, 0.0)
	var growing := minf(seconds, until_adult)
	# While growing, the rate rises linearly; integrate it, then add the adult part.
	var g_end := growth + growing / def.growth_time_s
	var growing_income := growing * (base_rate + rate_per_growth * (growth + g_end) * 0.5)
	var adult_income := (seconds - growing) * base_rate * GROWN_VALUE_MULT
	return growing_income + adult_income
