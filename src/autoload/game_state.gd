extends Node
## Holds the live PlayerState. Scenes read from it; player actions go through its command methods
## so the matching EventBus signals are always emitted.

var state := PlayerState.new()


func replace_state(new_state: PlayerState) -> void:
	state = new_state
	EventBus.state_replaced.emit()
	EventBus.money_changed.emit(state.money)


func add_money(amount: float) -> void:
	state.add_money(amount)
	EventBus.money_changed.emit(state.money)


func try_spend(amount: float) -> bool:
	if not state.try_spend(amount):
		return false
	EventBus.money_changed.emit(state.money)
	return true


## Records a fish entering the net. Returns true the first time a species is ever caught.
func record_catch(species_id: String) -> bool:
	var is_new := state.record_catch(species_id)
	EventBus.fish_caught.emit(species_id, is_new)
	return is_new


func record_best(stat: String, value: int) -> void:
	state.record_best(stat, value)


## What the given fish would sell for.
func catch_value(species_ids: Array[String]) -> float:
	var total := 0.0
	for id in species_ids:
		total += Economy.sale_price(DataRegistry.species[id])
	return total


## Puts a caught fish into the tank.
func store_fish(species_id: String) -> void:
	state.tank_fish.append(species_id)
	EventBus.fish_stored.emit(species_id)
