# Top-view sheet 05 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_05.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `hottentot_seabream` | Hottentot seabream (Pachymetopon blochii) |
| 1 | 3–4 | `south_african_sardine` | South African sardine (Sardinops sagax) |
| 2 | 1–2 | `galjoen` | Galjoen (Dichistius capensis) |
| 2 | 3–4 | `cape_hake` | Cape hake (Merluccius capensis) |
| 3 | 1–2 | `sloanes_viperfish` | Sloane's viperfish (Chauliodus sloani) |
| 3 | 3–4 | `great_barracuda` | Great barracuda (Sphyraena barracuda) |
| 4 | 1–2 | `crocodile_icefish` | Crocodile icefish (Chionodraco hamatus) |
| 4 | 3–4 | `antarctic_toothfish` | Antarctic toothfish (Dissostichus mawsoni) |

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
Row 1, first: Hottentot seabream (Pachymetopon blochii): an oval bronze-grey seabream with a blunt head and a forked tail.
Row 1, second: South African sardine (Sardinops sagax): small, slim, silvery with a blue back and a row of dark spots along the side.
Row 2, first: Galjoen (Dichistius capensis): an oval body, dark bronze-black with faint bands, a small mouth, a spiny dorsal fin.
Row 2, second: Cape hake (Merluccius capensis): slim, silver-grey with a long head, big eyes, a long second dorsal fin.
Row 3, first: Sloane's viperfish (Chauliodus sloani): a slim black deep-sea fish, huge needle fangs sticking out of its mouth, glowing dots along the belly.
Row 3, second: Great barracuda (Sphyraena barracuda): long and slim, silver-grey with dark bars, a long pointed jaw full of sharp teeth.
Row 4, first: Crocodile icefish (Chionodraco hamatus): pale and almost see-through, a long flat crocodile-like snout, large fins.
Row 4, second: Antarctic toothfish (Dissostichus mawsoni): large and heavy, dark grey-brown, a big head with a wide mouth, two dorsal fins.
```
