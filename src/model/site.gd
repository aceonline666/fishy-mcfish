class_name Site
extends RefCounted
## One location's beach business: its tank, shop, sellers, drones and the player's gear there.
## Every location starts from scratch; coins, the Fishpedia, charted zones and goals are shared
## (see PlayerState).

var location_id := ""
## Index + 1 into DataRegistry.backpack_levels.
var backpack_level := 1
## Index + 1 into DataRegistry.gear_levels; decides which depth zones are open.
var gear_level := 1
## Index + 1 into DataRegistry.net_levels; better nets land big fish faster.
var net_level := 1
## Index + 1 into DataRegistry.shop_levels: bigger shops have booths for more sellers.
var shop_level := 1
## The fish in the backpack, oldest first. It stays at this location's beach when the player
## travels, and is kept in the save.
var backpack: Array[String] = []
## Sellers working in the shop, at most one per shop level.
var seller_count := 0
var drone_count := 0
## The beach's one tank; upgrades make it bigger.
var tank := TankState.new()
## Coins already paid into build pads, by pad id.
var build_progress: Dictionary[String, float] = {}


## A fresh business: a small tank and a fish stall.
static func create(location: String) -> Site:
	var site := Site.new()
	site.location_id = location
	return site


func location() -> LocationDef:
	return DataRegistry.location(location_id)


## Prices here are the data prices times this.
func price_factor() -> float:
	var def := location()
	return def.price_factor if def != null else 1.0


func to_dict() -> Dictionary:
	return {
		"backpack_level": backpack_level,
		"gear_level": gear_level,
		"net_level": net_level,
		"shop_level": shop_level,
		"seller_count": seller_count,
		"drone_count": drone_count,
		"tank": tank.to_dict(),
		"backpack": backpack.duplicate(),
		"build_progress": build_progress.duplicate(),
	}


## Reads a site; also used for the global fields of saves from before locations had their own
## business. Saves from before a beach had one tank list several "tanks" in slots: they are
## merged into one tank at the highest level. `slot_offset` and `slot_count` pick the slots that
## belong here from saves from before locations had their own business. Older saves counted
## shops ("shop_count"); each shop built becomes a shop level.
static func from_dict(location: String, data: Dictionary, slot_offset: int = 0, slot_count: int = 1 << 30) -> Site:
	var site := Site.new()
	site.location_id = location
	site.backpack_level = maxi(int(data.get("backpack_level", 1)), 1)
	site.gear_level = maxi(int(data.get("gear_level", 1)), 1)
	site.net_level = maxi(int(data.get("net_level", 1)), 1)
	site.shop_level = maxi(int(data.get("shop_level", data.get("shop_count", 1))), 1)
	site.seller_count = clampi(int(data.get("seller_count", 0)), 0, Selling.seller_slots(site))
	site.drone_count = maxi(int(data.get("drone_count", 0)), 0)
	if data.get("tank") is Dictionary:
		site.tank = TankState.from_dict(data["tank"])
	var raw_backpack: Array = data.get("backpack", [])
	for entry: Variant in raw_backpack:
		if entry is String and DataRegistry.species.has(entry):
			site.backpack.append(entry)
	var raw_tanks: Array = data.get("tanks", [])
	for entry: Variant in raw_tanks:
		if not entry is Dictionary:
			continue
		var slot := int(entry.get("slot", 0))
		if slot < slot_offset or slot >= slot_offset + slot_count:
			continue
		var old := TankState.from_dict(entry)
		site.tank.level = maxi(site.tank.level, old.level)
		site.tank.fish.append_array(old.fish)
	var raw_progress: Dictionary = data.get("build_progress", {})
	for key: Variant in raw_progress:
		site.build_progress[str(key)] = float(raw_progress[key])
	return site
