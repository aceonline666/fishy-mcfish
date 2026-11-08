# Top-view sheet 07 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_07.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `dapedium` | Dapedium (Dapedium politum) (new, sheet 14) |
| 1 | 3–4 | `pachycormus` | Pachycormus (Pachycormus macropterus) (new, sheet 14) |
| 2 | 1–2 | `lepidotes` | Lepidotes (Lepidotes elvensis) (new, sheet 14) |
| 2 | 3–4 | `lesser_sand_eel` | Lesser sand eel (Ammodytes tobianus) |
| 3 | 1–2 | `conger_eel` | European conger (Conger conger) |
| 3 | 3–4 | `pink_ling` | Pink ling (Genypterus blacodes) |
| 4 | 1–2 | `kingklip` | Kingklip (Genypterus capensis) |
| 4 | 3–4 | `pacific_blackdragon` | Pacific blackdragon (Idiacanthus antrostomus) |

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
Row 1, first: Dapedium (Dapedium politum), Jurassic: a deep, almost round body covered in thick shiny diamond-shaped bronze scales, a small mouth.
Row 1, second: Pachycormus (Pachycormus macropterus), Jurassic: streamlined and tuna-like, blue-grey, long sickle-shaped pectoral fins, a pointed snout.
Row 2, first: Lepidotes (Lepidotes elvensis), Jurassic: large and thick-bodied, heavy shiny square enamel scales, olive-bronze, a blunt head.
Row 2, second: Lesser sand eel (Ammodytes tobianus): a thin silvery eel-like fish with a pointed lower jaw. From above: a long, slim body in a gentle S-curve.
Row 3, first: European conger (Conger conger): a big grey-black eel with a long dorsal fin running down the whole back, a thick head. From above: a long, slim body in a gentle S-curve.
Row 3, second: Pink ling (Genypterus blacodes): an eel-like fish, pink-orange with brown mottling, a long fin around the tail. From above: a long, slim body in a gentle S-curve.
Row 4, first: Kingklip (Genypterus capensis): an eel-like fish, pinkish with brown blotches, a long fin around the tail, a chin barbel-like feeler. From above: a long, slim body in a gentle S-curve.
Row 4, second: Pacific blackdragon (Idiacanthus antrostomus): a long, thin black deep-sea fish with fangs, a long chin barbel with a glowing tip. From above: a long, slim body in a gentle S-curve.
```
