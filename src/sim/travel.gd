class_name Travel
extends RefCounted
## Which locations are open, and where the player is.


static func current(state: PlayerState) -> LocationDef:
	var def := DataRegistry.location(state.current_location)
	return def if def != null else DataRegistry.home()


static func is_home(state: PlayerState) -> bool:
	return current(state) == DataRegistry.home()


static func is_unlocked(state: PlayerState, def: LocationDef) -> bool:
	return def.unlock.is_empty() or state.unlocked_locations.has(def.id)


## True once the location's goal is reached and the fee is not yet paid.
static func can_unlock(state: PlayerState, def: LocationDef) -> bool:
	return not is_unlocked(state, def) and state.achievements.has(def.unlock)


## The goal that opens the location, or null for home.
static func unlock_goal(def: LocationDef) -> AchievementDef:
	for goal in DataRegistry.achievements:
		if goal.id == def.unlock:
			return goal
	return null
