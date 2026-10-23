class_name LiveWell
extends RefCounted
## The boat's tank holding the catch of the current trip.

var capacity: int
var species_ids: Array[String] = []


func _init(tank_capacity: int) -> void:
	capacity = tank_capacity


func count() -> int:
	return species_ids.size()


func free_space() -> int:
	return capacity - species_ids.size()


func is_full() -> bool:
	return free_space() <= 0


func add(species_id: String) -> bool:
	if is_full():
		return false
	species_ids.append(species_id)
	return true


## Empties the live-well and returns everything that was in it.
func take_all() -> Array[String]:
	var taken: Array[String] = species_ids.duplicate()
	species_ids.clear()
	return taken
