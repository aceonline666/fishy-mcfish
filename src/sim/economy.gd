class_name Economy
extends RefCounted
## Prices and costs. M2 adds growth-based sale prices and upgrade cost curves.


static func sale_price(def: SpeciesDef) -> float:
	return def.base_value
