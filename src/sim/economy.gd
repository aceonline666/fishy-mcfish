class_name Economy
extends RefCounted
## Prices. A fish's value grows from its base value (juvenile) to GROWN_VALUE_MULT times that
## (adult) while it lives in a tank.

const GROWN_VALUE_MULT := 3.0


static func growth_mult(growth: float) -> float:
	return lerpf(1.0, GROWN_VALUE_MULT, clampf(growth, 0.0, 1.0))


static func sale_price(def: SpeciesDef, growth: float = 0.0) -> float:
	return def.base_value * growth_mult(growth)
