# Top-view sheet 11 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). In a NEW ChatGPT chat,
attach only `art_source/fish/top_view/reference_top_cod.png`, then paste the prompt (as one paragraph is fine). Save the result as
`art_source/fish/top_view/top_sheet_11.png` and cut it with
`python tools/extract_top_sheet.py 11`.

| Row | Column | Species id | Species |
|---|---|---|---|
| 1 | 1 | `southern_blue_ringed_octopus` | Southern blue-ringed octopus (Hapalochlaena maculosa) |
| 1 | 2 | `japanese_flying_squid` | Japanese flying squid (Todarodes pacificus) |
| 1 | 3 | `giant_pacific_octopus` | Giant Pacific octopus (Enteroctopus dofleini) |
| 1 | 4 | `common_octopus` | Common octopus (Octopus vulgaris) |
| 2 | 1 | `colossal_squid` | Colossal squid (Mesonychoteuthis hamiltoni) |
| 2 | 2 | `ammonite` | Ammonite (Dactylioceras commune) |
| 2 | 3 | `belemnite` | Belemnite (Passaloteuthis bisulcata) |
| 2 | 4 | `lions_mane_jellyfish` | Lion's mane jellyfish (Cyanea capillata) |

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
1. Southern blue-ringed octopus (Hapalochlaena maculosa): a small yellow-brown octopus covered in bright blue rings; from above the mantle leads, the arms trail.
2. Japanese flying squid (Todarodes pacificus): a slim red-brown squid with a triangular fin at the mantle tip; from above mantle first, the arms trailing.
3. Giant Pacific octopus (Enteroctopus dofleini): a huge red-brown octopus with wrinkly skin; from above the mantle leads, the long arms trail behind.
4. Common octopus (Octopus vulgaris): a brown-orange octopus with mottled skin; from above the mantle leads, the arms trail behind.

Bottom row from left:
5. Colossal squid (Mesonychoteuthis hamiltoni): a huge, heavy red squid with a wide mantle, big eyes and hooked arms; from above mantle first, the arms trailing.
6. Ammonite (Dactylioceras commune): Jurassic: a ribbed, coiled shell, cream-brown; from above the shell's back, short tentacles at the opening.
7. Belemnite (Passaloteuthis bisulcata): Jurassic: a squid-like body with a pointed tail end, ten short hooked arms, red-brown; from above body first, arms trailing.
8. Lion's mane jellyfish (Cyanea capillata): a big orange-red bell, masses of long hair-like tentacles. From above: the round bell seen from above (its pattern visible), the tentacles and arms trailing behind it, away from the swimming direction.
```
