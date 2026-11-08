# Top-view sheet 10 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Two images per sheet,
in the same ChatGPT chat so the creatures match:

1. In a NEW chat, attach only `art_source/fish/top_view/reference_top_cod.png` and paste the first prompt (as one paragraph is
   fine). Save the result as `art_source/fish/top_view/top_sheet_10.png`, cut it with
   `python tools/extract_top_sheet.py 10`.
2. In the same chat, attach `art_source/fish/top_view/reference_top_cod_up.png` and paste the second prompt. Save the result as
   `art_source/fish/top_view/top_sheet_10_up.png`, cut it with
   `python tools/extract_top_sheet.py 10 --up`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `reef_manta_ray` | Reef manta ray (Mobula alfredi) |
| 1 | 2 | `smooth_stingray` | Smooth stingray (Bathytoshia brevicaudata) |
| 1 | 3 | `giant_guitarfish` | Giant guitarfish (Rhynchobatus djiddensis) |
| 1 | 4 | `ocean_sunfish` | Ocean sunfish (Mola mola) |
| 2 | 1 | `curled_octopus` | Curled octopus (Eledone cirrhosa) |
| 2 | 2 | `giant_squid` | Giant squid (Architeuthis dux) |
| 2 | 3 | `chambered_nautilus` | Chambered nautilus (Nautilus pompilius) |
| 2 | 4 | `vampire_squid` | Vampire squid (Vampyroteuthis infernalis) |

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
1. Reef manta ray (Mobula alfredi): from above: the whole diamond-shaped black disc with white shoulder patches, wide wing tips, the two head fins in front, a short tail.
2. Smooth stingray (Bathytoshia brevicaudata): from above: the whole round grey-brown disc, the eyes on top, a long whip-like tail with a spine.
3. Giant guitarfish (Rhynchobatus djiddensis): from above: a flat, wide shark-like body with a pointed wedge-shaped snout, white spots on a sandy back, shark-like dorsal fins and tail.
4. Ocean sunfish (Mola mola): a huge, flat, round fish with a tall dorsal and anal fin and a frilly round back end instead of a tail, silver-grey; from above we see its narrow back, both fins and the edge of the round body.

Bottom row from left:
5. Curled octopus (Eledone cirrhosa): an orange-red octopus with a single row of suckers; from above: the head (mantle) leads, the eight arms trail behind, their tips curled.
6. Giant squid (Architeuthis dux): a huge red squid: from above, the long mantle with its fins leads, the eight arms and two very long tentacles trail behind.
7. Chambered nautilus (Nautilus pompilius): a coiled shell with brown-orange tiger stripes; from above the shell's back, the many short tentacles poking out at the opening.
8. Vampire squid (Vampyroteuthis infernalis): dark red-black, big blue eyes, a cloak-like web between the arms, two ear-like fins; from above, fins first, the cloak trailing.
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
