# Top-view sheet 09 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). In a NEW ChatGPT chat,
attach only `art_source/fish/top_view/reference_top_cod.png`, then paste the prompt (as one paragraph is fine). Save the result as
`art_source/fish/top_view/top_sheet_09.png` and cut it with
`python tools/extract_top_sheet.py 9`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `frilled_shark` | Frilled shark (Chlamydoselachus anguineus) |
| 1 | 2 | `goblin_shark` | Goblin shark (Mitsukurina owstoni) |
| 1 | 3 | `copper_shark` | Copper shark (Carcharhinus brachyurus) |
| 1 | 4 | `ragged_tooth_shark` | Ragged-tooth shark (Carcharias taurus) |
| 2 | 1 | `shortfin_mako` | Shortfin mako (Isurus oxyrinchus) |
| 2 | 2 | `whale_shark` | Whale shark (Rhincodon typus) |
| 2 | 3 | `hybodus` | Hybodus (Hybodus hauffianus) (new, sheet 14) |
| 2 | 4 | `european_plaice` | European plaice (Pleuronectes platessa) |

Check before cutting: every creature seen steeply from above (both eyes, back from above), head at
the lower left, nothing touching the next cell. If one creature is wrong, ask ChatGPT to redraw
only that one, keeping everything else.

## Prompt

```
The attached cod is my reference for the art style AND, most importantly, for the camera view:
we look steeply DOWN on its back from above. We see the whole width of its back, BOTH eyes on top
of the head, BOTH pectoral fins sticking out to the left and right of the body, the dorsal fins
along the middle of the back, and only a thin strip of its flank. It swims towards the lower left:
head at the lower left, tail at the upper right, lying along the diagonal.

Draw 8 different sea creatures EXACTLY in this view, pose and style (cute comic style, bold dark
outlines, flat colours with soft cel shading, big friendly eyes, but accurate enough for a marine
biologist). Canvas 1536 x 1024 px, a grid of 4 columns x 2 rows, one creature centred in each
cell, nothing touching. Fully transparent background, no glow, no shadow, no water, no text.

Top row from left:
1. Frilled shark (Chlamydoselachus anguineus): eel-like, dark brown, a frilly collar of gill slits, a wide mouth with needle teeth. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
2. Goblin shark (Mitsukurina owstoni): pink-grey, a long flat blade-like snout, protruding jaws with thin teeth. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
3. Copper shark (Carcharhinus brachyurus): bronze-grey back with a coppery sheen, white belly, a pointed snout. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
4. Ragged-tooth shark (Carcharias taurus): light brown with darker spots, ragged teeth sticking out of its mouth. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.

Bottom row from left:
5. Shortfin mako (Isurus oxyrinchus): slim and fast, metallic blue back, white belly, a pointed snout, a crescent tail. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
6. Whale shark (Rhincodon typus): huge, dark blue-grey with white spots and pale stripes, a wide flat head with a wide mouth at the front. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
7. Hybodus (Hybodus hauffianus), Jurassic: grey-brown with a pale belly, a blunt snout, a long sharp spine at the front of each of its two dorsal fins. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
8. European plaice (Pleuronectes platessa): a flatfish lying flat: from above we see its whole brown upper side with bright orange spots, both eyes on top, the fins as a fringe all around.
```
