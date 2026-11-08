# Top-view sheet 01 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). In a NEW ChatGPT chat,
attach only `art_source/fish/top_view/reference_top_cod.png`, then paste the prompt (as one paragraph is fine). Save the result as
`art_source/fish/top_view/top_sheet_01.png` and cut it with
`python tools/extract_top_sheet.py 1`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `european_sprat` | European sprat (Sprattus sprattus) |
| 1 | 2 | `atlantic_herring` | Atlantic herring (Clupea harengus) |
| 1 | 3 | `atlantic_mackerel` | Atlantic mackerel (Scomber scombrus) |
| 1 | 4 | `lumpsucker` | Lumpsucker (Cyclopterus lumpus) |
| 2 | 1 | `atlantic_cod` | Atlantic cod (Gadus morhua) |
| 2 | 2 | `atlantic_wolffish` | Atlantic wolffish (Anarhichas lupus) |
| 2 | 3 | `roundnose_grenadier` | Roundnose grenadier (Coryphaenoides rupestris) |
| 2 | 4 | `rabbit_fish` | Rabbit fish (Chimaera monstrosa) |

Check before cutting: every creature seen steeply from above (both eyes, back from above), head at
the lower left, nothing touching the next cell. If one creature is wrong, ask ChatGPT to redraw
only that one, keeping everything else.

## Prompt

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
1. European sprat (Sprattus sprattus): small, slim, silvery with a blue-green back and a forked tail.
2. Atlantic herring (Clupea harengus): slim, silvery with a blue-green back, a single dorsal fin and a forked tail.
3. Atlantic mackerel (Scomber scombrus): streamlined, a green-blue back with black wavy stripes, silver sides, small finlets before the forked tail.
4. Lumpsucker (Cyclopterus lumpus): round and lumpy, grey-green with rows of bony bumps, a short tail.

Bottom row from left:
5. Atlantic cod (Gadus morhua): olive-brown back with dark spots, pale lateral line, a chin barbel, three dorsal fins (exactly as in the reference image).
6. Atlantic wolffish (Anarhichas lupus): long and heavy, blue-grey with dark bands, a big blunt head with strong teeth, one long dorsal fin.
7. Roundnose grenadier (Coryphaenoides rupestris): a big head with a rounded snout and big eyes, the body tapering into a long rat-like tail, grey-brown.
8. Rabbit fish (Chimaera monstrosa): a chimaera: a big head with huge green eyes, large wing-like pectoral fins, a tall spine on the first dorsal fin, a long whip tail, bronze with white spots.
```
