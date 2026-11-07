# Seabed props for the open-water zones – generation prompt

Zone props (`SeabedDecor.ZONE_PROPS`, `src/scenes/world/seabed_decor.gd`) for the zones that had
none: Sardine run, Shark alley and the two currents (Kuroshio, Agulhas). Six props on one sheet,
cut by `tools/extract_magenta_sheet.py` into `assets/sprites/seabed`:

| Cell | Sprite | Zones |
|---|---|---|
| 1 | (`sand_ripples`, not used: they looked wrong) | |
| 2 | `sea_whips` (bent by the current) | kuroshio, agulhas_current |
| 3 | (`sardine_shoal`, not used: a painted shoal cannot swim; the Sardine run has bait balls of small sardines instead, `BaitBall`) | |
| 4 | `whale_bones` | shark_alley |
| 5 | `shark_cage` (sunken) | shark_alley |
| 6 | `red_bait` (Cape sea squirts on a rock) | shark_alley |

Paste the prompt below and attach `art_source/ground/seabed_props.png` (the style reference).

---

## Prompt

```
Sprite sheet of seabed decoration props for a cozy mobile idle game about catching fish.
Match the painted cartoon style, the bold dark outline weight, the colour palette and the light
direction (from the upper left) of the attached sheet of seabed props exactly. All props lie on
the sea floor and are seen from the same 2:1 isometric camera, slightly from above; each sits on
a small, soft patch of sand that fades out at its edges (as in the attached sheet).

Six props, one per cell:
1. SAND RIPPLES: a roughly oval patch of sand with parallel wavy ripple ridges, a few small
   shells and pebbles in the troughs.
2. SEA WHIPS: a cluster of five or six long, thin, orange and yellow sea whip corals growing from
   a small rock, all bent the same way to the right as if by a strong current.
3. SARDINE SHOAL: a dense, swirling, roughly round shoal of about forty tiny silver-blue sardines
   seen from above, all swimming in the same circular direction, with a soft dark shadow below.
4. WHALE BONES: an old, weathered whale skeleton partly sunk into the sand: a few curved ribs
   sticking up and part of the spine, pale bone with a little green growth.
5. SHARK CAGE: an old, rusty shark diving cage lying sunken on its side on the sea floor,
   a box of thick bars with an open door, a little seaweed on it.
6. RED BAIT: a low, rounded rock covered in a crowd of red-brown, lumpy sea squirts (Cape red
   bait), with a few small barnacles.

Layout: canvas 1536 × 1024 px, a grid of three columns and two rows, each cell 512 × 512 px.
Props 1, 2, 3 in the top row and 4, 5, 6 in the bottom row, left to right. Each prop is centred
in its cell, about 380 px wide, and stays at least 30 px inside its cell.

Background: a perfectly flat, uniform magenta #FF00FF everywhere, also in the gaps between ribs,
bars and corals, with no gradient, texture, vignette, grid lines, checkerboard or cell borders.
Never use magenta or pink anywhere on the props.

Do not draw: water, fish other than the sardines, text, labels, numbers, a frame. Six props only,
nothing cropped.
```
