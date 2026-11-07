# Seabed props for the deep zones – generation prompt

Zone props (`SeabedDecor.ZONE_PROPS`) for the deep zones, which had none. Six props on one sheet,
cut by `tools/extract_magenta_sheet.py` into `assets/sprites/seabed`:

```
python tools/extract_magenta_sheet.py art_source/ground/seabed_props_deep.png assets/sprites/seabed 3 2 black_smoker tube_worms glass_sponge sea_pens whale_fall brittle_stars
```

The black smoker also suits the deep zones of a future Antarctic location (README, "Later").

Paste the prompt below and attach `art_source/ground/seabed_props.png` (the style reference).

---

## Prompt

```
Sprite sheet of deep-sea floor decoration props for a cozy mobile idle game about catching fish.
Match the painted cartoon style, the bold dark outline weight and the light direction (from the
upper left) of the attached sheet of seabed props exactly, with colours fitting the deep sea
(dark greys, muted browns, pale bone and a few soft glowing accents). All props stand on the sea
floor, seen from the same 2:1 isometric camera, slightly from above; each sits on a small, soft
patch of dark grey silt that fades out at its edges.

Six props, one per cell:
1. BLACK SMOKER: a tall, craggy chimney of dark mineral rock with a few short side chimneys,
   puffing a thick plume of black smoke from its top (the smoke rises straight up and ends
   inside the cell), a faint orange glow at its mouth.
2. TUBE WORMS: a dense cluster of tall white tube worms with bright red plumes at their tips,
   growing from a dark rock.
3. GLASS SPONGE: a tall, vase-shaped, pale, lattice-like glass sponge (Venus' flower basket)
   standing upright, with a second smaller one beside it.
4. SEA PENS: a little group of four feather-shaped sea pens in pale orange and cream, standing
   up from the silt, softly glowing at their edges.
5. WHALE FALL: the bleached skeleton of a whale lying flat on the silt, a long spine and rows of
   ribs, covered here and there with tiny white bacterial mats and a few small crabs.
6. BRITTLE STARS: a patch of silt with seven grey-violet brittle stars with long, thin, curling
   arms, and a few small stones.

Layout: canvas 1536 × 1024 px, a grid of three columns and two rows, each cell 512 × 512 px.
Props 1, 2, 3 in the top row and 4, 5, 6 in the bottom row, left to right. Each prop is centred
in its cell, about 380 px wide, and stays at least 30 px inside its cell.

Background: a perfectly flat, uniform magenta #FF00FF everywhere, also in the gaps between ribs,
tubes and the sponge's lattice, with no gradient, texture, vignette, grid lines, checkerboard or
cell borders. Never use magenta or pink anywhere on the props.

Do not draw: water, fish, text, labels, numbers, a frame. Six props only, nothing cropped.
```
