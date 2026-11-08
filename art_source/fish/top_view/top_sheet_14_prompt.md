# Top-view sheet 14 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_14.png`, cut it with
   `python tools/extract_top_sheet.py 14`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_14_up.png`, cut it with
   `python tools/extract_top_sheet.py 14 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `common_bottlenose_dolphin` | Common bottlenose dolphin (Tursiops truncatus) |
| 1 | 2 | `leopard_seal` | Leopard seal (Hydrurga leptonyx) |
| 1 | 3 | `southern_elephant_seal` | Southern elephant seal (Mirounga leonina) |
| 1 | 4 | `ichthyosaurus` | Ichthyosaurus (Ichthyosaurus communis) |
| 2 | 1 | `plesiosaurus` | Plesiosaurus (Plesiosaurus dolichodeirus) |
| 2 | 2 | `liopleurodon` | Liopleurodon (Liopleurodon ferox) |
| 2 | 3 | `metriorhynchus` | Metriorhynchus (Metriorhynchus superciliosus) (new, sheet 14) |
| 2 | 4 | `green_sea_turtle` | Green sea turtle (Chelonia mydas) |

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
1. Common bottlenose dolphin (Tursiops truncatus): grey, a short beak, a friendly smile; from above the back, the curved dorsal fin, both flippers and the flukes.
2. Leopard seal (Hydrurga leptonyx): long, grey with dark spots, a big reptile-like head; from above the back, both front flippers spread, the hind flippers together behind.
3. Southern elephant seal (Mirounga leonina): huge, brown-grey, a big floppy nose (a male); from above the bulky back, the front flippers, the hind flippers behind.
4. Ichthyosaurus (Ichthyosaurus communis): Jurassic marine reptile shaped like a dolphin, grey-blue, a long toothy snout, big eyes, four flippers, a crescent tail.

Bottom row from left:
5. Plesiosaurus (Plesiosaurus dolichodeirus): Jurassic marine reptile: a small head on a very long neck, a broad body with four big flippers, a short tail, green-brown.
6. Liopleurodon (Liopleurodon ferox): Jurassic marine reptile: a huge crocodile-like head, a short neck, a broad body with four big flippers, dark grey-brown.
7. Metriorhynchus (Metriorhynchus superciliosus), Jurassic: a sea crocodile with smooth grey-green skin, a long narrow toothy snout, four small paddle flippers, a shark-like tail fin.
8. Green sea turtle (Chelonia mydas): from above: the olive-green shell with its pattern of plates, the head in front, all four flippers spread.
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
