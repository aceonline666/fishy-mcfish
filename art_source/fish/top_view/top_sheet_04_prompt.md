# Top-view sheet 04 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_04.png`, cut it with
   `python tools/extract_top_sheet.py 4`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_04_up.png`, cut it with
   `python tools/extract_top_sheet.py 4 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `blobfish` | Blobfish (Psychrolutes marcidus) |
| 1 | 2 | `common_fangtooth` | Common fangtooth (Anoplogaster cornuta) |
| 1 | 3 | `red_sea_bream` | Red sea bream (Pagrus major) |
| 1 | 4 | `japanese_horse_mackerel` | Japanese horse mackerel (Trachurus japonicus) |
| 2 | 1 | `tiger_puffer` | Tiger puffer (Takifugu rubripes) |
| 2 | 2 | `japanese_amberjack` | Japanese amberjack (Seriola quinqueradiata) |
| 2 | 3 | `opah` | Opah (Lampris guttatus) |
| 2 | 4 | `mariana_snailfish` | Mariana snailfish (Pseudoliparis swirei) |

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
1. Blobfish (Psychrolutes marcidus): a soft, droopy pink body, a big sad face with a fleshy nose, a small tail (alive in the deep sea, a little less droopy).
2. Common fangtooth (Anoplogaster cornuta): small and dark, a huge head with enormous fang teeth, small eyes.
3. Red sea bream (Pagrus major): a tall oval body, pink-red with tiny blue spots, a forked tail.
4. Japanese horse mackerel (Trachurus japonicus): slim, silvery green-blue, a row of bony scutes along the side, a forked tail.

Bottom row from left:
5. Tiger puffer (Takifugu rubripes): a round fugu, grey-brown back with a big black spot ringed in white behind each pectoral fin, a white belly.
6. Japanese amberjack (Seriola quinqueradiata): streamlined, blue-green back, a yellow stripe along the side, silver belly, a forked yellow tail.
7. Opah (Lampris guttatus): a round disc-shaped fish, red-pink with white spots, bright red fins.
8. Mariana snailfish (Pseudoliparis swirei): small, soft, pale pink and almost see-through, a tadpole shape with a big head.
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
