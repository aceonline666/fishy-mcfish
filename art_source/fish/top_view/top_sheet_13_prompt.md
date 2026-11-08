# Top-view sheet 13 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_13.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `weedy_seadragon` | Weedy seadragon (Phyllopteryx taeniolatus) |
| 1 | 3–4 | `leafy_seadragon` | Leafy seadragon (Phycodurus eques) |
| 2 | 1–2 | `knysna_seahorse` | Knysna seahorse (Hippocampus capensis) |
| 2 | 3–4 | `sperm_whale` | Sperm whale (Physeter macrocephalus) |
| 3 | 1–2 | `blue_whale` | Blue whale (Balaenoptera musculus) |
| 3 | 3–4 | `humpback_whale` | Humpback whale (Megaptera novaeangliae) |
| 4 | 1–2 | `southern_right_whale` | Southern right whale (Eubalaena australis) |
| 4 | 3–4 | `orca` | Orca (Orcinus orca) |

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
Row 1, first: Weedy seadragon (Phyllopteryx taeniolatus): a red-orange seadragon with yellow spots and purple bands, small leaf-like appendages, a long pipe snout. It swims upright: draw it seen from above at an angle, so its snout, back and curled tail stay recognisable.
Row 1, second: Leafy seadragon (Phycodurus eques): a yellow-green seadragon covered in big leaf-like appendages, a long pipe snout. It swims upright: draw it seen from above at an angle, so its snout, back and curled tail stay recognisable.
Row 2, first: Knysna seahorse (Hippocampus capensis): a small brown-green seahorse with a curled tail. It swims upright: draw it seen from above at an angle, so its snout, back and curled tail stay recognisable.
Row 2, second: Sperm whale (Physeter macrocephalus): huge, dark grey, an enormous square head, wrinkled skin; from above the long back, the blowhole on the left front of the head, the flippers and the wide horizontal tail flukes.
Row 3, first: Blue whale (Balaenoptera musculus): huge, slim, mottled blue-grey; from above the long back, the twin blowholes, the long flippers and the wide horizontal tail flukes.
Row 3, second: Humpback whale (Megaptera novaeangliae): dark grey with a white belly, very long white-edged flippers, knobs on the head; from above the back, both long flippers spread, the wide flukes.
Row 4, first: Southern right whale (Eubalaena australis): black, a big arched head with white rough patches, no dorsal fin; from above the broad back, short wide flippers, the wide flukes.
Row 4, second: Orca (Orcinus orca): black with a white eye patch, a grey saddle patch behind the tall dorsal fin; from above the back, the fin, both flippers and the flukes.
```
