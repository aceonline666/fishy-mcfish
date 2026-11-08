# Top-view sheet 14 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_14.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `common_bottlenose_dolphin` | Common bottlenose dolphin (Tursiops truncatus) |
| 1 | 3–4 | `leopard_seal` | Leopard seal (Hydrurga leptonyx) |
| 2 | 1–2 | `southern_elephant_seal` | Southern elephant seal (Mirounga leonina) |
| 2 | 3–4 | `ichthyosaurus` | Ichthyosaurus (Ichthyosaurus communis) |
| 3 | 1–2 | `plesiosaurus` | Plesiosaurus (Plesiosaurus dolichodeirus) |
| 3 | 3–4 | `liopleurodon` | Liopleurodon (Liopleurodon ferox) |
| 4 | 1–2 | `metriorhynchus` | Metriorhynchus (Metriorhynchus superciliosus) (new, sheet 14) |
| 4 | 3–4 | `green_sea_turtle` | Green sea turtle (Chelonia mydas) |

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
Row 1, first: Common bottlenose dolphin (Tursiops truncatus): grey, a short beak, a friendly smile; from above the back, the curved dorsal fin, both flippers and the flukes.
Row 1, second: Leopard seal (Hydrurga leptonyx): long, grey with dark spots, a big reptile-like head; from above the back, both front flippers spread, the hind flippers together behind.
Row 2, first: Southern elephant seal (Mirounga leonina): huge, brown-grey, a big floppy nose (a male); from above the bulky back, the front flippers, the hind flippers behind.
Row 2, second: Ichthyosaurus (Ichthyosaurus communis): Jurassic marine reptile shaped like a dolphin, grey-blue, a long toothy snout, big eyes, four flippers, a crescent tail.
Row 3, first: Plesiosaurus (Plesiosaurus dolichodeirus): Jurassic marine reptile: a small head on a very long neck, a broad body with four big flippers, a short tail, green-brown.
Row 3, second: Liopleurodon (Liopleurodon ferox): Jurassic marine reptile: a huge crocodile-like head, a short neck, a broad body with four big flippers, dark grey-brown.
Row 4, first: Metriorhynchus (Metriorhynchus superciliosus), Jurassic: a sea crocodile with smooth grey-green skin, a long narrow toothy snout, four small paddle flippers, a shark-like tail fin.
Row 4, second: Green sea turtle (Chelonia mydas): from above: the olive-green shell with its pattern of plates, the head in front, all four flippers spread.
```
