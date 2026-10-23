class_name TankFish
extends RefCounted
## One fish living in a tank. Grows from juvenile (0) to adult (1).

var species_id: String
var growth := 0.0


func _init(id: String = "", start_growth: float = 0.0) -> void:
	species_id = id
	growth = start_growth


func to_dict() -> Dictionary:
	return {"species": species_id, "growth": growth}


static func from_dict(data: Dictionary) -> TankFish:
	return TankFish.new(str(data.get("species", "")), clampf(float(data.get("growth", 0.0)), 0.0, 1.0))
