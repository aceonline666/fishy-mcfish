# Top-view sheet 07 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_07.png`, cut it with
   `python tools/extract_top_sheet.py 7`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_07_up.png`, cut it with
   `python tools/extract_top_sheet.py 7 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `dapedium` | Dapedium (Dapedium politum) (new, sheet 14) |
| 1 | 2 | `pachycormus` | Pachycormus (Pachycormus macropterus) (new, sheet 14) |
| 1 | 3 | `lepidotes` | Lepidotes (Lepidotes elvensis) (new, sheet 14) |
| 1 | 4 | `lesser_sand_eel` | Lesser sand eel (Ammodytes tobianus) |
| 2 | 1 | `conger_eel` | European conger (Conger conger) |
| 2 | 2 | `pink_ling` | Pink ling (Genypterus blacodes) |
| 2 | 3 | `kingklip` | Kingklip (Genypterus capensis) |
| 2 | 4 | `pacific_blackdragon` | Pacific blackdragon (Idiacanthus antrostomus) |

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
1. Dapedium (Dapedium politum), Jurassic: a deep, almost round body covered in thick shiny diamond-shaped bronze scales, a small mouth.
2. Pachycormus (Pachycormus macropterus), Jurassic: streamlined and tuna-like, blue-grey, long sickle-shaped pectoral fins, a pointed snout.
3. Lepidotes (Lepidotes elvensis), Jurassic: large and thick-bodied, heavy shiny square enamel scales, olive-bronze, a blunt head.
4. Lesser sand eel (Ammodytes tobianus): a thin silvery eel-like fish with a pointed lower jaw. From above: a long, slim body in a gentle S-curve.

Bottom row from left:
5. European conger (Conger conger): a big grey-black eel with a long dorsal fin running down the whole back, a thick head. From above: a long, slim body in a gentle S-curve.
6. Pink ling (Genypterus blacodes): an eel-like fish, pink-orange with brown mottling, a long fin around the tail. From above: a long, slim body in a gentle S-curve.
7. Kingklip (Genypterus capensis): an eel-like fish, pinkish with brown blotches, a long fin around the tail, a chin barbel-like feeler. From above: a long, slim body in a gentle S-curve.
8. Pacific blackdragon (Idiacanthus antrostomus): a long, thin black deep-sea fish with fangs, a long chin barbel with a glowing tip. From above: a long, slim body in a gentle S-curve.
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
