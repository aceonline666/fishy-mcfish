class_name TankState
extends RefCounted
## A tank built in one of the beach slots.

var slot: int
## Index + 1 into DataRegistry.tank_levels.
var level := 1
var fish: Array[TankFish] = []


func _init(slot_index: int = 0, tank_level: int = 1) -> void:
	slot = slot_index
	level = tank_level


func to_dict() -> Dictionary:
	var fish_data: Array[Dictionary] = []
	for f in fish:
		fish_data.append(f.to_dict())
	return {"slot": slot, "level": level, "fish": fish_data}


static func from_dict(data: Dictionary) -> TankState:
	var tank := TankState.new(int(data.get("slot", 0)), maxi(int(data.get("level", 1)), 1))
	var raw_fish: Array = data.get("fish", [])
	for entry: Variant in raw_fish:
		if entry is Dictionary:
			tank.fish.append(TankFish.from_dict(entry))
	return tank
