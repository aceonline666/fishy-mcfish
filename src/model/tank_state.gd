class_name TankState
extends RefCounted
## The tank of a beach business; upgrades make it bigger.

## Index + 1 into DataRegistry.tank_levels.
var level := 1
var fish: Array[TankFish] = []
## Progress of each species towards its next young (Aquarium.breed); not saved.
var breeding: Dictionary[String, float] = {}


func _init(tank_level: int = 1) -> void:
	level = tank_level


func to_dict() -> Dictionary:
	var fish_data: Array[Dictionary] = []
	for f in fish:
		fish_data.append(f.to_dict())
	return {"level": level, "fish": fish_data}


static func from_dict(data: Dictionary) -> TankState:
	var tank := TankState.new(maxi(int(data.get("level", 1)), 1))
	var raw_fish: Array = data.get("fish", [])
	for entry: Variant in raw_fish:
		if entry is Dictionary:
			tank.fish.append(TankFish.from_dict(entry))
	return tank
