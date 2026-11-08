# Top-view sheet 15 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_15.png`, cut it with
   `python tools/extract_top_sheet.py 15`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_15_up.png`, cut it with
   `python tools/extract_top_sheet.py 15 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `loggerhead_turtle` | Loggerhead turtle (Caretta caretta) |
| 1 | 2 | `leatherback_turtle` | Leatherback turtle (Dermochelys coriacea) |
| 1 | 3 | `emperor_penguin` | Emperor penguin (Aptenodytes forsteri) (new, sheet 14) |
| 1 | 4 | `adelie_penguin` | Adélie penguin (Pygoscelis adeliae) (new, sheet 14) |

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

Draw 4 different sea creatures EXACTLY in this view, pose and style (cute comic style, bold dark
outlines, flat colours with soft cel shading, big friendly eyes, but accurate enough for a marine
biologist). Canvas 1536 x 1024 px, a grid of 4 columns x 2 rows, one creature centred in each
cell, nothing touching. Fully transparent background, no glow, no shadow, no water, no text.

Top row from left:
1. Loggerhead turtle (Caretta caretta): from above: the red-brown shell, the big head in front, all four flippers spread.
2. Leatherback turtle (Dermochelys coriacea): from above: the dark blue-black leathery shell with long ridges and white spots, very long front flippers spread.
3. Emperor penguin (Aptenodytes forsteri), swimming: from above the black back and head, golden-yellow neck patches, BOTH flippers spread at the sides, the two feet together behind.
4. Adélie penguin (Pygoscelis adeliae), swimming: smaller and rounder, from above the black back and head, a white eye ring, BOTH flippers at the sides, the two feet together behind.

Leave the bottom row empty.
```

## Second prompt: towards the upper left (same chat)

```
Perfect. Now the same 4 creatures again, a second sheet: identical colours, markings, fins
and style, the same grid of 4 columns x 2 rows in the same order, but every creature now swims
towards the UPPER LEFT, exactly like the newly attached cod: head at the upper left, tail at the
lower right, lying along the diagonal. We still look steeply down on its back from above (back
facing up, BOTH eyes on top of the head, BOTH pectoral fins to the left and right), and the head
is now further from the camera than the tail. Do NOT just flip the old drawings upside down: the
back must stay on top. Fully transparent background, no glow, no shadow, no text.
```
