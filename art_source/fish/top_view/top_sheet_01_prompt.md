# Top-view sheet 01 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_01.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `european_sprat` | European sprat (Sprattus sprattus) |
| 1 | 3–4 | `atlantic_herring` | Atlantic herring (Clupea harengus) |
| 2 | 1–2 | `atlantic_mackerel` | Atlantic mackerel (Scomber scombrus) |
| 2 | 3–4 | `lumpsucker` | Lumpsucker (Cyclopterus lumpus) |
| 3 | 1–2 | `atlantic_cod` | Atlantic cod (Gadus morhua) |
| 3 | 3–4 | `atlantic_wolffish` | Atlantic wolffish (Anarhichas lupus) |
| 4 | 1–2 | `roundnose_grenadier` | Roundnose grenadier (Coryphaenoides rupestris) |
| 4 | 3–4 | `rabbit_fish` | Rabbit fish (Chimaera monstrosa) |

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
Row 1, first: European sprat (Sprattus sprattus): small, slim, silvery with a blue-green back and a forked tail.
Row 1, second: Atlantic herring (Clupea harengus): slim, silvery with a blue-green back, a single dorsal fin and a forked tail.
Row 2, first: Atlantic mackerel (Scomber scombrus): streamlined, a green-blue back with black wavy stripes, silver sides, small finlets before the forked tail.
Row 2, second: Lumpsucker (Cyclopterus lumpus): round and lumpy, grey-green with rows of bony bumps, a short tail.
Row 3, first: Atlantic cod (Gadus morhua): olive-brown back with dark spots, pale lateral line, a chin barbel, three dorsal fins (exactly as in the reference image).
Row 3, second: Atlantic wolffish (Anarhichas lupus): long and heavy, blue-grey with dark bands, a big blunt head with strong teeth, one long dorsal fin.
Row 4, first: Roundnose grenadier (Coryphaenoides rupestris): a big head with a rounded snout and big eyes, the body tapering into a long rat-like tail, grey-brown.
Row 4, second: Rabbit fish (Chimaera monstrosa): a chimaera: a big head with huge green eyes, large wing-like pectoral fins, a tall spine on the first dorsal fin, a long whip tail, bronze with white spots.
```
