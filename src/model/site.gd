class_name Site
extends RefCounted
## One location's beach business: its tanks, shops, sellers, drones and the player's gear there.
## Every location starts from scratch; coins, the Fishpedia, charted zones and goals are shared
## (see PlayerState).

var location_id := ""
## Index + 1 into DataRegistry.backpack_levels.
var backpack_level := 1
## Index + 1 into DataRegistry.gear_levels; decides which depth zones are open.
var gear_level := 1
## Index + 1 into DataRegistry.net_levels; better nets land big fish faster.
var net_level := 1
## Shops built on the beach (the first is free) and sellers hired to work in them.
var shop_count := 1
var seller_count := 0
var drone_count := 0
## Built tanks, ordered by slot.
var tanks: Array[TankState] = []
## Coins already paid into build pads, by pad id.
var build_progress: Dictionary[String, float] = {}


## A fresh business: one small tank and the first shop.
static func create(location: String) -> Site:
	var site := Site.new()
	site.location_id = location
	site.tanks.append(TankState.new(0, 1))
	return site


func location() -> LocationDef:
	return DataRegistry.location(location_id)


## Prices here are the data prices times this.
func price_factor() -> float:
	var def := location()
	return def.price_factor if def != null else 1.0


func tank_in_slot(slot: int) -> TankState:
	for tank in tanks:
		if tank.slot == slot:
			return tank
	return null


func to_dict() -> Dictionary:
	var tank_data: Array[Dictionary] = []
	for tank in tanks:
		tank_data.append(tank.to_dict())
	return {
		"backpack_level": backpack_level,
		"gear_level": gear_level,
		"net_level": net_level,
		"shop_count": shop_count,
		"seller_count": seller_count,
		"drone_count": drone_count,
		"tanks": tank_data,
		"build_progress": build_progress.duplicate(),
	}


## Reads a site; also used for the global fields of saves from before locations had their own
## business. `slot_offset` and `slot_count` pick the tanks that belong here from such saves.
static func from_dict(location: String, data: Dictionary, slot_offset: int = 0, slot_count: int = 1 << 30) -> Site:
	var site := Site.new()
	site.location_id = location
	site.backpack_level = maxi(int(data.get("backpack_level", 1)), 1)
	site.gear_level = maxi(int(data.get("gear_level", 1)), 1)
	site.net_level = maxi(int(data.get("net_level", 1)), 1)
	site.shop_count = maxi(int(data.get("shop_count", 1)), 1)
	site.seller_count = maxi(int(data.get("seller_count", 0)), 0)
	site.drone_count = maxi(int(data.get("drone_count", 0)), 0)
	var raw_tanks: Array = data.get("tanks", [])
	for entry: Variant in raw_tanks:
		if not entry is Dictionary:
			continue
		var tank := TankState.from_dict(entry)
		if tank.slot >= slot_offset and tank.slot < slot_offset + slot_count:
			tank.slot -= slot_offset
			site.tanks.append(tank)
	if site.tanks.is_empty():
		site.tanks.append(TankState.new(0, 1))
	site.tanks.sort_custom(func(a: TankState, b: TankState) -> bool: return a.slot < b.slot)
	var raw_progress: Dictionary = data.get("build_progress", {})
	for key: Variant in raw_progress:
		site.build_progress[str(key)] = float(raw_progress[key])
	return site
