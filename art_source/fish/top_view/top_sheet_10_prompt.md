# Top-view sheet 10 – generation prompt

Part of the top-view species set (overview: `README.md` in this folder). Attach
`art_source/fish/species_style_test.png` (style and view: the cods) as image 1, then paste the
prompt. Save the result as `art_source/fish/top_view/top_sheet_10.png`.

| Row | Columns | Species id | Species |
|---|---|---|---|
| 1 | 1–2 | `reef_manta_ray` | Reef manta ray (Mobula alfredi) |
| 1 | 3–4 | `smooth_stingray` | Smooth stingray (Bathytoshia brevicaudata) |
| 2 | 1–2 | `giant_guitarfish` | Giant guitarfish (Rhynchobatus djiddensis) |
| 2 | 3–4 | `ocean_sunfish` | Ocean sunfish (Mola mola) |
| 3 | 1–2 | `curled_octopus` | Curled octopus (Eledone cirrhosa) |
| 3 | 3–4 | `giant_squid` | Giant squid (Architeuthis dux) |
| 4 | 1–2 | `chambered_nautilus` | Chambered nautilus (Nautilus pompilius) |
| 4 | 3–4 | `vampire_squid` | Vampire squid (Vampyroteuthis infernalis) |

Check before cutting: both drawings of each creature match, heads point lower left (columns 1, 3)
and upper left (columns 2, 4), no glow, nothing touches the next cell. If one creature is wrong,
ask ChatGPT to redraw only that cell pair, keeping everything else.

## Prompt

```
Top-view sprite sheet for a cozy mobile fishing game. Image 1 is the reference for both the
style AND the view: keep its art style exactly (cute comic style, bold dark outlines, flat colours
with soft cel shading, big friendly eyes, yet every animal recognisable to a marine biologist)
and draw every creature from the same steep view from above as the two top cods: the camera looks
down at about 60 degrees, so we see the whole width of the back, both eyes, fins spreading to both
sides, and only a thin strip of the left flank.

Canvas 1536 x 1024 px, fully transparent background (PNG with real alpha). A grid of 4 columns and
4 rows of 384 x 256 px cells, one creature per cell, centred, filling about 85 % of the cell along
its diagonal, never touching another cell. No glow or halo around the creatures, no shadows, no
water, no bubbles, no text, no labels, no numbers, no frames, no checkerboard.

Each row holds two creatures, each drawn twice:
- columns 1 and 2: the first creature of the row, columns 3 and 4: the second,
- columns 1 and 3: swimming towards the LOWER LEFT (head at the lower left, tail at the upper
  right, the head closer to the camera, like the top-left cod in image 1),
- columns 2 and 4: the same creature swimming towards the UPPER LEFT (head at the upper left, tail
  at the lower right, the head further from the camera, like the top-right cod in image 1).
Both drawings of a creature must match exactly in colours, markings and fins.

The creatures:
Row 1, first: Reef manta ray (Mobula alfredi): from above: the whole diamond-shaped black disc with white shoulder patches, wide wing tips, the two head fins in front, a short tail.
Row 1, second: Smooth stingray (Bathytoshia brevicaudata): from above: the whole round grey-brown disc, the eyes on top, a long whip-like tail with a spine.
Row 2, first: Giant guitarfish (Rhynchobatus djiddensis): from above: a flat, wide shark-like body with a pointed wedge-shaped snout, white spots on a sandy back, shark-like dorsal fins and tail.
Row 2, second: Ocean sunfish (Mola mola): a huge, flat, round fish with a tall dorsal and anal fin and a frilly round back end instead of a tail, silver-grey; from above we see its narrow back, both fins and the edge of the round body.
Row 3, first: Curled octopus (Eledone cirrhosa): an orange-red octopus with a single row of suckers; from above: the head (mantle) leads, the eight arms trail behind, their tips curled.
Row 3, second: Giant squid (Architeuthis dux): a huge red squid: from above, the long mantle with its fins leads, the eight arms and two very long tentacles trail behind.
Row 4, first: Chambered nautilus (Nautilus pompilius): a coiled shell with brown-orange tiger stripes; from above the shell's back, the many short tentacles poking out at the opening.
Row 4, second: Vampire squid (Vampyroteuthis infernalis): dark red-black, big blue eyes, a cloak-like web between the arms, two ear-like fins; from above, fins first, the cloak trailing.
```
