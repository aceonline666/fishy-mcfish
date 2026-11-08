# Top-view sheet 15 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_15.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `loggerhead_turtle` | Loggerhead turtle (Caretta caretta) |
| 1 | 3–4 | `leatherback_turtle` | Leatherback turtle (Dermochelys coriacea) |
| 2 | 1–2 | `emperor_penguin` | Emperor penguin (Aptenodytes forsteri) (new, sheet 14) |
| 2 | 3–4 | `adelie_penguin` | Adélie penguin (Pygoscelis adeliae) (new, sheet 14) |

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

Only the first 2 rows are used; leave the rest of the canvas empty.

The creatures:
Row 1, first: Loggerhead turtle (Caretta caretta): from above: the red-brown shell, the big head in front, all four flippers spread.
Row 1, second: Leatherback turtle (Dermochelys coriacea): from above: the dark blue-black leathery shell with long ridges and white spots, very long front flippers spread.
Row 2, first: Emperor penguin (Aptenodytes forsteri), swimming: from above the black back and head, golden-yellow neck patches, BOTH flippers spread at the sides, the two feet together behind.
Row 2, second: Adélie penguin (Pygoscelis adeliae), swimming: smaller and rounder, from above the black back and head, a white eye ring, BOTH flippers at the sides, the two feet together behind.
```
