# Species sheets 12 and 13 – generation prompts

One consistent style for every species (README TODO): the 23 species whose sprites still come
from the comic-style sheets (`painted_sprite_sheet.png`, `sea_creatures_sheet.png`,
`species_sheet_5.png`) are painted again in the style of sheets 6 to 9. Sheet 12 also redoes three
sprites that came out wrong:

- the scalloped hammerhead of sheet 9 (its hammer looked as if seen from the front);
- the emperor and Adélie penguins of sheet 10 (two flippers on one side, three feet). The rest of
  sheet 10 is fine; the penguins are taken from sheet 12 instead.

The view stays strictly side-on, as for every other species: FishArt draws all fish side-on and
tilts them a little with their direction, so an isometric view would mean redrawing every
species and the animations at once.

Attach `art_source/fish/species_sheet_6.png` and `art_source/fish/species_sheet_9.png` as the
**style** references. Cut with
`python tools/extract_painted.py art_source/fish/species_sheet_12.png assets/sprites/fish_painted`
(and sheet 13), after adding both sheets to `SHEETS` in the script.

Layout of both: canvas 1536 × 1024, a grid of four columns and four rows of 384 × 256 px cells,
13 creatures (the last row has one, in its first cell). Fish face LEFT; the jellyfish, the
octopus and the vampire squid hang bell or head up, arms down (their pulse animation squeezes the
top and lets the arms trail).

---

## Sheet 12

```
A sprite sheet for a cozy mobile game about fish. Match the painting style, the outline, the
soft shading and the light of the attached species sheets exactly: friendly but accurate, every
species recognisable by a marine biologist. Use only their style, not their animals.

Canvas 1536 × 1024 px, fully transparent background (PNG with alpha). Thirteen creatures in a
grid of four columns and four rows of 384 × 256 px cells (the last row has only one, in the first
cell), each centred in its own cell and filling about 85 % of its width, well apart: no creature
touches or overlaps another, no labels, no text, no numbers, no frames, no water, no bubbles, no
shadows.

Every creature is seen EXACTLY FROM THE SIDE, HEAD POINTING LEFT, its body straight and
horizontal, unless said otherwise.

1. Emperor penguin (Aptenodytes forsteri), swimming underwater, seen exactly from the side: a
   streamlined body, black back, white belly, golden-yellow patches on the neck, ONE flipper
   (the near one) held back along the side, the TWO feet together at the tail pointing back.
   Anatomically correct: exactly two feet, one visible flipper.
2. Adélie penguin (Pygoscelis adeliae), swimming underwater, seen exactly from the side: smaller,
   black back and head, white belly, a white ring round the eye, ONE flipper held back along the
   side, the TWO feet together at the tail. Anatomically correct.
3. Scalloped hammerhead (Sphyrna lewini), seen from the side and slightly from above, so its
   wide, flat hammer-shaped head shows as a T: a broad flat blade across the front with the
   wavy (scalloped) front edge and an eye at each end, bronze-grey back, white belly, tall
   first dorsal fin, long upper tail lobe.
4. Atlantic bluefin tuna (Thunnus thynnus): a big torpedo body, dark blue back, silver sides,
   yellow finlets behind the second dorsal and anal fins, a crescent tail.
5. Atlantic cod (Gadus morhua): olive-brown, speckled back, pale lateral line, a chin barbel,
   three dorsal fins and two anal fins.
6. Blacktip reef shark (Carcharhinus melanopterus): slim grey-brown shark, white belly, black
   tips on the dorsal fin and the tail.
7. Curled octopus (Eledone cirrhosa), HEAD UP: an orange-red, warty mantle at the top, eight arms
   with a single row of suckers hanging down and curling at the tips.
8. European plaice (Pleuronectes platessa), seen from the side at a slight angle so its flat
   body shows: brown with bright orange spots, both eyes on the upper side.
9. Green sea turtle (Chelonia mydas), seen from the side and slightly from above, swimming: a
   smooth, olive-brown shell with large plates, a small rounded head, long front flippers, short
   back flippers.
10. Lion's mane jellyfish (Cyanea capillata), BELL UP: a wide, red-orange to golden bell, a dense
    mane of long, thin tentacles and frilly oral arms hanging down.
11. Lumpsucker (Cyclopterus lumpus): a round, lumpy body with rows of bony bumps, blue-grey, the
    suction disc on its belly.
12. Blobfish (Psychrolutes marcidus), in the water (not collapsed): a large, soft, pale pink
    head, a tapering body and small fins.
13. Blue whale (Balaenoptera musculus): very long and slender, mottled blue-grey, a small dorsal
    fin far back, throat grooves, broad flat head, flukes horizontal (seen edge-on).
```

---

## Sheet 13

```
A sprite sheet for a cozy mobile game about fish. Match the painting style, the outline, the
soft shading and the light of the attached species sheets exactly: friendly but accurate, every
species recognisable by a marine biologist. Use only their style, not their animals.

Canvas 1536 × 1024 px, fully transparent background (PNG with alpha). Thirteen creatures in a
grid of four columns and four rows of 384 × 256 px cells (the last row has only one, in the first
cell), each centred in its own cell and filling about 85 % of its width, well apart: no creature
touches or overlaps another, no labels, no text, no numbers, no frames, no water, no bubbles, no
shadows.

Every creature is seen EXACTLY FROM THE SIDE, HEAD POINTING LEFT, its body straight and
horizontal, unless said otherwise.

1. Humpback anglerfish (Melanocetus johnsonii): a round, dark brown-black body, a huge mouth
   with needle teeth, a glowing lure on a stalk over its head.
2. Humphead wrasse (Cheilinus undulatus): a big green-blue wrasse with a bulging forehead hump,
   thick lips and fine wavy lines on the face.
3. Pacific blackdragon (Idiacanthus antrostomus): a long, slim, jet-black eel-like dragonfish,
   fang-like teeth, a chin barbel with a small glowing tip.
4. Red lionfish (Pterois volitans): red and white stripes, long, fanned venomous spines on the
   back and wide, feathery pectoral fins.
5. West Indian Ocean coelacanth (Latimeria chalumnae): deep steel-blue with white blotches, thick
   lobed, limb-like fins and a three-lobed tail.
6. Basking shark (Cetorhinus maximus): huge grey-brown shark with an enormous gaping mouth, very
   long gill slits round the head, a pointed snout.
7. Blue tang (Paracanthurus hepatus): royal blue oval body, a black palette-shaped band, a yellow
   tail.
8. Greenland shark (Somniosus microcephalus): heavy, rounded, grey-brown shark with small fins
   and a short rounded snout, a small pale parasite on its eye.
9. Mandarinfish (Synchiropus splendidus): a small fish with swirling blue, orange and green
   patterns.
10. Ocean sunfish (Mola mola): a huge, flat, disc-shaped grey body with a tall dorsal fin and a
    tall anal fin and no real tail, only a frilly rudder (clavus).
11. Ocellaris clownfish (Amphiprion ocellaris): orange with three white bands edged in black.
12. Sperm whale (Physeter macrocephalus): a huge, square, block-like head taking a third of the
    body, a narrow lower jaw, wrinkled dark grey skin, a low hump instead of a dorsal fin, flukes
    horizontal (seen edge-on).
13. Vampire squid (Vampyroteuthis infernalis), HEAD UP: a dark red body with two ear-like fins
    and large blue eyes, eight arms joined by a black webbed cloak, hanging down.
```
