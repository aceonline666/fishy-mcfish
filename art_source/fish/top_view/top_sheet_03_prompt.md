# Top-view sheet 03 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_03.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `humpback_anglerfish` | Humpback anglerfish (Melanocetus johnsonii) |
| 1 | 3–4 | `atlantic_footballfish` | Atlantic footballfish (Himantolophus groenlandicus) |
| 2 | 1–2 | `skinnycheek_lanternfish` | Skinnycheek lanternfish (Benthosema pterotum) |
| 2 | 3–4 | `west_indian_ocean_coelacanth` | West Indian Ocean coelacanth (Latimeria chalumnae) |
| 3 | 1–2 | `australian_salmon` | Australian salmon (Arripis trutta) |
| 3 | 3–4 | `blue_groper` | Blue groper (Achoerodus viridis) |
| 4 | 1–2 | `old_wife` | Old wife (Enoplosus armatus) |
| 4 | 3–4 | `orange_roughy` | Orange roughy (Hoplostethus atlanticus) |

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
Row 1, first: Humpback anglerfish (Melanocetus johnsonii): a small black deep-sea fish, a huge mouth full of needle teeth, a glowing lure on a rod over its head.
Row 1, second: Atlantic footballfish (Himantolophus groenlandicus): round like a ball, dark brown with bony plates, a lure with glowing tassels on its head.
Row 2, first: Skinnycheek lanternfish (Benthosema pterotum): tiny, dark with big eyes and rows of glowing blue light dots along the belly.
Row 2, second: West Indian Ocean coelacanth (Latimeria chalumnae): steel blue with white blotches, thick scales, fleshy lobed fins like little legs, a three-lobed tail.
Row 3, first: Australian salmon (Arripis trutta): streamlined, a green-blue back with dark spots, silver sides, a forked tail.
Row 3, second: Blue groper (Achoerodus viridis): a big wrasse, bright blue, thick lips, a rounded tail.
Row 4, first: Old wife (Enoplosus armatus): a tall, flat, silver-white body with bold black diagonal bands, a tall spiny dorsal fin.
Row 4, second: Orange roughy (Hoplostethus atlanticus): deep-bodied, bright orange-red, a big bony head with big eyes.
```
