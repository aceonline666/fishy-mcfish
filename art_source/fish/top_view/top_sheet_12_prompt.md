# Top-view sheet 12 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_12.png`, cut it with
   `python tools/extract_top_sheet.py 12`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_12_up.png`, cut it with
   `python tools/extract_top_sheet.py 12 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `moon_jellyfish` | Moon jellyfish (Aurelia aurita) |
| 1 | 2 | `blubber_jellyfish` | Blubber jellyfish (Catostylus mosaicus) |
| 1 | 3 | `nomuras_jellyfish` | Nomura's jellyfish (Nemopilema nomurai) |
| 1 | 4 | `portuguese_man_o_war` | Portuguese man o' war (Physalia physalis) |
| 2 | 1 | `japanese_spider_crab` | Japanese spider crab (Macrocheira kaempferi) |
| 2 | 2 | `giant_isopod` | Giant isopod (Bathynomus giganteus) |
| 2 | 3 | `antarctic_krill` | Antarctic krill (Euphausia superba) |
| 2 | 4 | `giant_sea_spider` | Giant sea spider (Colossendeis megalonyx) |

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
1. Moon jellyfish (Aurelia aurita): a clear pale-blue bell with four violet rings (a flower pattern), short fringe tentacles. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.
2. Blubber jellyfish (Catostylus mosaicus): a pale violet-blue bell, frilly mouth arms, no long tentacles. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.
3. Nomura's jellyfish (Nemopilema nomurai): an enormous cream-brown bell, thick frilly mouth arms. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.
4. Portuguese man o' war (Physalia physalis): a blue-violet gas float like a sail with a pink crest on top, long blue stinging tentacles below; from above mostly the float. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.

Bottom row from left:
5. Japanese spider crab (Macrocheira kaempferi): from above: an orange-red carapace with white spots, very long thin spidery legs spread wide, two claws in front.
6. Giant isopod (Bathynomus giganteus): from above: a big armoured pale lilac woodlouse with overlapping plates, small legs at the sides, two short antennae.
7. Antarctic krill (Euphausia superba): from above: a tiny see-through pink shrimp with big black eyes, red dots, long antennae.
8. Giant sea spider (Colossendeis megalonyx): from above: a tiny body with eight very long thin orange-red legs spread wide.
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
