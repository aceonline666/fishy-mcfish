# Top-view sheet 03 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_03.png`, cut it with
   `python tools/extract_top_sheet.py 3`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_03_up.png`, cut it with
   `python tools/extract_top_sheet.py 3 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `humpback_anglerfish` | Humpback anglerfish (Melanocetus johnsonii) |
| 1 | 2 | `atlantic_footballfish` | Atlantic footballfish (Himantolophus groenlandicus) |
| 1 | 3 | `skinnycheek_lanternfish` | Skinnycheek lanternfish (Benthosema pterotum) |
| 1 | 4 | `west_indian_ocean_coelacanth` | West Indian Ocean coelacanth (Latimeria chalumnae) |
| 2 | 1 | `australian_salmon` | Australian salmon (Arripis trutta) |
| 2 | 2 | `blue_groper` | Blue groper (Achoerodus viridis) |
| 2 | 3 | `old_wife` | Old wife (Enoplosus armatus) |
| 2 | 4 | `orange_roughy` | Orange roughy (Hoplostethus atlanticus) |

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
1. Humpback anglerfish (Melanocetus johnsonii): a small black deep-sea fish, a huge mouth full of needle teeth, a glowing lure on a rod over its head.
2. Atlantic footballfish (Himantolophus groenlandicus): round like a ball, dark brown with bony plates, a lure with glowing tassels on its head.
3. Skinnycheek lanternfish (Benthosema pterotum): tiny, dark with big eyes and rows of glowing blue light dots along the belly.
4. West Indian Ocean coelacanth (Latimeria chalumnae): steel blue with white blotches, thick scales, fleshy lobed fins like little legs, a three-lobed tail.

Bottom row from left:
5. Australian salmon (Arripis trutta): streamlined, a green-blue back with dark spots, silver sides, a forked tail.
6. Blue groper (Achoerodus viridis): a big wrasse, bright blue, thick lips, a rounded tail.
7. Old wife (Enoplosus armatus): a tall, flat, silver-white body with bold black diagonal bands, a tall spiny dorsal fin.
8. Orange roughy (Hoplostethus atlanticus): deep-bodied, bright orange-red, a big bony head with big eyes.
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
