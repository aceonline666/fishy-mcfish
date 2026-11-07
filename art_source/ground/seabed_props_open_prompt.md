# Seabed props for the shallow and open-water zones – generation prompt

Zone props (`SeabedDecor.ZONE_PROPS`) for the zones that still had none: Pier shallows,
Sandbanks, Open sea, Drop-off, Open ocean, Southern Ocean and Sagami Bay. Six props on one sheet,
cut by `tools/extract_magenta_sheet.py` into `assets/sprites/seabed`:

```
python tools/extract_magenta_sheet.py art_source/ground/seabed_props_open.png assets/sprites/seabed 3 2 sand_dollars razor_clams lost_lure sea_cucumbers hermit_crab wall_sponges
```

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
1. SAND DOLLARS: a patch of sand with five flat, round, pale grey-violet sand dollars with the
   five-petal pattern on top, a few half buried.
2. RAZOR CLAMS: a patch of sand with a few long, narrow razor clam shells, some sticking upright
   out of the sand, some lying flat, and a few small holes in the sand.
3. LOST LURE: an old fishing lure (a striped wooden plug with two treble hooks) lying on the
   sand with a tangle of fishing line and a small lead sinker, a little algae on it.
4. SEA CUCUMBERS: three fat, warty, brown and orange sea cucumbers lying on the sand.
5. HERMIT CRAB: a small red hermit crab peeking out of a spiral whelk shell, next to two empty
   shells and a pebble.
6. WALL SPONGES: a rock with a crowd of colourful sponges on it: yellow tube sponges, an orange
   barrel sponge and a few small purple-blue encrusting sponges.

Layout: canvas 1536 × 1024 px, a grid of three columns and two rows, each cell 512 × 512 px.
Props 1, 2, 3 in the top row and 4, 5, 6 in the bottom row, left to right. Each prop is centred
in its cell, about 360 px wide, and stays at least 30 px inside its cell.

Background: a perfectly flat, uniform magenta #FF00FF everywhere, also in the gaps between
shells, line and hooks, with no gradient, texture, vignette, grid lines, checkerboard or cell
borders. Never use magenta or pink anywhere on the props.

Do not draw: water, fish, text, labels, numbers, a frame. Six props only, nothing cropped.
```
