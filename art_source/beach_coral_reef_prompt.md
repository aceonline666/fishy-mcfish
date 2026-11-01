# Coral Reef beach tile – generation prompt

One image. Paste the prompt below and attach **two images**:

1. `beach_north_sea.png`, the **style and scale** reference (sand texture, ripple size, object
   size and density, outlines, light). The new tile replaces the North Sea placeholder the Reef
   still uses (`assets/sprites/beach/coral_reef.png` is a copy of it).
2. `seafloor_coral_reef.png`, the **palette and subject** reference (coral fragments, cowries,
   the tropical colours), so the beach and the water in front of it read as the same place.

## How the tile is used (from the code, for reference)

- `tools/make_seafloor.py` takes `art_source/beach_coral_reef.png`, scales it to 1024 × 1024 and
  writes `assets/sprites/beach/coral_reef.png`. It does **not** make it seamless, so the image
  must already tile on all four edges.
- `water.gdshader` repeats the tile every 900 ground units (`sand_tile`) in ground coordinates
  and then projects it to 2:1 isometry, so it is painted **straight from above**, not in
  isometry: anything with height or a cast shadow will look skewed in the game.
- The shader darkens the wet strip along the waterline and tints the dunes at the top of the
  beach itself, so the tile is one even dry-sand surface with no shoreline, foam or dunes.
- Pads, booths, the tank, the belt, the wader and buyers stand on it, so it stays calm and
  low in contrast: no large objects, no strong dark spots, no saturated colours that compete with
  the pad texts. The Reef's plain sand colour is `#fff0cc` (data/locations.csv).

Save the result as `art_source/beach_coral_reef.png` (square, ideally 1254 × 1254 like the
North Sea one) and run `python tools/make_seafloor.py`.

---

## Prompt

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the dry sand of a tropical coral-reef beach, seen straight from above (top-down orthographic,
camera looking straight down, no perspective, no horizon, no cast shadows that suggest a light
angle other than soft top light).

Match the painted cartoon style, the fine outline weight, the sand grain, the size of the
wind ripples and the size and spacing of the scattered objects of the attached North Sea beach
tile exactly. Take the colours of the coral pieces and shells from the attached coral-reef
seabed tile, but much paler and sun-bleached, because these are washed up and dry.

Sand: very pale, warm, almost white coral sand (base colour around #fff0cc, lighter than the
North Sea sand), fine sparkling grain with a few tiny pink and cream specks of crushed shell.
Soft, shallow wind ripples running diagonally across the whole tile, low contrast.

Scattered on the sand, small and flat, evenly spread with plenty of empty sand between them,
no clusters and no item near the edges larger than the rest:
- bleached white and pale pink branching coral fragments, lying flat
- cowrie shells, small conch and cone shells, pale scallop shells
- tiny smooth coral pebbles and a few pieces of pale pumice
- a few dried brown-green seagrass blades and one or two small coconut-husk fibres
No starfish larger than a shell, no living coral, no plants standing upright, no footprints,
no water, no wet sand, no foam, no shoreline, no dunes, no palm trees, no driftwood logs,
no man-made objects, no text.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects crossing an edge continuing on the opposite side.
Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```
