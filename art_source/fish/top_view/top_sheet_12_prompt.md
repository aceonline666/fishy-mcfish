# Top-view sheet 12 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_12.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `moon_jellyfish` | Moon jellyfish (Aurelia aurita) |
| 1 | 3–4 | `blubber_jellyfish` | Blubber jellyfish (Catostylus mosaicus) |
| 2 | 1–2 | `nomuras_jellyfish` | Nomura's jellyfish (Nemopilema nomurai) |
| 2 | 3–4 | `portuguese_man_o_war` | Portuguese man o' war (Physalia physalis) |
| 3 | 1–2 | `japanese_spider_crab` | Japanese spider crab (Macrocheira kaempferi) |
| 3 | 3–4 | `giant_isopod` | Giant isopod (Bathynomus giganteus) |
| 4 | 1–2 | `antarctic_krill` | Antarctic krill (Euphausia superba) |
| 4 | 3–4 | `giant_sea_spider` | Giant sea spider (Colossendeis megalonyx) |

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
Row 1, first: Moon jellyfish (Aurelia aurita): a clear pale-blue bell with four violet rings (a flower pattern), short fringe tentacles. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.
Row 1, second: Blubber jellyfish (Catostylus mosaicus): a pale violet-blue bell, frilly mouth arms, no long tentacles. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.
Row 2, first: Nomura's jellyfish (Nemopilema nomurai): an enormous cream-brown bell, thick frilly mouth arms. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.
Row 2, second: Portuguese man o' war (Physalia physalis): a blue-violet gas float like a sail with a pink crest on top, long blue stinging tentacles below; from above mostly the float. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.
Row 3, first: Japanese spider crab (Macrocheira kaempferi): from above: an orange-red carapace with white spots, very long thin spidery legs spread wide, two claws in front.
Row 3, second: Giant isopod (Bathynomus giganteus): from above: a big armoured pale lilac woodlouse with overlapping plates, small legs at the sides, two short antennae.
Row 4, first: Antarctic krill (Euphausia superba): from above: a tiny see-through pink shrimp with big black eyes, red dots, long antennae.
Row 4, second: Giant sea spider (Colossendeis megalonyx): from above: a tiny body with eight very long thin orange-red legs spread wide.
```
