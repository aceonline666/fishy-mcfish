# Species sheet 6 – generation prompt

Replaces sprites that showed the wrong animal: the four small schooling fish were the same
generic tuna-like fish, the sand eel and the kingklip were not eel-like, the old wife was a red
scorpionfish, the rabbit fish (*Chimaera monstrosa*) a tropical rabbitfish, and the tiger puffer,
the blue-green chromis and the Port Jackson shark lacked their marks.

Attach `art_source/fish/species_sheet_4.png` as the **style** reference. Cut with
`python tools/extract_painted.py art_source/fish/species_sheet_6.png assets/sprites/fish_painted`
(its entry in `SHEETS` gives a point on each sprite).

## Prompt

```
A sprite sheet for a cozy mobile game about fish. Match the painted cartoon style, the bold dark
outline, the soft shading and the light of the attached species sheet exactly: friendly but
accurate, every species recognisable by a marine biologist. Use only its style, not its fish.

Canvas 1536 × 1024 px, fully transparent background (PNG with alpha). Eleven creatures in a
loose grid of four columns and three rows (the last row has three), each in its own cell, well
apart: no creature touches or overlaps another, no labels, no text, no numbers, no frames, no
water, no bubbles, no shadows.

Every creature is seen exactly from the side, with its HEAD POINTING LEFT and its tail to the
right, body straight (not bent or curled), the tail fin spread wide open and clearly visible,
the fins spread. Similar size on the sheet: each about 300 px long.

Row 1:
1. European sprat (Sprattus sprattus): a small slender silvery herring-like fish, blue-green
   back, bright silver sides, a sharp saw-edged belly, small forked tail, no stripes, no spots.
2. Atlantic herring (Clupea harengus): slender silver fish with a dark blue-green back fading to
   silver, large eye, single small dorsal fin in the middle of the back, deeply forked tail.
3. Atlantic mackerel (Scomber scombrus): streamlined fish with a shiny green-blue back covered
   in bold black WAVY TIGER STRIPES, silvery-white belly without marks, two small dorsal fins
   far apart, a row of little finlets before the deeply forked tail.
4. South African sardine (Sardinops sagax): slender silver fish with a blue back and a ROW OF
   ROUND BLACK SPOTS along its upper side, small forked tail.

Row 2:
5. Lesser sand eel (Ammodytes tobianus): a very long, thin, pencil-shaped silvery-yellowish fish
   (at least eight times as long as tall) with a pointed snout and protruding lower jaw, a long
   low dorsal fin along the back, a small forked tail. Not an eel: a straight slim fish.
6. Kingklip (Genypterus capensis): an EEL-LIKE cusk-eel, long and tapering, pinkish-orange skin
   mottled with irregular brown blotches, a long continuous low fin along the back and belly
   that joins the small pointed tail, small chin barbels-like pelvic fins under the throat.
7. Old wife (Enoplosus armatus): a deep, flat, almost diamond-shaped silver-white fish with
   SEVEN to eight bold BLACK VERTICAL BANDS, two tall dorsal fins (the first with long spines),
   a small mouth, a rounded tail fin.
8. Rabbit fish (Chimaera monstrosa): a ghost shark: a large rounded head with huge GREEN
   reflecting eyes and a small rabbit-like mouth with front teeth, a brownish-bronze body with
   pale spots and silvery sheen, a tall pointed first dorsal fin with a spine, large wing-like
   pectoral fins, and a body that tapers into a LONG THIN WHIP-LIKE TAIL.

Row 3:
9. Tiger puffer (Takifugu rubripes): a chunky pufferfish, not inflated, dark grey-brown back with
   small dark spots, white belly, and one big round BLACK SPOT ringed with WHITE behind the
   pectoral fin, a small beak-like mouth, a short rounded tail fin.
10. Blue-green chromis (Chromis viridis): a small oval damselfish, iridescent pale apple-green to
   light blue all over, with a deeply FORKED tail and pointed fin tips, no other marks.
11. Port Jackson shark (Heterodontus portusjacksoni): a bull-headed shark with a blunt high
   forehead with ridges over the eyes, pale grey-brown body with a dark HARNESS-LIKE BAND
   running from the eye down the back and over the sides, two dorsal fins each with a spine,
   a shark tail.
```
