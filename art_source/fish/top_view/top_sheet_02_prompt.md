# Top-view sheet 02 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_02.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `ocellaris_clownfish` | Ocellaris clownfish (Amphiprion ocellaris) |
| 1 | 3–4 | `blue_green_chromis` | Blue-green chromis (Chromis viridis) |
| 2 | 1–2 | `blue_tang` | Blue tang (Paracanthurus hepatus) |
| 2 | 3–4 | `mandarinfish` | Mandarinfish (Synchiropus splendidus) |
| 3 | 1–2 | `red_lionfish` | Red lionfish (Pterois volitans) |
| 3 | 3–4 | `humphead_wrasse` | Humphead wrasse (Cheilinus undulatus) |
| 4 | 1–2 | `atlantic_bluefin_tuna` | Atlantic bluefin tuna (Thunnus thynnus) |
| 4 | 3–4 | `yellowfin_tuna` | Yellowfin tuna (Thunnus albacares) |

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
Row 1, first: Ocellaris clownfish (Amphiprion ocellaris): small, bright orange with three white bands edged in black.
Row 1, second: Blue-green chromis (Chromis viridis): small, iridescent blue-green, a forked tail.
Row 2, first: Blue tang (Paracanthurus hepatus): an oval royal-blue body with a black palette pattern and a yellow tail.
Row 2, second: Mandarinfish (Synchiropus splendidus): tiny, orange and electric blue wavy patterns, big fan-like fins.
Row 3, first: Red lionfish (Pterois volitans): red and white stripes, long fan-like pectoral fins and long venomous spines spread around it.
Row 3, second: Humphead wrasse (Cheilinus undulatus): huge, green-blue, a big hump on the forehead, thick lips, fine wavy lines on the face.
Row 4, first: Atlantic bluefin tuna (Thunnus thynnus): big and torpedo-shaped, a dark blue back, silver belly, yellow finlets, a sickle-shaped tail.
Row 4, second: Yellowfin tuna (Thunnus albacares): torpedo-shaped, dark blue back, a yellow side stripe, long yellow second dorsal and anal fins.
```
