# Top-view sheet 09 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_09.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `frilled_shark` | Frilled shark (Chlamydoselachus anguineus) |
| 1 | 3–4 | `goblin_shark` | Goblin shark (Mitsukurina owstoni) |
| 2 | 1–2 | `copper_shark` | Copper shark (Carcharhinus brachyurus) |
| 2 | 3–4 | `ragged_tooth_shark` | Ragged-tooth shark (Carcharias taurus) |
| 3 | 1–2 | `shortfin_mako` | Shortfin mako (Isurus oxyrinchus) |
| 3 | 3–4 | `whale_shark` | Whale shark (Rhincodon typus) |
| 4 | 1–2 | `hybodus` | Hybodus (Hybodus hauffianus) (new, sheet 14) |
| 4 | 3–4 | `european_plaice` | European plaice (Pleuronectes platessa) |

Check before cutting: both drawings of each creature match, heads point lower left (columns 1, 3)
and upper left (columns 2, 4), no glow, nothing touches the next cell. If one creature is wrong,
ask ChatGPT to redraw only that cell pair, keeping everything else.

## Prompt

```
Top-view sprite sheet for a cozy mobile fishing game. Image 1 is the reference for both the
style AND the view: keep its art style exactly (cute comic style, bold dark outlines, flat colours
with soft cel shading, big friendly eyes, yet every animal recognisable to a marine biologist)
and draw every creature from the same steep view from above as the two top cods: the camera looks
down at about 60 degrees, so we see the whole width of the back, both eyes, fins spreading to both
sides, and only a thin strip of the left flank.

Canvas 1536 x 1024 px, fully transparent background (PNG with real alpha). A grid of 4 columns and
4 rows of 384 x 256 px cells, one creature per cell, centred, filling about 85 % of the cell along
its diagonal, never touching another cell. No glow or halo around the creatures, no shadows, no
water, no bubbles, no text, no labels, no numbers, no frames, no checkerboard.

Each row holds two creatures, each drawn twice:
- columns 1 and 2: the first creature of the row, columns 3 and 4: the second,
- columns 1 and 3: swimming towards the LOWER LEFT (head at the lower left, tail at the upper
  right, the head closer to the camera, like the top-left cod in image 1),
- columns 2 and 4: the same creature swimming towards the UPPER LEFT (head at the upper left, tail
  at the lower right, the head further from the camera, like the top-right cod in image 1).
Both drawings of a creature must match exactly in colours, markings and fins.

The creatures:
Row 1, first: Frilled shark (Chlamydoselachus anguineus): eel-like, dark brown, a frilly collar of gill slits, a wide mouth with needle teeth. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 1, second: Goblin shark (Mitsukurina owstoni): pink-grey, a long flat blade-like snout, protruding jaws with thin teeth. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 2, first: Copper shark (Carcharhinus brachyurus): bronze-grey back with a coppery sheen, white belly, a pointed snout. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 2, second: Ragged-tooth shark (Carcharias taurus): light brown with darker spots, ragged teeth sticking out of its mouth. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 3, first: Shortfin mako (Isurus oxyrinchus): slim and fast, metallic blue back, white belly, a pointed snout, a crescent tail. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 3, second: Whale shark (Rhincodon typus): huge, dark blue-grey with white spots and pale stripes, a wide flat head with a wide mouth at the front. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 4, first: Hybodus (Hybodus hauffianus), Jurassic: grey-brown with a pale belly, a blunt snout, a long sharp spine at the front of each of its two dorsal fins. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 4, second: European plaice (Pleuronectes platessa): a flatfish lying flat: from above we see its whole brown upper side with bright orange spots, both eyes on top, the fins as a fringe all around.
```
