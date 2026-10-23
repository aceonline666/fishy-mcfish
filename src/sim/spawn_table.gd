class_name SpawnTable
extends RefCounted
## Weighted random choice of species ids for one fishing layer.

var total_weight := 0.0

var _ids: Array[String] = []
var _cumulative := PackedFloat64Array()


func _init(weights: Dictionary[String, float]) -> void:
	for id in weights:
		assert(weights[id] > 0.0, "Spawn weight for '%s' must be positive." % id)
		total_weight += weights[id]
		_ids.append(id)
		_cumulative.append(total_weight)


func pick(rng: RandomNumberGenerator) -> String:
	var roll := rng.randf() * total_weight
	for i in _ids.size():
		if roll < _cumulative[i]:
			return _ids[i]
	return _ids[-1]
