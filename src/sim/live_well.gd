class_name LiveWell
extends RefCounted
## What the player carries on the current trip: the wader's backpack at shallow spots,
## the boat's live-well at deeper layers later.

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


## Removes and returns the most recently added fish.
func take_last() -> String:
	return species_ids.pop_back()


## Removes and returns the fish at `index` (0 = oldest).
func take_at(index: int) -> String:
	var id := species_ids[index]
	species_ids.remove_at(index)
	return id


## Empties the live-well and returns everything that was in it.
func take_all() -> Array[String]:
	var taken: Array[String] = species_ids.duplicate()
	species_ids.clear()
	return taken
