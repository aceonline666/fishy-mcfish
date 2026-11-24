"""Writes the prompts for the species views into art_source/fish/views/prompts.md: one image per
species, the creature seen from the side, head left, in the style of the cod in
art_source/fish/species_style_side.png (the game draws every creature side-on).
The species, their order and their descriptions live in CREATURES below; edit them there and run
again:

    python tools/make_species_view_prompts.py

Cut each image with tools/extract_species_views.py.
"""
import csv
import math
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art_source", "fish", "views")
REFERENCE = "art_source/fish/species_style_side.png"

# How each kind of creature is drawn (added to its description).
KIND = {
    "fish": "",
    "eel": "",
    "shark": "",
    # Rays and flatfish: the game shows them gliding along, seen from the side and a little above.
    "flat": " Seen from the side and a little from above (a three-quarter view), gliding to the left, so its flat shape shows.",
    "ceph": " It swims to the left, mantle first: the mantle at the left, the eyes behind it, and the arms trailing straight back to the right in a loose, slightly spread bundle (so the arms can be animated): no arm curls back over or under the body, the arms do not cross each other or the mantle, and they form no closed loops; arms and tentacles only at that one end.",
    # The game does not beat a tail for jellyfish: it squeezes the bell around its middle and
    # sways the tentacles below it (FishArt's jelly pulse), so they are drawn straight upright.
    "jelly": " A jellyfish does not swim head first like a fish and has no tail: it is painted straight along a vertical line, upright and symmetric: the bell (or float) at the top, centred on that line, and the tentacles below it, hanging down along the same line, a little tangled, spreading out slightly towards the bottom (not trailing to one side, not diagonal, none curling back up over the bell), so the game can squeeze the bell and sway the tentacles. A jellyfish has no eyes and no face: draw no eyes, no mouth and no smile on it (the big friendly eyes of the style are only for animals that have eyes).",
    "octopus": " An octopus has no fins and no face at the front: it swims to the left, mantle first, like a jet: the rounded, bag-like mantle (no eyes, no mouth on it) leads at the left, the head with the two eyes sits behind it on the right where the arms begin, and the eight arms, a row of pale suckers along each, trail straight back to the right in a loose, slightly spread bundle (so the arms can be animated): no arm curls back over or under the body, the arms do not cross each other or the mantle, and they form no closed loops. It must not look like a fish.",
    "crust": " It walks to the left on its legs.",
    "upright": " It swims upright, snout pointing left.",
    "big": "",
}

# id: (kind, description). Names and scientific names come from data/species.csv; the sheet 14
# species (not in the game yet) carry their names here.
CREATURES = [
    # Ordinary fish
    ("european_sprat", "fish", "small, slim, silvery with a blue-green back and a forked tail"),
    ("atlantic_herring", "fish", "slim, silvery with a blue-green back, a single dorsal fin and a forked tail"),
    ("atlantic_mackerel", "fish", "streamlined, a green-blue back with black wavy stripes, silver sides, small finlets before the forked tail"),
    ("lumpsucker", "fish", "round and lumpy like a ball, grey-green with three rows of bony bumps along its side, a high rounded hump on its back, a small mouth, small round pectoral fins and a short rounded tail fin"),
    ("atlantic_cod", "fish", "olive-brown back with dark spots, pale lateral line, a chin barbel, three dorsal fins (exactly as in the reference image)"),
    ("atlantic_wolffish", "fish", "long and heavy, blue-grey with dark bands, a big blunt head with strong teeth, one long dorsal fin"),
    ("roundnose_grenadier", "fish", "a big head with a rounded snout and big eyes, the body tapering into a long rat-like tail, grey-brown"),
    ("rabbit_fish", "fish", "a chimaera: a big head with huge green eyes, large wing-like pectoral fins, a tall spine on the first dorsal fin, a long whip tail, bronze with white spots"),
    ("ocellaris_clownfish", "fish", "small, bright orange with three white bands edged in black"),
    ("blue_green_chromis", "fish", "small, iridescent blue-green, a forked tail"),
    ("blue_tang", "fish", "a surgeonfish, not slim: a deep, flat, almost disc-shaped oval body (nearly as tall as it is long without the tail), a steep rounded forehead, a small pointed mouth, a big eye, royal blue with a black palette pattern, black edges on the long dorsal and anal fins, a yellow pectoral fin and a yellow tail"),
    ("mandarinfish", "fish", "tiny, a dragonet, not a goby: a broad, blunt, rounded head with big bulging eyes set high on top of it (they bulge out above the head outline), a small mouth, a short stout body, orange and electric blue wavy patterns, a green-yellow tint on the head, big fan-like blue pectoral and pelvic fins with orange edges"),
    ("red_lionfish", "fish", "red and white stripes, long fan-like pectoral fins and long venomous spines spread around it"),
    ("humphead_wrasse", "fish", "huge, green-blue, a big hump on the forehead, thick lips, fine wavy lines on the face"),
    ("atlantic_bluefin_tuna", "fish", "big and torpedo-shaped, a dark blue back, silver belly, yellow finlets, a sickle-shaped tail"),
    ("yellowfin_tuna", "fish", "torpedo-shaped, dark blue back, a yellow side stripe, long yellow second dorsal and anal fins"),
    ("humpback_anglerfish", "fish", "a small black deep-sea fish, a huge mouth full of needle teeth, a glowing lure on a rod over its head"),
    ("atlantic_footballfish", "fish", "round like a ball, dark brown with bony plates, a lure with glowing tassels on its head"),
    ("skinnycheek_lanternfish", "fish", "tiny, dark with big eyes and rows of glowing blue light dots along the belly"),
    ("west_indian_ocean_coelacanth", "fish", "steel blue with white blotches, thick scales, fleshy lobed fins like little legs, a three-lobed tail"),
    ("australian_salmon", "fish", "streamlined, a green-blue back with dark spots, silver sides, a forked tail"),
    ("blue_groper", "fish", "a big wrasse, bright blue, thick lips, a rounded tail"),
    ("old_wife", "fish", "a tall, flat, silver-white body with bold black diagonal bands, a tall spiny dorsal fin"),
    ("orange_roughy", "fish", "deep-bodied, bright orange-red, a big bony head with big eyes"),
    ("blobfish", "fish", "swimming level to the left in a plain side view, its face in profile (not turned towards the viewer): a soft, droopy pink body, a big sad face with a fleshy nose, a small tail (alive in the deep sea, a little less droopy)"),
    ("common_fangtooth", "fish", "small and dark, a huge head with enormous fang teeth, small eyes"),
    ("red_sea_bream", "fish", "a tall oval body, pink-red with tiny blue spots, a forked tail"),
    ("japanese_horse_mackerel", "fish", "slim, silvery green-blue, a row of bony scutes along the side, a forked tail"),
    ("tiger_puffer", "fish", "a round fugu, grey-brown back with a big black spot ringed in white behind each pectoral fin, a white belly"),
    ("japanese_amberjack", "fish", "streamlined, blue-green back, a yellow stripe along the side, silver belly, a forked yellow tail"),
    ("opah", "fish", "a round disc-shaped fish, red-pink with white spots, bright red fins"),
    ("mariana_snailfish", "fish", "small, soft, pale pink and almost see-through, a tadpole shape with a big head"),
    ("hottentot_seabream", "fish", "an oval bronze-grey seabream with a blunt head and a forked tail"),
    ("south_african_sardine", "fish", "small, slim, silvery with a blue back and a row of dark spots along the side"),
    ("galjoen", "fish", "an oval body, dark bronze-black with faint bands, a small mouth, a spiny dorsal fin"),
    ("cape_hake", "fish", "slim, silver-grey with a long head, big eyes, a long second dorsal fin"),
    ("sloanes_viperfish", "fish", "a slim black deep-sea fish, huge needle fangs sticking out of its mouth, glowing dots along the belly"),
    ("great_barracuda", "fish", "long and slim, silver-grey with dark bars, a long pointed jaw full of sharp teeth"),
    ("crocodile_icefish", "fish", "pale and almost see-through, a long flat crocodile-like snout, large fins"),
    ("antarctic_toothfish", "fish", "large and heavy, dark grey-brown, a big head with a wide mouth, two dorsal fins"),
    ("leedsichthys", "fish", "Jurassic giant filter feeder: an enormous, long, grey-brown fish with a huge wide gaping mouth, long pectoral fins and a big forked tail"),
    ("antarctic_silverfish", "fish", "Antarctic silverfish (Pleuragramma antarctica): small, slim, silvery, almost see-through, a big eye, a forked tail"),
    ("emerald_rockcod", "fish", "Emerald rockcod (Trematomus bernacchii): stocky, mottled green-brown with dark bands, a big head, wide pectoral fins"),
    ("bald_notothen", "fish", "Bald notothen (Pagothenia borchgrevinki): slim, silvery-grey with dark spots, a pointed head, a long second dorsal fin"),
    ("mackerel_icefish", "fish", "Mackerel icefish (Champsocephalus gunnari): long, pale see-through grey-white with dark bands on the back, a long flat snout"),
    ("marbled_rockcod", "fish", "Marbled rockcod (Notothenia rossii): heavy, a big head, olive-brown with darker marbled patches"),
    ("antarctic_jonasfish", "fish", "Antarctic jonasfish (Neopagetopsis ionah): a large pale icefish with a long duck-billed snout, faint dark bands, a tall spiny first dorsal fin"),
    ("leptolepis", "fish", "Leptolepis (Leptolepis coryphaenoides), Jurassic: small, slender, herring-like, silver with thin round scales"),
    ("dapedium", "fish", "Dapedium (Dapedium politum), Jurassic: a deep, almost round body covered in thick shiny diamond-shaped bronze scales, a small mouth"),
    ("pachycormus", "fish", "Pachycormus (Pachycormus macropterus), Jurassic: streamlined and tuna-like, blue-grey, long sickle-shaped pectoral fins, a pointed snout"),
    ("lepidotes", "fish", "Lepidotes (Lepidotes elvensis), Jurassic: large and thick-bodied, heavy shiny square enamel scales, olive-bronze, a blunt head"),
    # Eels and long fish
    ("lesser_sand_eel", "eel", "a thin silvery eel-like fish with a pointed lower jaw"),
    ("conger_eel", "eel", "a big grey-black eel with a long dorsal fin running down the whole back, a thick head"),
    ("pink_ling", "eel", "an eel-like fish, pink-orange with brown mottling, a long fin around the tail"),
    ("kingklip", "eel", "an eel-like fish, pinkish with brown blotches, a long fin around the tail, a chin barbel-like feeler"),
    ("pacific_blackdragon", "eel", "a long, thin black deep-sea fish with fangs, a long chin barbel with a glowing tip"),
    ("giant_oarfish", "eel", "a very long ribbon-like silver fish with a red crest on its head and a red fin running along the whole back"),
    ("pelican_eel", "eel", "a black deep-sea eel with an enormous pelican-like mouth pouch and a long whip tail with a glowing tip"),
    # Sharks
    ("blacktip_reef_shark", "shark", "grey-brown with black tips on all fins"),
    ("basking_shark", "shark", "huge, grey-brown with pale mottling, a long pointed conical snout (a big nose) sticking far out over the mouth, below it an enormous, wide-open, ring-shaped mouth with the gill rakers visible inside, very long gill slits that almost encircle the head"),
    ("greenland_shark", "shark", "heavy, grey-brown, a short rounded snout, small fins, small eyes"),
    ("bluntnose_sixgill_shark", "shark", "dark brown-grey, a blunt snout, green eyes, one dorsal fin far back"),
    ("port_jackson_shark", "shark", "small, a blunt bulldog head with ridges over the eyes, a dark harness-like pattern on a light brown body"),
    ("great_white_shark", "shark", "big, grey back, white belly, a pointed snout, black eyes"),
    ("frilled_shark", "shark", "eel-like, dark brown, a frilly collar of gill slits, a wide mouth with needle teeth"),
    ("goblin_shark", "shark", "pink-grey, a long flat blade-like snout, protruding jaws with thin teeth"),
    ("copper_shark", "shark", "bronze-grey back with a coppery sheen, white belly, a pointed snout"),
    ("ragged_tooth_shark", "shark", "also called sand tiger shark; it must not look like a great white: a bulky, hump-backed body, a flattened, pointed conical snout, small eyes, two big dorsal fins of nearly the same size set far back, a long upper tail lobe with a short lower one, a sandy bronze-brown back with scattered reddish-brown spots, a pale cream belly, crooked needle teeth sticking out of its open mouth"),
    ("shortfin_mako", "shark", "slim and fast, metallic blue back, white belly, a pointed snout, a crescent tail"),
    ("whale_shark", "shark", "huge, dark blue-grey with white spots and pale stripes, a wide flat head with a wide mouth at the front"),
    ("hybodus", "shark", "Hybodus (Hybodus hauffianus), Jurassic: grey-brown with a pale belly, a blunt snout, a long sharp spine at the front of each of its two dorsal fins"),
    # Flat creatures
    ("european_plaice", "fish", "a flatfish gliding along, showing its eyed brown upper side with bright orange spots: an oval flat body, both eyes on the head, the fins as a fringe all around and a short fan-shaped tail fin"),
    ("reef_manta_ray", "flat", "gliding level to the left, the disc held horizontal (not banking, not tilted up or down): the whole diamond-shaped black disc with white shoulder patches, wide wing tips, the two head fins in front, a short tail"),
    ("smooth_stingray", "flat", "the whole round grey-brown disc, the eyes on top, a long whip-like tail with a spine"),
    ("giant_guitarfish", "shark", "a flat, wide shark-like body with a pointed wedge-shaped snout, white spots on a sandy back, shark-like dorsal fins and tail"),
    ("ocean_sunfish", "fish", "a huge, flat, round fish, the body itself taller than long, with a tall pointed dorsal fin and anal fin and a scalloped, frilly round back end (the clavus) instead of a tail, blue-grey with pale speckles fading into a white belly, a big round eye, a small round pouting mouth, a small pectoral fin; very cute and chubby"),
    # Cephalopods
    ("curled_octopus", "octopus", "an orange-red octopus with a single row of suckers on each arm, only the arm tips curled"),
    ("giant_squid", "ceph", "a huge red squid: the long mantle with its fins leads, the eight arms and two very long tentacles trail behind"),
    ("chambered_nautilus", "ceph", "a coiled shell with brown-orange tiger stripes, the many short tentacles poking out at the opening"),
    ("vampire_squid", "ceph", "swimming level to the left in a plain side view (not upright, not facing the viewer): dark red-black. From left to right: the smooth, rounded tip of the mantle (no mouth, no beak, no nose and no face on it: the mouth is hidden in the middle of the arms), then the two ear-like fins on the mantle, one up and one down, then the head with one very big blue eye, clearly behind the fins (further right than the fins, where the mantle meets the arms, never in front of the fins), then the eight arms joined by a cloak-like dark web, trailing to the right"),
    ("southern_blue_ringed_octopus", "octopus", "a small yellow-brown octopus covered in bright blue rings"),
    ("japanese_flying_squid", "ceph", "a slim red-brown squid with a triangular fin at the mantle tip, eight arms and two longer tentacles"),
    ("giant_pacific_octopus", "octopus", "a huge red-brown octopus with wrinkly skin and pale suckers, long arms"),
    ("common_octopus", "octopus", "a brown-orange octopus with mottled skin"),
    ("colossal_squid", "ceph", "a huge, heavy red squid with a wide mantle, big fins at its tip, big eyes and short, thick arms with hooks plus two longer tentacles"),
    ("ammonite", "ceph", "Jurassic: a ribbed, coiled shell, cream-brown, short tentacles at the opening"),
    ("belemnite", "ceph", "Jurassic: a squid-like body with a pointed tail end, ten short hooked arms, red-brown"),
    # Jellyfish
    ("lions_mane_jellyfish", "jelly", "a big orange-red bell, masses of long hair-like tentacles"),
    ("moon_jellyfish", "jelly", "a clear pale-blue bell with four violet rings (a flower pattern), short fringe tentacles"),
    ("blubber_jellyfish", "jelly", "a pale violet-blue bell, frilly mouth arms, no long tentacles"),
    ("nomuras_jellyfish", "jelly", "an enormous cream-brown bell, thick frilly mouth arms"),
    ("portuguese_man_o_war", "jelly", "a blue-violet gas float like a sail with a pink crest on top, long blue stinging tentacles below"),
    # Crustaceans and other crawlers
    ("japanese_spider_crab", "crust", "an orange-red carapace with white spots, very long thin spidery legs spread wide, two claws in front"),
    ("giant_isopod", "crust", "a big armoured pale lilac woodlouse with overlapping plates, small legs below, two short antennae"),
    ("antarctic_krill", "crust", "a tiny see-through pink shrimp with big black eyes, red dots, long antennae"),
    ("giant_sea_spider", "crust", "a tiny body with eight very long thin orange-red legs spread wide"),
    # Upright swimmers
    ("weedy_seadragon", "upright", "a red-orange seadragon with yellow spots and purple bands, small leaf-like appendages, a long pipe snout"),
    ("leafy_seadragon", "upright", "a yellow-green seadragon covered in big leaf-like appendages, a long pipe snout"),
    ("knysna_seahorse", "upright", "a small brown-green seahorse with a curled tail"),
    # Big animals
    ("sperm_whale", "big", "huge, dark grey, an enormous square head, wrinkled skin, the flippers and the wide horizontal tail flukes"),
    ("blue_whale", "big", "huge, slim, mottled blue-grey, the long flippers and the wide horizontal tail flukes"),
    ("humpback_whale", "big", "dark grey with a white belly and white throat grooves, very long white-edged flippers, round knobs along the top of the snout and on the lower jaw, a small dorsal fin on a low hump, the wide flukes. The long mouth line runs from the snout tip far back along the head and ends just in front of the flipper; the small eye sits low on the side of the head, just above and behind that end of the mouth line, close to the flipper (never on the forehead, never on top of the head, never near the snout)"),
    ("southern_right_whale", "big", "black, a big head (about a quarter of the body) with a narrow, arched upper jaw and a long mouth line that curves high up and back down, white rough patches (callosities) on the snout tip, along the lower lip and just above the eye, no dorsal fin, short wide paddle-shaped flippers, the wide flukes. The small eye sits low on the side of the head, just above and behind the rear end of the curved mouth line, right in front of the flipper, with a white callosity patch just above it (never high up on the head, never above the middle of the mouth arch)"),
    ("orca", "big", "black with a white eye patch, a grey saddle patch behind the tall dorsal fin"),
    ("common_bottlenose_dolphin", "big", "grey, a short beak, a friendly smile, a curved dorsal fin"),
    ("leopard_seal", "big", "long, grey with dark spots, a big reptile-like head, the front flippers at its sides, the hind flippers together behind"),
    ("southern_elephant_seal", "big", "huge, brown-grey, a big floppy nose (a male), the front flippers, the hind flippers together behind"),
    ("ichthyosaurus", "big", "Jurassic marine reptile shaped like a dolphin, grey-blue, a long toothy snout, big eyes, four flippers, a crescent tail"),
    ("plesiosaurus", "big", "Jurassic marine reptile: a small head on a very long neck, a broad body with four big flippers, a short tail, green-brown"),
    ("liopleurodon", "big", "Jurassic marine reptile: a huge crocodile-like head, a short neck, a broad body with four big flippers, dark grey-brown"),
    ("metriorhynchus", "big", "Metriorhynchus (Metriorhynchus superciliosus), Jurassic: a sea crocodile with smooth grey-green skin, a long narrow toothy snout, four small paddle flippers, a shark-like tail fin"),
    ("green_sea_turtle", "big", "a turtle, not a fish: no tail fin at all, only a short stubby tail barely peeking out behind the shell. The olive-green shell in profile with its pattern of plates, the head stretched forward, the long near front flipper held down and back and the small near rear flipper at the back, both clearly apart from each other with open space around them, the far flippers only peeking out"),
    ("loggerhead_turtle", "big", "the red-brown shell in profile, the big head in front, the near front and rear flippers clearly apart"),
    ("leatherback_turtle", "big", "the dark blue-black leathery shell with long ridges and white spots, very long front flippers"),
    ("emperor_penguin", "big", "Emperor penguin (Aptenodytes forsteri), swimming: the black back and head, golden-yellow neck patches, a white belly, only ONE flipper (the near one, held back along the side) and exactly TWO feet together at the tail"),
    ("adelie_penguin", "big", "Adélie penguin (Pygoscelis adeliae), swimming: smaller and rounder, the black back and head, a white eye ring, a white belly, only ONE flipper (the near one, held back along the side) and exactly TWO feet together at the tail"),
]


PROMPT = """Image 1 shows the view and art style I need: one creature, a plain side view, head pointing
left, filling most of the canvas width.

Draw it in exactly the same view and style (cute comic style, dark outlines, flat colours with soft
cel shading, big friendly eyes, but accurate enough for a marine biologist), for a different
species{not_cod}:

{description}{old_sprite}

{outline}

One single drawing, centred. Canvas 1536 x 1024 px, a real transparent background (PNG alpha, not
a white or checkered background, also in the gaps between fins, legs or arms), no glow, no shadow,
no water, no text."""

# The cod in the reference pulls other species towards its shape (a basking shark lost its big
# snout), so every other species is told to take only view and style from it.
NOT_COD = """. Take only the view and style from Image 1, never the cod's shape: the
head, snout, mouth, body outline, proportions and fins must be those of this species, with its
characteristic features clearly shown; it must not look like a cod"""

# Image 2: the species' current sprite (sprite.py info puts it back together, head left), for the
# anatomy only, so the drawing keeps the species' own shape and does not drift towards the cod.
OLD_SPRITE = """

Image 2 shows this species as it looks in the game now, drawn in an older style. Use it only for
the anatomy: the body shape and proportions, the fins and where they sit, the markings, and where
the eye and the mouth are. Do not copy its style, line work, shading or pose: the view and the style
come from Image 1 only."""

# Every species is drawn on the same canvas but shown in the sea at its own size
# (CatchRules.body_length: a blue whale about 8 times as long as the cod, a clownfish less than
# half), so the outlines are drawn thinner the bigger it is shown, to look alike on screen.
REFERENCE_ID = "atlantic_cod"


def sea_length(length_cm: float) -> float:
    """CatchRules.body_length() in ground units (keep in step with src/sim/catch_rules.gd)."""
    if length_cm <= 200.0:
        return min(35.0 + 14.0 * math.sqrt(length_cm), 760.0)
    return min(35.0 + 14.0 * math.sqrt(200.0) + 7.0 / math.sqrt(200.0) * (length_cm - 200.0), 1500.0)


def outline_text(scale: float) -> str:
    """The outline rule for a creature shown `scale` times as long as the cod in the game."""
    why = f"the game shows this creature about {scale:.1f} times as long as the cod"
    if scale <= 0.75:
        return ("Outlines: bolder than in Image 1, about 1.5 times as thick, because the game shows this "
                "creature much smaller than the cod.")
    if scale < 1.3:
        return "Outlines: as thick as in Image 1."
    if scale < 1.75:
        fraction = "two thirds"
    else:
        fraction = {2: "half", 3: "a third", 4: "a quarter", 5: "a fifth", 6: "a sixth", 7: "a seventh"}.get(
            round(scale), "an eighth")
    return (f"Outlines: thin, only about {fraction} as thick as in Image 1, because {why}; thick lines "
            "would look clumsy at that size. Fine details may be drawn with even thinner lines.")


# What the game's animation (FishArt.MOTIONS) needs from the side view.
MOTION_HINTS = {
    "TAIL": " The tail fin sits clearly behind a narrow tail root (the game cuts it off there and beats it).",
    "WAVE": " The body is held straight, not curved or bent (the game bends it in a wave as it swims).",
    "FLAP": " Its wings are spread out flat, not bent up or down (the game flaps them).",
    "PADDLE": " Its flippers stand clearly apart from the body with open space around them (the game rows them).",
    "CRAWL": " Its legs are spread apart, none crossing another (the game swings them).",
}


def motions() -> dict[str, str]:
    """Species id -> motion name from FishArt.MOTIONS; species not listed beat their tail."""
    text = open(os.path.join(ROOT, "src", "scenes", "fishing", "fish_art.gd"), encoding="utf-8").read()
    block = text[text.index("const MOTIONS"):text.index("const WAVES")]
    return dict(re.findall(r'"([a-z0-9_]+)": Motion\.([A-Z]+)', block))


def main() -> None:
    species = {r["id"]: r for r in csv.DictReader(open(os.path.join(ROOT, "data", "species.csv"), encoding="utf-8"))}
    ids = [c[0] for c in CREATURES]
    assert len(ids) == len(set(ids)), "duplicate"
    missing = [s for s in species if s not in ids]
    assert not missing, missing
    os.makedirs(OUT, exist_ok=True)
    motion = motions()
    reference = sea_length(float(species[REFERENCE_ID]["length_cm"]))
    sections = []
    table = []
    for cid, kind, text in CREATURES:
        if cid in species:
            name = f"{species[cid]['common_name']} ({species[cid]['scientific_name']})"
            description = f"{name}: {text}."
            scale = sea_length(float(species[cid]["length_cm"])) / reference
        else:
            name = text.split(")")[0] + ")"
            description = f"{text}."
            scale = 1.0
        description += KIND[kind]
        # Upright swimmers and the kinds with arms or bells say in KIND what their animation needs.
        if kind not in ("upright", "jelly", "ceph", "octopus"):
            description += MOTION_HINTS.get(motion.get(cid, "TAIL"), "")
        new = "" if cid in species else " – new (sheet 14), add to data/species.csv"
        if cid in species and os.path.exists(os.path.join(OUT, f"{cid}.png")):
            new = " – in the game (side view)"
        has_sprite = cid != REFERENCE_ID and os.path.exists(
            os.path.join(ROOT, "assets", "sprites", "fish_painted", f"{cid}_body.png"))
        table.append(f"| `{cid}` | {name}{new} |")
        sections.append(f"""## {name} – `{cid}`

Save as `art_source/fish/views/{cid}.png`, then `python tools/extract_species_views.py {cid}`.

```
{PROMPT.format(description=description, not_cod="" if cid == REFERENCE_ID else NOT_COD, outline=outline_text(scale),
                old_sprite=OLD_SPRITE if has_sprite else "")}
```
""")
    doc = f"""# Species views – generation prompts

One image per species, in a NEW ChatGPT chat each: attach `{REFERENCE}` (the cod from
the side, Image 1) and, for a species already in the game, its current sprite put back together and
turned head left (Image 2, written by `python .claude/skills/regenerate-species-sprite/sprite.py
info <id>` to `build/sprite_check/reference_<id>.png`), then paste the species' prompt. Save the result here as `<id>.png` and cut it with
`python tools/extract_species_views.py <id>` into the side-view sprites (`<id>_body.png`,
`<id>_tail.png`) in `assets/sprites/fish_painted/`. Then import in Godot and turn mipmaps on for
new sprites. Older images here also show two views from above; the game no longer uses them and
the cutter takes only the side view.

Generated by `tools/make_species_view_prompts.py` (edit the descriptions there).

| Species id | Species |
|---|---|
{chr(10).join(table)}

{chr(10).join(sections)}"""
    open(os.path.join(OUT, "prompts.md"), "w", encoding="utf-8", newline="\n").write(doc)
    print(len(CREATURES), "species")


main()
