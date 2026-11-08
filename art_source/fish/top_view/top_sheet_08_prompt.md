# Top-view sheet 08 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_08.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `giant_oarfish` | Giant oarfish (Regalecus glesne) |
| 1 | 3–4 | `pelican_eel` | Pelican eel (Eurypharynx pelecanoides) |
| 2 | 1–2 | `blacktip_reef_shark` | Blacktip reef shark (Carcharhinus melanopterus) |
| 2 | 3–4 | `basking_shark` | Basking shark (Cetorhinus maximus) |
| 3 | 1–2 | `greenland_shark` | Greenland shark (Somniosus microcephalus) |
| 3 | 3–4 | `bluntnose_sixgill_shark` | Bluntnose sixgill shark (Hexanchus griseus) |
| 4 | 1–2 | `port_jackson_shark` | Port Jackson shark (Heterodontus portusjacksoni) |
| 4 | 3–4 | `great_white_shark` | Great white shark (Carcharodon carcharias) |

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
Row 1, first: Giant oarfish (Regalecus glesne): a very long ribbon-like silver fish with a red crest on its head and a red fin running along the whole back. From above: a long, slim body in a gentle S-curve.
Row 1, second: Pelican eel (Eurypharynx pelecanoides): a black deep-sea eel with an enormous pelican-like mouth pouch and a long whip tail with a glowing tip. From above: a long, slim body in a gentle S-curve.
Row 2, first: Blacktip reef shark (Carcharhinus melanopterus): grey-brown with black tips on all fins. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 2, second: Basking shark (Cetorhinus maximus): huge, grey-brown, an enormous wide open mouth, long gill slits around the head. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 3, first: Greenland shark (Somniosus microcephalus): heavy, grey-brown, a short rounded snout, small fins, small eyes. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 3, second: Bluntnose sixgill shark (Hexanchus griseus): dark brown-grey, a blunt snout, green eyes, one dorsal fin far back. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 4, first: Port Jackson shark (Heterodontus portusjacksoni): small, a blunt bulldog head with ridges over the eyes, a dark harness-like pattern on a light brown body. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
Row 4, second: Great white shark (Carcharodon carcharias): big, grey back, white belly, a pointed snout, black eyes. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
```
