# Top-view sheet 13 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). In a NEW ChatGPT chat,
attach only `art_source/fish/top_view/reference_top_cod.png`, then paste the prompt (as one paragraph is fine). Save the result as
`art_source/fish/top_view/top_sheet_13.png` and cut it with
`python tools/extract_top_sheet.py 13`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `weedy_seadragon` | Weedy seadragon (Phyllopteryx taeniolatus) |
| 1 | 2 | `leafy_seadragon` | Leafy seadragon (Phycodurus eques) |
| 1 | 3 | `knysna_seahorse` | Knysna seahorse (Hippocampus capensis) |
| 1 | 4 | `sperm_whale` | Sperm whale (Physeter macrocephalus) |
| 2 | 1 | `blue_whale` | Blue whale (Balaenoptera musculus) |
| 2 | 2 | `humpback_whale` | Humpback whale (Megaptera novaeangliae) |
| 2 | 3 | `southern_right_whale` | Southern right whale (Eubalaena australis) |
| 2 | 4 | `orca` | Orca (Orcinus orca) |

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
1. Weedy seadragon (Phyllopteryx taeniolatus): a red-orange seadragon with yellow spots and purple bands, small leaf-like appendages, a long pipe snout. It swims upright: draw it seen from above at an angle, so its snout, back and curled tail stay recognisable.
2. Leafy seadragon (Phycodurus eques): a yellow-green seadragon covered in big leaf-like appendages, a long pipe snout. It swims upright: draw it seen from above at an angle, so its snout, back and curled tail stay recognisable.
3. Knysna seahorse (Hippocampus capensis): a small brown-green seahorse with a curled tail. It swims upright: draw it seen from above at an angle, so its snout, back and curled tail stay recognisable.
4. Sperm whale (Physeter macrocephalus): huge, dark grey, an enormous square head, wrinkled skin; from above the long back, the blowhole on the left front of the head, the flippers and the wide horizontal tail flukes.

Bottom row from left:
5. Blue whale (Balaenoptera musculus): huge, slim, mottled blue-grey; from above the long back, the twin blowholes, the long flippers and the wide horizontal tail flukes.
6. Humpback whale (Megaptera novaeangliae): dark grey with a white belly, very long white-edged flippers, knobs on the head; from above the back, both long flippers spread, the wide flukes.
7. Southern right whale (Eubalaena australis): black, a big arched head with white rough patches, no dorsal fin; from above the broad back, short wide flippers, the wide flukes.
8. Orca (Orcinus orca): black with a white eye patch, a grey saddle patch behind the tall dorsal fin; from above the back, the fin, both flippers and the flukes.
```
