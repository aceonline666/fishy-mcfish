# Japan beach and seafloor tiles – generation prompts

Two images, one prompt each. Japan is the temperate Pacific coast of central Japan (Izu, Sagami
Bay), warmed by the Kuroshio current: dark volcanic rock, seaweed beds of kajime kelp and
sargassum, turban shells and sea urchins. Its zones start with a rocky shore, then a seaweed bed
and the Kuroshio current (data/zones.csv). The location colours are sand `#e6d6b8` and water
`#56c0d6` to `#0b3f7a` (data/locations.csv).

Today the beach is the plain sand colour `#e6d6b8` with the tile grid, and the seabed is a small
patch cut from `seafloor_sheet.png` by `tools/make_seafloor.py`.

## How the tiles are used (from the code, for reference)

- `tools/make_seafloor.py` takes `art_source/ground/beach_japan.png` and
  `art_source/ground/seafloor_japan.png` when they exist, scales each to 1024 × 1024 and writes
  `assets/sprites/beach/japan.png` and `assets/sprites/seafloor/japan.png`. It does **not**
  make them seamless, so each image must already tile on all four edges.
- `water.gdshader` repeats both tiles every 900 ground units in ground coordinates and projects
  them to 2:1 isometry, so they are painted **straight from above**, not in isometry.
- Beach: the shader darkens the wet strip at the waterline and tints the dunes itself, so the
  tile is even dry sand. Pads, booths, the tank and the wader stand on it, so it stays calm and
  low in contrast.
- Seafloor: it shows through the water, clearly in the shallows and fading into the water colour
  (`#56c0d6` to `#0b3f7a`) with depth, and fish swim over it. It can be richer than the beach,
  but it should not be so busy that the fish get lost on it.

Save as `art_source/ground/beach_japan.png` and `art_source/ground/seafloor_japan.png` (square, ideally
1254 × 1254 like the others) and run `python tools/make_seafloor.py`.

---

## Beach

Attach `beach_north_sea.png` (style, scale, density) and `beach_australia.png` (how a warmer
sand and the shells were handled).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the dry sand of a beach on the Pacific coast of central Japan, seen straight from above
(top-down orthographic, camera looking straight down, no perspective, no horizon, soft top light).

Match the painted cartoon style, the fine outline weight, the sand grain, the size of the
wind ripples and the size and spacing of the scattered objects of the attached beach tiles
exactly.

Sand: pale greyish beige sand (base colour around #e6d6b8), a little cooler and greyer than the
Australian sand, fine grain with scattered tiny dark grey and black volcanic specks. Soft,
shallow wind ripples running diagonally across the whole tile, low contrast.

Scattered on the sand, small and flat, evenly spread with plenty of empty sand between them,
no clusters and no item near the edges larger than the rest:
- tiny pink cherry-blossom shells (sakura-gai), thin and translucent
- small spiky turban shells (sazae) in brown and green, pale clam shells
- short dried strips of dark brown kelp and olive-green sargassum with tiny round air bladders
- round smooth black and dark grey volcanic pebbles
- a few pale sea urchin shells without spines
No starfish larger than a shell, no plants standing upright, no footprints, no water, no wet
sand, no foam, no shoreline, no dunes, no driftwood logs, no man-made objects, no glass floats,
no text.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects crossing an edge continuing on the opposite side.
Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```

---

## Seafloor

Attach `seafloor_australia.png` (style, scale, density) and `seafloor_coral_reef.png` (how the
brighter accents were handled).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the shallow rocky seabed off the Pacific coast of central Japan, a temperate sea warmed by the
Kuroshio current, seen straight from above (top-down orthographic, camera looking straight down,
no perspective, no horizon, soft top light, no water surface, no light rays, no fish).

Match the painted cartoon style, the fine outline weight, the sand texture and ripples and the
size and spacing of the objects of the attached seafloor tiles exactly.

Ground: pale grey-beige sand with soft ripples, broken up by low, flat shelves and rounded
boulders of dark grey volcanic rock, and patches of seaweed lying flat and swaying in one
direction.

Scattered, small to medium, evenly spread, with sand showing between them:
- clumps of kajime kelp: short stalks with broad, wrinkled golden-brown blades lying flat
- tufts of olive and amber sargassum with tiny round air bladders
- pink coralline algae crusts on the rocks
- purple and black sea urchins, small orange sea stars, a brown sea cucumber
- spiky turban shells (sazae) and abalone shells on the rocks, clams half in the sand
No tropical hard corals, no bright coral reef colours, no anemone fish, no animals other than the
ones listed, no tall plants standing upright, no wrecks, no man-made objects, no text.

Colours a little darker and cooler than the Australian tile because of the volcanic rock, but
still bright and friendly: slate greys, golden browns, olive greens, with small accents of pink,
purple and orange.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects crossing an edge continuing on the opposite side.
Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```
