# Top-view sheet 06 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_06.png`, cut it with
   `python tools/extract_top_sheet.py 6`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_06_up.png`, cut it with
   `python tools/extract_top_sheet.py 6 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `leedsichthys` | Leedsichthys (Leedsichthys problematicus) |
| 1 | 2 | `antarctic_silverfish` | Antarctic silverfish (Pleuragramma antarctica) (new, sheet 14) |
| 1 | 3 | `emerald_rockcod` | Emerald rockcod (Trematomus bernacchii) (new, sheet 14) |
| 1 | 4 | `bald_notothen` | Bald notothen (Pagothenia borchgrevinki) (new, sheet 14) |
| 2 | 1 | `mackerel_icefish` | Mackerel icefish (Champsocephalus gunnari) (new, sheet 14) |
| 2 | 2 | `marbled_rockcod` | Marbled rockcod (Notothenia rossii) (new, sheet 14) |
| 2 | 3 | `antarctic_jonasfish` | Antarctic jonasfish (Neopagetopsis ionah) (new, sheet 14) |
| 2 | 4 | `leptolepis` | Leptolepis (Leptolepis coryphaenoides) (new, sheet 14) |

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
1. Leedsichthys (Leedsichthys problematicus): Jurassic giant filter feeder: an enormous, long, grey-brown fish with a huge wide gaping mouth, long pectoral fins and a big forked tail.
2. Antarctic silverfish (Pleuragramma antarctica): small, slim, silvery, almost see-through, a big eye, a forked tail.
3. Emerald rockcod (Trematomus bernacchii): stocky, mottled green-brown with dark bands, a big head, wide pectoral fins.
4. Bald notothen (Pagothenia borchgrevinki): slim, silvery-grey with dark spots, a pointed head, a long second dorsal fin.

Bottom row from left:
5. Mackerel icefish (Champsocephalus gunnari): long, pale see-through grey-white with dark bands on the back, a long flat snout.
6. Marbled rockcod (Notothenia rossii): heavy, a big head, olive-brown with darker marbled patches.
7. Antarctic jonasfish (Neopagetopsis ionah): a large pale icefish with a long duck-billed snout, faint dark bands, a tall spiny first dorsal fin.
8. Leptolepis (Leptolepis coryphaenoides), Jurassic: small, slender, herring-like, silver with thin round scales.
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
