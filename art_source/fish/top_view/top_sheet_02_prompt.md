# Top-view sheet 02 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_02.png`, cut it with
   `python tools/extract_top_sheet.py 2`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_02_up.png`, cut it with
   `python tools/extract_top_sheet.py 2 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `ocellaris_clownfish` | Ocellaris clownfish (Amphiprion ocellaris) |
| 1 | 2 | `blue_green_chromis` | Blue-green chromis (Chromis viridis) |
| 1 | 3 | `blue_tang` | Blue tang (Paracanthurus hepatus) |
| 1 | 4 | `mandarinfish` | Mandarinfish (Synchiropus splendidus) |
| 2 | 1 | `red_lionfish` | Red lionfish (Pterois volitans) |
| 2 | 2 | `humphead_wrasse` | Humphead wrasse (Cheilinus undulatus) |
| 2 | 3 | `atlantic_bluefin_tuna` | Atlantic bluefin tuna (Thunnus thynnus) |
| 2 | 4 | `yellowfin_tuna` | Yellowfin tuna (Thunnus albacares) |

Check before cutting: every creature seen steeply from above (both eyes, back from above), head at
the lower left, nothing touching the next cell. If one creature is wrong, ask ChatGPT to redraw
only that one, keeping everything else.

## First prompt: towards the lower left

```
The attached cod is my reference for the art style AND, most importantly, for the camera view:
we look steeply DOWN on its back from above. We see the whole width of its back, BOTH eyes on top
of the head, BOTH pectoral fins sticking out to the left and right of the body, the dorsal fins
along the middle of the back, and only a thin strip of its flank. It swims towards the lower left:
head at the lower left, tail at the upper right, lying along the diagonal.

Draw 8 different sea creatures EXACTLY in this view, pose and style (cute comic style, bold dark
outlines, flat colours with soft cel shading, big friendly eyes, but accurate enough for a marine
biologist). Canvas 1536 x 1024 px, a grid of 4 columns x 2 rows, one creature centred in each
cell, nothing touching. Fully transparent background, no glow, no shadow, no water, no text.

Top row from left:
1. Ocellaris clownfish (Amphiprion ocellaris): small, bright orange with three white bands edged in black.
2. Blue-green chromis (Chromis viridis): small, iridescent blue-green, a forked tail.
3. Blue tang (Paracanthurus hepatus): an oval royal-blue body with a black palette pattern and a yellow tail.
4. Mandarinfish (Synchiropus splendidus): tiny, orange and electric blue wavy patterns, big fan-like fins.

Bottom row from left:
5. Red lionfish (Pterois volitans): red and white stripes, long fan-like pectoral fins and long venomous spines spread around it.
6. Humphead wrasse (Cheilinus undulatus): huge, green-blue, a big hump on the forehead, thick lips, fine wavy lines on the face.
7. Atlantic bluefin tuna (Thunnus thynnus): big and torpedo-shaped, a dark blue back, silver belly, yellow finlets, a sickle-shaped tail.
8. Yellowfin tuna (Thunnus albacares): torpedo-shaped, dark blue back, a yellow side stripe, long yellow second dorsal and anal fins.
```

## Second prompt: towards the upper left (same chat)

```
Perfect. Now the same 8 creatures again, a second sheet: identical colours, markings, fins
and style, the same grid of 4 columns x 2 rows in the same order, but every creature now swims
towards the UPPER LEFT, exactly like the newly attached cod: head at the upper left, tail at the
lower right, lying along the diagonal. We still look steeply down on its back from above (back
facing up, BOTH eyes on top of the head, BOTH pectoral fins to the left and right), and the head
is now further from the camera than the tail. Do NOT just flip the old drawings upside down: the
back must stay on top. Fully transparent background, no glow, no shadow, no text.
```
