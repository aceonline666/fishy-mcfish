class_name Curiosities
extends RefCounted
## Rare finds, kept on the curiosities page of the Fishpedia. Every location has a message in a
## bottle: it washes into the shallows once the location's first zone is charted, and read in the
## order of the locations, the seven letters tell what became of the wader's father, lost at sea.
## Five locations also hide a curiosity on the seabed of their second zone, there once that zone
## is charted. One find of a location shows at a time, the bottle first; the net picks it up like
## the treasure chest. Not shown during the tutorial.

enum Kind { BOTTLE, ITEM }

## The finds of each location, in the order they turn up: find id, sprite and the zone (order)
## it lies in.
const FINDS: Dictionary[String, Array] = {
	"north_sea": [["bottle_north_sea", "message_in_a_bottle", 1], ["ships_bell", "ships_bell", 2]],
	"coral_reef": [["bottle_coral_reef", "message_in_a_bottle", 1], ["pirate_coin", "pirate_coin", 2]],
	"australia": [["bottle_australia", "message_in_a_bottle", 1], ["sea_glass", "sea_glass", 2]],
	"japan": [["bottle_japan", "message_in_a_bottle", 1], ["rubber_duck", "rubber_duck", 2]],
	"south_africa": [["bottle_south_africa", "message_in_a_bottle", 1], ["old_compass", "old_compass", 2]],
	"antarctica": [["bottle_antarctica", "message_in_a_bottle", 1]],
	"jurassic_sea": [["bottle_jurassic_sea", "message_in_a_bottle", 1]],
}
const SPRITE_DIR := "res://assets/sprites/props/"
## A find keeps this far from its zone's edges (ground units).
const EDGE_MARGIN := 200.0

## Names and descriptions of the items; the bottles are all "Message in a bottle".
const ITEM_NAMES: Dictionary[String, String] = {
	"ships_bell": "Ship's bell",
	"pirate_coin": "Pirate coin",
	"sea_glass": "Sea glass",
	"rubber_duck": "Rubber duck",
	"old_compass": "Old compass",
}
const ITEM_TEXTS: Dictionary[String, String] = {
	"ships_bell": "A ship's bell, green with age and crusted with barnacles. Somewhere out there lies the ship it once rang for.",
	"pirate_coin": "A worn gold doubloon with a cross stamped on it. Pirates sailed these waters, and not all of their gold made it home.",
	"sea_glass": "Smooth, frosted pieces of glass in green, blue and white, rolled round by the waves for many years.",
	"rubber_duck": "A faded rubber duck, scuffed from a long journey. Lost bath toys drift across whole oceans with the currents.",
	"old_compass": "A brass pocket compass with its lid open. The needle still points north, steady as ever.",
}
## The letters, by location, in the order of the locations.
const LETTERS: Dictionary[String, String] = {
	"north_sea": "To whoever finds this: please bring it to my family, at the little beach with the pier.\n\nThe storm took my boat. I held on to a crate for two days and nights, and the current carried me away.\n\nI am alive. Tell my kid I am sorry I missed the summer.\n\n- Dad",
	"coral_reef": "My dear,\n\nthe sea washed me up on an island no map knows. Palm trees, warm water and fish so bright they look painted.\n\nI catch them with my hands, the way I showed you on the pier. I think of you every time.\n\n- Dad",
	"australia": "My dear,\n\nthree years now. I count the days with notches in my hut's door post.\n\nA big old turtle visits the bay every spring. I talk to her about you.\n\nI throw a bottle into every current I find. One of them has to reach you.\n\n- Dad",
	"japan": "My dear,\n\nI built a raft and sailed for four days. The sea brought me back to the island, as if it wanted me to stay.\n\nDo you still have my old net? Use it well. You were always better with it than you thought.\n\n- Dad",
	"south_africa": "My dear,\n\nlast night I saw the lights of a ship far out. I lit every fire I could, but it sailed on.\n\nI keep a fire burning now, every night.\n\nIf you are reading this, you have gone further out to sea than I ever did. I am so proud of you.\n\n- Dad",
	"antarctica": "My dear,\n\nthe island is wrapped in fog all year. Once a year it lifts.\n\nLast night it did, and the sea beyond it was wrong: no lights on the horizon, no ships, no planes. Only huge shadows moving in the water, and the stars in places I did not know.\n\n- Dad",
	"jurassic_sea": "My dear,\n\nI know now. It is not where I am, it is when.\n\nThe fog is a door. The creatures in the bay are the ones from your dinosaur books, and they are very much alive.\n\nIf this bottle reached you, you have found the door too. Follow the fog. I will keep the fire burning.\n\n- Dad",
}


## Every find of every location, in the order of the locations.
static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for location in DataRegistry.locations:
		for find: Array in FINDS.get(location.id, []):
			ids.append(find[0])
	return ids


static func is_bottle(find_id: String) -> bool:
	return find_id.begins_with("bottle_")


## The location a find belongs to, or "".
static func location_of(find_id: String) -> String:
	for location_id in FINDS:
		for find: Array in FINDS[location_id]:
			if find[0] == find_id:
				return location_id
	return ""


static func _entry(find_id: String) -> Array:
	for find: Array in FINDS.get(location_of(find_id), []):
		if find[0] == find_id:
			return find
	return []


static func texture(find_id: String) -> Texture2D:
	return load(SPRITE_DIR + str(_entry(find_id)[1]) + ".png")


## The find's name in English (translate with tr()).
static func find_name(find_id: String) -> String:
	return "Message in a bottle" if is_bottle(find_id) else ITEM_NAMES[find_id]


## The letter in the bottle, or the item's description, in English (translate with tr()).
static func text(find_id: String) -> String:
	return LETTERS[location_of(find_id)] if is_bottle(find_id) else ITEM_TEXTS[find_id]


## The zone a find lies in.
static func zone(find_id: String) -> ZoneDef:
	var location_id := location_of(find_id)
	for candidate in DataRegistry.zones_in(location_id):
		if candidate.order == int(_entry(find_id)[2]):
			return candidate
	return null


## The find of the location waiting in the water now: the first one not found yet whose zone is
## charted; "" if none (or during the tutorial).
static func waiting(state: PlayerState, location_id: String) -> String:
	if not Tutorial.is_done(state):
		return ""
	for find: Array in FINDS.get(location_id, []):
		if state.curiosities.has(find[0]):
			continue
		var find_zone := zone(find[0])
		return find[0] if find_zone != null and Charting.is_charted(state, find_zone) else ""
	return ""


## Where the find lies in its zone's area: always the same spot.
static func spot(find_id: String, area: PlayArea) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(find_id)
	return area.random_point(rng, EDGE_MARGIN)


static func record_find(state: PlayerState, find_id: String) -> void:
	if not state.curiosities.has(find_id):
		state.curiosities.append(find_id)
