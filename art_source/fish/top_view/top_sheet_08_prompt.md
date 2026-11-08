# Top-view sheet 08 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_08.png`, cut it with
   `python tools/extract_top_sheet.py 8`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_08_up.png`, cut it with
   `python tools/extract_top_sheet.py 8 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `giant_oarfish` | Giant oarfish (Regalecus glesne) |
| 1 | 2 | `pelican_eel` | Pelican eel (Eurypharynx pelecanoides) |
| 1 | 3 | `blacktip_reef_shark` | Blacktip reef shark (Carcharhinus melanopterus) |
| 1 | 4 | `basking_shark` | Basking shark (Cetorhinus maximus) |
| 2 | 1 | `greenland_shark` | Greenland shark (Somniosus microcephalus) |
| 2 | 2 | `bluntnose_sixgill_shark` | Bluntnose sixgill shark (Hexanchus griseus) |
| 2 | 3 | `port_jackson_shark` | Port Jackson shark (Heterodontus portusjacksoni) |
| 2 | 4 | `great_white_shark` | Great white shark (Carcharodon carcharias) |

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
1. Giant oarfish (Regalecus glesne): a very long ribbon-like silver fish with a red crest on its head and a red fin running along the whole back. From above: a long, slim body in a gentle S-curve.
2. Pelican eel (Eurypharynx pelecanoides): a black deep-sea eel with an enormous pelican-like mouth pouch and a long whip tail with a glowing tip. From above: a long, slim body in a gentle S-curve.
3. Blacktip reef shark (Carcharhinus melanopterus): grey-brown with black tips on all fins. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
4. Basking shark (Cetorhinus maximus): huge, grey-brown, an enormous wide open mouth, long gill slits around the head. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.

Bottom row from left:
5. Greenland shark (Somniosus microcephalus): heavy, grey-brown, a short rounded snout, small fins, small eyes. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
6. Bluntnose sixgill shark (Hexanchus griseus): dark brown-grey, a blunt snout, green eyes, one dorsal fin far back. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
7. Port Jackson shark (Heterodontus portusjacksoni): small, a blunt bulldog head with ridges over the eyes, a dark harness-like pattern on a light brown body. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
8. Great white shark (Carcharodon carcharias): big, grey back, white belly, a pointed snout, black eyes. From above: the wide flat head and snout, both pectoral fins spread like wings, the first dorsal fin seen from above along the back, the tail fin trailing.
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
