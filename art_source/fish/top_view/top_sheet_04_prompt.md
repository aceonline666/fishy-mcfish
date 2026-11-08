# Top-view sheet 04 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_04.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `blobfish` | Blobfish (Psychrolutes marcidus) |
| 1 | 3–4 | `common_fangtooth` | Common fangtooth (Anoplogaster cornuta) |
| 2 | 1–2 | `red_sea_bream` | Red sea bream (Pagrus major) |
| 2 | 3–4 | `japanese_horse_mackerel` | Japanese horse mackerel (Trachurus japonicus) |
| 3 | 1–2 | `tiger_puffer` | Tiger puffer (Takifugu rubripes) |
| 3 | 3–4 | `japanese_amberjack` | Japanese amberjack (Seriola quinqueradiata) |
| 4 | 1–2 | `opah` | Opah (Lampris guttatus) |
| 4 | 3–4 | `mariana_snailfish` | Mariana snailfish (Pseudoliparis swirei) |

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
Row 1, first: Blobfish (Psychrolutes marcidus): a soft, droopy pink body, a big sad face with a fleshy nose, a small tail (alive in the deep sea, a little less droopy).
Row 1, second: Common fangtooth (Anoplogaster cornuta): small and dark, a huge head with enormous fang teeth, small eyes.
Row 2, first: Red sea bream (Pagrus major): a tall oval body, pink-red with tiny blue spots, a forked tail.
Row 2, second: Japanese horse mackerel (Trachurus japonicus): slim, silvery green-blue, a row of bony scutes along the side, a forked tail.
Row 3, first: Tiger puffer (Takifugu rubripes): a round fugu, grey-brown back with a big black spot ringed in white behind each pectoral fin, a white belly.
Row 3, second: Japanese amberjack (Seriola quinqueradiata): streamlined, blue-green back, a yellow stripe along the side, silver belly, a forked yellow tail.
Row 4, first: Opah (Lampris guttatus): a round disc-shaped fish, red-pink with white spots, bright red fins.
Row 4, second: Mariana snailfish (Pseudoliparis swirei): small, soft, pale pink and almost see-through, a tadpole shape with a big head.
```
