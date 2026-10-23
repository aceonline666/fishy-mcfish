class_name PlayerState
extends RefCounted
## Everything about a player's progress that gets saved. Pure data: no nodes, no signals.
## Coins, the Fishpedia, charted zones and goals are shared; each location has its own beach
## business (a Site). Use new_game() for a fresh start; PlayerState.new() is completely empty.

## Tank slots per location in saves from before each location had its own business: four
## temperate slots at home, then four tropical ones (now the Coral Reef's).
const LEGACY_SLOTS_PER_LOCATION := 4
const LEGACY_TROPICAL_LOCATION := "coral_reef"

var money := 0.0
## Lifetime earnings. Used later to pick the "most progressed" save on cloud conflicts.
var total_earned := 0.0
var stats: Dictionary[String, int] = {}
## How many of each species the player has ever caught. Feeds the Fishpedia.
var species_caught: Dictionary[String, int] = {}
## Fish caught per depth zone id, for charting.
var zone_catches: Dictionary[String, int] = {}
## Where the player is fishing; empty means home.
var current_location := ""
## Locations opened by paying their travel fee.
var unlocked_locations: Array[String] = []
## Ids of the goals reached (and paid out).
var achievements: Array[String] = []
## The beach business of each location visited, by location id.
var sites: Dictionary[String, Site] = {}


static func new_game() -> PlayerState:
	var state := PlayerState.new()
	state.site(DataRegistry.home().id)
	return state


## The business at a location, started from scratch on the first visit.
func site(location_id: String) -> Site:
	if not sites.has(location_id):
		sites[location_id] = Site.create(location_id)
	return sites[location_id]


## The business where the player is.
func here() -> Site:
	return site(current_location if not current_location.is_empty() else DataRegistry.home().id)


func add_money(amount: float) -> void:
	assert(amount >= 0.0, "Use try_spend to remove money.")
	money += amount
	total_earned += amount


func try_spend(amount: float) -> bool:
	if amount < 0.0 or amount > money:
		return false
	money -= amount
	return true


func increment_stat(key: String, by: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + by


## Keeps the highest value seen for a stat, e.g. the best combo.
func record_best(key: String, value: int) -> void:
	if value > int(stats.get(key, 0)):
		stats[key] = value


## Returns true if this is the first catch of the species.
func record_catch(species_id: String, zone_id: String = "") -> bool:
	var is_new := not species_caught.has(species_id)
	species_caught[species_id] = int(species_caught.get(species_id, 0)) + 1
	if not zone_id.is_empty():
		zone_catches[zone_id] = int(zone_catches.get(zone_id, 0)) + 1
	increment_stat("fish_caught")
	return is_new


## Sum of an integer site field (e.g. "drone_count") over all locations.
func total(field: String) -> int:
	var sum := 0
	for s: Site in sites.values():
		sum += int(s.get(field))
	return sum


## The highest value of an integer site field (e.g. "shop_count") at any one location.
func most(field: String) -> int:
	var best := 0
	for s: Site in sites.values():
		best = maxi(best, int(s.get(field)))
	return best


## The most tanks built at any one location.
func most_tanks() -> int:
	var best := 0
	for s: Site in sites.values():
		best = maxi(best, s.tanks.size())
	return best


func to_dict() -> Dictionary:
	var site_data := {}
	for id in sites:
		site_data[id] = sites[id].to_dict()
	return {
		"money": money,
		"total_earned": total_earned,
		"stats": stats.duplicate(),
		"species_caught": species_caught.duplicate(),
		"zone_catches": zone_catches.duplicate(),
		"achievements": achievements.duplicate(),
		"current_location": current_location,
		"unlocked_locations": unlocked_locations.duplicate(),
		"sites": site_data,
	}


static func from_dict(data: Dictionary) -> PlayerState:
	var state := PlayerState.new()
	state.money = float(data.get("money", 0.0))
	state.total_earned = float(data.get("total_earned", 0.0))
	# JSON turns ints into floats, so convert back.
	var raw_stats: Dictionary = data.get("stats", {})
	for key: Variant in raw_stats:
		state.stats[str(key)] = int(raw_stats[key])
	var raw_caught: Dictionary = data.get("species_caught", {})
	for key: Variant in raw_caught:
		state.species_caught[str(key)] = int(raw_caught[key])
	var raw_achievements: Array = data.get("achievements", [])
	for id: Variant in raw_achievements:
		state.achievements.append(str(id))
	state.current_location = str(data.get("current_location", ""))
	var raw_locations: Array = data.get("unlocked_locations", [])
	for id: Variant in raw_locations:
		state.unlocked_locations.append(str(id))
	var raw_zones: Dictionary = data.get("zone_catches", {})
	for key: Variant in raw_zones:
		state.zone_catches[str(key)] = int(raw_zones[key])

	var raw_sites: Variant = data.get("sites")
	if raw_sites is Dictionary:
		for id: Variant in raw_sites:
			if raw_sites[id] is Dictionary:
				state.sites[str(id)] = Site.from_dict(str(id), raw_sites[id])
	else:
		_read_legacy_business(state, data)
	state.site(DataRegistry.home().id)
	return state


## Saves from before each location had its own business kept it in global fields: it all
## becomes the home business, except the tropical tanks, which move to the Coral Reef.
static func _read_legacy_business(state: PlayerState, data: Dictionary) -> void:
	var home := Site.from_dict(DataRegistry.home().id, data, 0, LEGACY_SLOTS_PER_LOCATION)
	home.build_progress.erase("build_tropical_tank")
	state.sites[home.location_id] = home
	# Saves from before the shops had visitors, a cash pile and a cashier: keep the coins and
	# turn the cashier into the first seller.
	state.money += float(data.get("cash_pile", 0.0)) + float(data.get("pending_income", 0.0))
	if bool(data.get("has_cashier", false)):
		home.seller_count = maxi(home.seller_count, 1)
	# Early prototype saves kept stored fish as a flat list; move them into the first tank.
	var legacy_tank: Array = data.get("tank_fish", [])
	for id: Variant in legacy_tank:
		home.tanks[0].fish.append(TankFish.new(str(id)))

	var tropical_tanks: Array = (data.get("tanks", []) as Array).filter(func(entry: Variant) -> bool:
		return entry is Dictionary and int(entry.get("slot", 0)) >= LEGACY_SLOTS_PER_LOCATION)
	if not tropical_tanks.is_empty():
		state.sites[LEGACY_TROPICAL_LOCATION] = Site.from_dict(LEGACY_TROPICAL_LOCATION,
				{"tanks": tropical_tanks}, LEGACY_SLOTS_PER_LOCATION, LEGACY_SLOTS_PER_LOCATION)
