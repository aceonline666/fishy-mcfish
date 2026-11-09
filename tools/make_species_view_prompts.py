"""Writes the prompts for the species views into art_source/fish/views/prompts.md: one image per
species, in the layout of the cod in art_source/fish/species_style_test.png (top left seen from
above heading lower left, top right seen from above heading upper left, bottom the side view).
The species, their order and their descriptions live in CREATURES below; edit them there and run
again:

    python tools/make_species_view_prompts.py

Cut each image with tools/extract_species_views.py.
"""
import csv
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art_source", "fish", "views")
REFERENCE = "art_source/fish/species_style_test.png"

# How each kind of creature looks in the three views (added to its description).
KIND = {
    "fish": "",
    "eel": " From above it is a long, slim body in a gentle S-curve.",
    "shark": " From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back.",
    "flat": "",
    "ceph": " In the side view it swims head first, the arms trailing behind.",
    "jelly": " From above: the round bell seen from above (its pattern visible), the tentacles trailing behind it, away from the swimming direction. In the side view: the bell at the top, the tentacles hanging down and trailing.",
    "crust": " In the side view it walks to the left on its legs.",
    "upright": " It swims upright: in the views from above draw it seen from above at an angle, so its snout, back and curled tail stay recognisable; the side view shows it upright, snout pointing left.",
    "big": "",
}

# id: (kind, description). Names and scientific names come from data/species.csv; the sheet 14
# species (not in the game yet) carry their names here.
CREATURES = [
    # Ordinary fish
    ("european_sprat", "fish", "small, slim, silvery with a blue-green back and a forked tail"),
    ("atlantic_herring", "fish", "slim, silvery with a blue-green back, a single dorsal fin and a forked tail"),
    ("atlantic_mackerel", "fish", "streamlined, a green-blue back with black wavy stripes, silver sides, small finlets before the forked tail"),
    ("lumpsucker", "fish", "round and lumpy, grey-green with rows of bony bumps, a short tail"),
    ("atlantic_cod", "fish", "olive-brown back with dark spots, pale lateral line, a chin barbel, three dorsal fins (exactly as in the reference image)"),
    ("atlantic_wolffish", "fish", "long and heavy, blue-grey with dark bands, a big blunt head with strong teeth, one long dorsal fin"),
    ("roundnose_grenadier", "fish", "a big head with a rounded snout and big eyes, the body tapering into a long rat-like tail, grey-brown"),
    ("rabbit_fish", "fish", "a chimaera: a big head with huge green eyes, large wing-like pectoral fins, a tall spine on the first dorsal fin, a long whip tail, bronze with white spots"),
    ("ocellaris_clownfish", "fish", "small, bright orange with three white bands edged in black"),
    ("blue_green_chromis", "fish", "small, iridescent blue-green, a forked tail"),
    ("blue_tang", "fish", "an oval royal-blue body with a black palette pattern and a yellow tail"),
    ("mandarinfish", "fish", "tiny, orange and electric blue wavy patterns, big fan-like fins"),
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
    ("blobfish", "fish", "a soft, droopy pink body, a big sad face with a fleshy nose, a small tail (alive in the deep sea, a little less droopy)"),
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
    ("basking_shark", "shark", "huge, grey-brown, an enormous wide open mouth, long gill slits around the head"),
    ("greenland_shark", "shark", "heavy, grey-brown, a short rounded snout, small fins, small eyes"),
    ("bluntnose_sixgill_shark", "shark", "dark brown-grey, a blunt snout, green eyes, one dorsal fin far back"),
    ("port_jackson_shark", "shark", "small, a blunt bulldog head with ridges over the eyes, a dark harness-like pattern on a light brown body"),
    ("great_white_shark", "shark", "big, grey back, white belly, a pointed snout, black eyes"),
    ("frilled_shark", "shark", "eel-like, dark brown, a frilly collar of gill slits, a wide mouth with needle teeth"),
    ("goblin_shark", "shark", "pink-grey, a long flat blade-like snout, protruding jaws with thin teeth"),
    ("copper_shark", "shark", "bronze-grey back with a coppery sheen, white belly, a pointed snout"),
    ("ragged_tooth_shark", "shark", "light brown with darker spots, ragged teeth sticking out of its mouth"),
    ("shortfin_mako", "shark", "slim and fast, metallic blue back, white belly, a pointed snout, a crescent tail"),
    ("whale_shark", "shark", "huge, dark blue-grey with white spots and pale stripes, a wide flat head with a wide mouth at the front"),
    ("hybodus", "shark", "Hybodus (Hybodus hauffianus), Jurassic: grey-brown with a pale belly, a blunt snout, a long sharp spine at the front of each of its two dorsal fins"),
    # Flat creatures
    ("european_plaice", "flat", "a flatfish lying flat: from above we see its whole brown upper side with bright orange spots, both eyes on top, the fins as a fringe all around"),
    ("reef_manta_ray", "flat", "from above: the whole diamond-shaped black disc with white shoulder patches, wide wing tips, the two head fins in front, a short tail"),
    ("smooth_stingray", "flat", "from above: the whole round grey-brown disc, the eyes on top, a long whip-like tail with a spine"),
    ("giant_guitarfish", "flat", "from above: a flat, wide shark-like body with a pointed wedge-shaped snout, white spots on a sandy back, shark-like dorsal fins and tail"),
    ("ocean_sunfish", "flat", "a huge, flat, round fish with a tall dorsal and anal fin and a frilly round back end instead of a tail, silver-grey; from above we see its narrow back, both fins and the edge of the round body"),
    # Cephalopods
    ("curled_octopus", "ceph", "an orange-red octopus with a single row of suckers; from above: the head (mantle) leads, the eight arms trail behind, their tips curled"),
    ("giant_squid", "ceph", "a huge red squid: from above, the long mantle with its fins leads, the eight arms and two very long tentacles trail behind"),
    ("chambered_nautilus", "ceph", "a coiled shell with brown-orange tiger stripes; from above the shell's back, the many short tentacles poking out at the opening"),
    ("vampire_squid", "ceph", "dark red-black, big blue eyes, a cloak-like web between the arms, two ear-like fins; from above, fins first, the cloak trailing"),
    ("southern_blue_ringed_octopus", "ceph", "a small yellow-brown octopus covered in bright blue rings; from above the mantle leads, the arms trail"),
    ("japanese_flying_squid", "ceph", "a slim red-brown squid with a triangular fin at the mantle tip; from above mantle first, the arms trailing"),
    ("giant_pacific_octopus", "ceph", "a huge red-brown octopus with wrinkly skin; from above the mantle leads, the long arms trail behind"),
    ("common_octopus", "ceph", "a brown-orange octopus with mottled skin; from above the mantle leads, the arms trail behind"),
    ("colossal_squid", "ceph", "a huge, heavy red squid with a wide mantle, big eyes and hooked arms; from above mantle first, the arms trailing"),
    ("ammonite", "ceph", "Jurassic: a ribbed, coiled shell, cream-brown; from above the shell's back, short tentacles at the opening"),
    ("belemnite", "ceph", "Jurassic: a squid-like body with a pointed tail end, ten short hooked arms, red-brown; from above body first, arms trailing"),
    # Jellyfish
    ("lions_mane_jellyfish", "jelly", "a big orange-red bell, masses of long hair-like tentacles"),
    ("moon_jellyfish", "jelly", "a clear pale-blue bell with four violet rings (a flower pattern), short fringe tentacles"),
    ("blubber_jellyfish", "jelly", "a pale violet-blue bell, frilly mouth arms, no long tentacles"),
    ("nomuras_jellyfish", "jelly", "an enormous cream-brown bell, thick frilly mouth arms"),
    ("portuguese_man_o_war", "jelly", "a blue-violet gas float like a sail with a pink crest on top, long blue stinging tentacles below; from above mostly the float"),
    # Crustaceans and other crawlers
    ("japanese_spider_crab", "crust", "from above: an orange-red carapace with white spots, very long thin spidery legs spread wide, two claws in front"),
    ("giant_isopod", "crust", "from above: a big armoured pale lilac woodlouse with overlapping plates, small legs at the sides, two short antennae"),
    ("antarctic_krill", "crust", "from above: a tiny see-through pink shrimp with big black eyes, red dots, long antennae"),
    ("giant_sea_spider", "crust", "from above: a tiny body with eight very long thin orange-red legs spread wide"),
    # Upright swimmers
    ("weedy_seadragon", "upright", "a red-orange seadragon with yellow spots and purple bands, small leaf-like appendages, a long pipe snout"),
    ("leafy_seadragon", "upright", "a yellow-green seadragon covered in big leaf-like appendages, a long pipe snout"),
    ("knysna_seahorse", "upright", "a small brown-green seahorse with a curled tail"),
    # Big animals
    ("sperm_whale", "big", "huge, dark grey, an enormous square head, wrinkled skin; from above the long back, the blowhole on the left front of the head, the flippers and the wide horizontal tail flukes"),
    ("blue_whale", "big", "huge, slim, mottled blue-grey; from above the long back, the twin blowholes, the long flippers and the wide horizontal tail flukes"),
    ("humpback_whale", "big", "dark grey with a white belly, very long white-edged flippers, knobs on the head; from above the back, both long flippers spread, the wide flukes"),
    ("southern_right_whale", "big", "black, a big arched head with white rough patches, no dorsal fin; from above the broad back, short wide flippers, the wide flukes"),
    ("orca", "big", "black with a white eye patch, a grey saddle patch behind the tall dorsal fin; from above the back, the fin, both flippers and the flukes"),
    ("common_bottlenose_dolphin", "big", "grey, a short beak, a friendly smile; from above the back, the curved dorsal fin, both flippers and the flukes"),
    ("leopard_seal", "big", "long, grey with dark spots, a big reptile-like head; from above the back, both front flippers spread, the hind flippers together behind"),
    ("southern_elephant_seal", "big", "huge, brown-grey, a big floppy nose (a male); from above the bulky back, the front flippers, the hind flippers behind"),
    ("ichthyosaurus", "big", "Jurassic marine reptile shaped like a dolphin, grey-blue, a long toothy snout, big eyes, four flippers, a crescent tail"),
    ("plesiosaurus", "big", "Jurassic marine reptile: a small head on a very long neck, a broad body with four big flippers, a short tail, green-brown"),
    ("liopleurodon", "big", "Jurassic marine reptile: a huge crocodile-like head, a short neck, a broad body with four big flippers, dark grey-brown"),
    ("metriorhynchus", "big", "Metriorhynchus (Metriorhynchus superciliosus), Jurassic: a sea crocodile with smooth grey-green skin, a long narrow toothy snout, four small paddle flippers, a shark-like tail fin"),
    ("green_sea_turtle", "big", "from above: the olive-green shell with its pattern of plates, the head in front, all four flippers spread"),
    ("loggerhead_turtle", "big", "from above: the red-brown shell, the big head in front, all four flippers spread"),
    ("leatherback_turtle", "big", "from above: the dark blue-black leathery shell with long ridges and white spots, very long front flippers spread"),
    ("emperor_penguin", "big", "Emperor penguin (Aptenodytes forsteri), swimming: from above the black back and head, golden-yellow neck patches, BOTH flippers spread at the sides, the two feet together behind; in the side view only ONE flipper (the near one, held back along the side) and exactly TWO feet together at the tail"),
    ("adelie_penguin", "big", "Adélie penguin (Pygoscelis adeliae), swimming: smaller and rounder, from above the black back and head, a white eye ring, BOTH flippers at the sides, the two feet together behind; in the side view only ONE flipper (the near one, held back along the side) and exactly TWO feet together at the tail"),
]


PROMPT = """Image 1 shows the exact layout, views and art style I need: one creature drawn three times on
one canvas. Top left: seen steeply from above, swimming towards the lower left (head at the lower
left). Top right: seen steeply from above, swimming towards the upper left (head at the upper left,
further from the camera). Bottom: a plain side view, head pointing left.

Redraw this sheet with exactly the same layout, views, sizes and style (cute comic style, bold dark
outlines, flat colours with soft cel shading, big friendly eyes, but accurate enough for a marine
biologist), for a different species:

{description}

In both views from above we look steeply down on its back: the whole width of the back, both eyes
on top of the head, fins spreading to both sides, only a thin strip of the flank, and the back
always facing up (never belly up). All three drawings are the same individual: identical body
shape, proportions, colours and markings. Canvas 1536 x 1024 px, fully transparent background, no
glow, no shadow, no water, no text."""


def main() -> None:
    species = {r["id"]: r for r in csv.DictReader(open(os.path.join(ROOT, "data", "species.csv"), encoding="utf-8"))}
    ids = [c[0] for c in CREATURES]
    assert len(ids) == len(set(ids)), "duplicate"
    missing = [s for s in species if s not in ids]
    assert not missing, missing
    os.makedirs(OUT, exist_ok=True)
    sections = []
    table = []
    for cid, kind, text in CREATURES:
        if cid in species:
            name = f"{species[cid]['common_name']} ({species[cid]['scientific_name']})"
            description = f"{name}: {text}."
        else:
            name = text.split(")")[0] + ")"
            description = f"{text}."
        description += KIND[kind]
        new = "" if cid in species else " – new (sheet 14), add to data/species.csv"
        table.append(f"| `{cid}` | {name}{new} |")
        sections.append(f"""## {name} – `{cid}`

Save as `art_source/fish/views/{cid}.png`, then `python tools/extract_species_views.py {cid}`.

```
{PROMPT.format(description=description)}
```
""")
    doc = f"""# Species views – generation prompts

One image per species, in a NEW ChatGPT chat each: attach only `{REFERENCE}` (the cod in
the three views) and paste the species' prompt. Save the result here as `<id>.png` and cut it with
`python tools/extract_species_views.py <id>` into the two views from above (`<id>_top.png`,
`<id>_top_up.png`) and the side view (`<id>_body.png`, `<id>_tail.png`) in
`assets/sprites/fish_painted/`. Then import in Godot and turn mipmaps on for new sprites.

Check before cutting: both views from above show the back (both eyes on top), the three drawings
are the same animal (same shape and markings), heads point lower left, upper left and left. If one
view is wrong, ask in the same chat to redraw only that one.

Generated by `tools/make_species_view_prompts.py` (edit the descriptions there). Why one image per
species: on shared sheets ChatGPT drew the same species differently in the two views (the
lumpsucker round in one, slim in the other) or fell back to tilted side views.

| Species id | Species |
|---|---|
{chr(10).join(table)}

{chr(10).join(sections)}"""
    open(os.path.join(OUT, "prompts.md"), "w", encoding="utf-8", newline="\n").write(doc)
    print(len(CREATURES), "species")


main()
