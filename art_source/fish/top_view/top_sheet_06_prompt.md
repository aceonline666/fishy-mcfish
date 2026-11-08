# Top-view sheet 06 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_06.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `leedsichthys` | Leedsichthys (Leedsichthys problematicus) |
| 1 | 3–4 | `antarctic_silverfish` | Antarctic silverfish (Pleuragramma antarctica) (new, sheet 14) |
| 2 | 1–2 | `emerald_rockcod` | Emerald rockcod (Trematomus bernacchii) (new, sheet 14) |
| 2 | 3–4 | `bald_notothen` | Bald notothen (Pagothenia borchgrevinki) (new, sheet 14) |
| 3 | 1–2 | `mackerel_icefish` | Mackerel icefish (Champsocephalus gunnari) (new, sheet 14) |
| 3 | 3–4 | `marbled_rockcod` | Marbled rockcod (Notothenia rossii) (new, sheet 14) |
| 4 | 1–2 | `antarctic_jonasfish` | Antarctic jonasfish (Neopagetopsis ionah) (new, sheet 14) |
| 4 | 3–4 | `leptolepis` | Leptolepis (Leptolepis coryphaenoides) (new, sheet 14) |

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
Row 1, first: Leedsichthys (Leedsichthys problematicus): Jurassic giant filter feeder: an enormous, long, grey-brown fish with a huge wide gaping mouth, long pectoral fins and a big forked tail.
Row 1, second: Antarctic silverfish (Pleuragramma antarctica): small, slim, silvery, almost see-through, a big eye, a forked tail.
Row 2, first: Emerald rockcod (Trematomus bernacchii): stocky, mottled green-brown with dark bands, a big head, wide pectoral fins.
Row 2, second: Bald notothen (Pagothenia borchgrevinki): slim, silvery-grey with dark spots, a pointed head, a long second dorsal fin.
Row 3, first: Mackerel icefish (Champsocephalus gunnari): long, pale see-through grey-white with dark bands on the back, a long flat snout.
Row 3, second: Marbled rockcod (Notothenia rossii): heavy, a big head, olive-brown with darker marbled patches.
Row 4, first: Antarctic jonasfish (Neopagetopsis ionah): a large pale icefish with a long duck-billed snout, faint dark bands, a tall spiny first dorsal fin.
Row 4, second: Leptolepis (Leptolepis coryphaenoides), Jurassic: small, slender, herring-like, silver with thin round scales.
```
