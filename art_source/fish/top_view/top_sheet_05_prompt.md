# Top-view sheet 05 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_05.png`, cut it with
   `python tools/extract_top_sheet.py 5`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_05_up.png`, cut it with
   `python tools/extract_top_sheet.py 5 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `hottentot_seabream` | Hottentot seabream (Pachymetopon blochii) |
| 1 | 2 | `south_african_sardine` | South African sardine (Sardinops sagax) |
| 1 | 3 | `galjoen` | Galjoen (Dichistius capensis) |
| 1 | 4 | `cape_hake` | Cape hake (Merluccius capensis) |
| 2 | 1 | `sloanes_viperfish` | Sloane's viperfish (Chauliodus sloani) |
| 2 | 2 | `great_barracuda` | Great barracuda (Sphyraena barracuda) |
| 2 | 3 | `crocodile_icefish` | Crocodile icefish (Chionodraco hamatus) |
| 2 | 4 | `antarctic_toothfish` | Antarctic toothfish (Dissostichus mawsoni) |

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
1. Hottentot seabream (Pachymetopon blochii): an oval bronze-grey seabream with a blunt head and a forked tail.
2. South African sardine (Sardinops sagax): small, slim, silvery with a blue back and a row of dark spots along the side.
3. Galjoen (Dichistius capensis): an oval body, dark bronze-black with faint bands, a small mouth, a spiny dorsal fin.
4. Cape hake (Merluccius capensis): slim, silver-grey with a long head, big eyes, a long second dorsal fin.

Bottom row from left:
5. Sloane's viperfish (Chauliodus sloani): a slim black deep-sea fish, huge needle fangs sticking out of its mouth, glowing dots along the belly.
6. Great barracuda (Sphyraena barracuda): long and slim, silver-grey with dark bars, a long pointed jaw full of sharp teeth.
7. Crocodile icefish (Chionodraco hamatus): pale and almost see-through, a long flat crocodile-like snout, large fins.
8. Antarctic toothfish (Dissostichus mawsoni): large and heavy, dark grey-brown, a big head with a wide mouth, two dorsal fins.
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
