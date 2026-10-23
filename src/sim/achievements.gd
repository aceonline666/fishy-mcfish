class_name Achievements
extends RefCounted
## Measures progress towards goals and finds the ones just reached.


## Current value of what the goal measures.
static func progress(state: PlayerState, def: AchievementDef) -> float:
	match def.type:
		"catch_count":
			return state.stats.get("fish_caught", 0)
		"best_combo":
			return state.stats.get("best_combo", 0)
		"tank_count":
			return state.tanks.size()
		"species_count":
			return state.species_caught.size()
		"charted":
			for zone in DataRegistry.zones:
				if zone.id == def.param:
					return 1.0 if Charting.is_charted(state, zone) else 0.0
			return 0.0
		"rarity_caught":
			var rarity: int = SpeciesDef.Rarity.get(def.param.to_upper(), -1)
			var count := 0
			for id in state.species_caught:
				if DataRegistry.species.has(id) and DataRegistry.species[id].rarity >= rarity:
					count += state.species_caught[id]
			return count
		"drone_count":
			return state.drone_count
		"seller_count":
			return state.seller_count
		"shop_count":
			return state.shop_count
		"total_earned":
			return state.total_earned
	return 0.0


static func is_reached(state: PlayerState, def: AchievementDef) -> bool:
	return progress(state, def) >= def.target


## Goals reached but not yet recorded in the state.
static func newly_reached(state: PlayerState) -> Array[AchievementDef]:
	var reached: Array[AchievementDef] = []
	for def in DataRegistry.achievements:
		if not state.achievements.has(def.id) and is_reached(state, def):
			reached.append(def)
	return reached
