# South Africa beach and seafloor tiles – generation prompts

Two images, one prompt each. South Africa is the Cape coast, where the cold Benguela and the warm
Agulhas currents meet: kelp forests of sea bamboo, rounded granite boulders, mussel beds and
colourful anemones. Its zones start with a kelp forest, then the sardine run and shark alley
(data/zones.csv). The location colours are sand `#f2e2bc` and water `#4ec2b8` to `#0a466e`
(data/locations.csv).

Today the beach is the plain sand colour `#f2e2bc` with the tile grid, and the seabed is a small
patch cut from `seafloor_sheet.png` by `tools/make_seafloor.py`.

## How the tiles are used (from the code, for reference)

- `tools/make_seafloor.py` takes `art_source/ground/beach_south_africa.png` and
  `art_source/ground/seafloor_south_africa.png` when they exist, scales each to 1024 × 1024 and writes
  `assets/sprites/beach/south_africa.png` and `assets/sprites/seafloor/south_africa.png`. It
  does **not** make them seamless, so each image must already tile on all four edges.
- `water.gdshader` repeats both tiles every 900 ground units in ground coordinates and projects
  them to 2:1 isometry, so they are painted **straight from above**, not in isometry.
- Beach: the shader darkens the wet strip at the waterline and tints the dunes itself, so the
  tile is even dry sand. Pads, booths, the tank and the wader stand on it, so it stays calm and
  low in contrast.
- Seafloor: it shows through the water, clearly in the shallows and fading into the water colour
  (`#4ec2b8` to `#0a466e`) with depth, and fish swim over it. It can be richer than the beach,
  but it should not be so busy that the fish get lost on it.

Save as `art_source/ground/beach_south_africa.png` and `art_source/ground/seafloor_south_africa.png` (square,
ideally 1254 × 1254 like the others) and run `python tools/make_seafloor.py`.

---

## Beach

Attach `beach_north_sea.png` (style, scale, density) and `beach_australia.png` (how a warmer
sand and the shells were handled).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the dry sand of a beach on the Cape coast of South Africa, seen straight from above
(top-down orthographic, camera looking straight down, no perspective, no horizon, soft top light).

Match the painted cartoon style, the fine outline weight, the sand grain, the size of the
wind ripples and the size and spacing of the scattered objects of the attached beach tiles
exactly.

Sand: pale, bright cream-white quartz sand (base colour around #f2e2bc), lighter and cleaner
than the Australian sand, fine grain with a few soft beige and pale grey specks. Soft, shallow
wind ripples running diagonally across the whole tile, low contrast.

Scattered on the sand, small and flat, evenly spread with plenty of empty sand between them,
no clusters and no item near the edges larger than the rest:
- pale pansy shells (flat round sand dollars with a five-petal pattern)
- empty blue-black mussel shells and smooth white wedge-shaped clam shells
- small plough shells and a few big round turban shells in orange-brown
- short dried pieces of sea bamboo kelp: dark brown tubes and flat amber blade strips
- smooth grey and pinkish granite pebbles
No starfish larger than a shell, no plants standing upright, no footprints, no water, no wet
sand, no foam, no shoreline, no dunes, no driftwood logs, no man-made objects, no text.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects crossing an edge continuing on the opposite side.
Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```

---

## Seafloor

Attach `seafloor_australia.png` (style, scale, density) and `seafloor_north_sea.png` (how a
colder sea was handled).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the shallow seabed of a kelp forest on the Cape coast of South Africa, a cool temperate sea,
seen straight from above (top-down orthographic, camera looking straight down, no perspective,
no horizon, soft top light, no water surface, no light rays, no fish).

Match the painted cartoon style, the fine outline weight, the sand texture and ripples and the
size and spacing of the objects of the attached seafloor tiles exactly.

Ground: pale cream sand with soft ripples, broken up by smooth, rounded granite boulders and low
rock shelves in warm grey and pinkish beige.

Scattered, small to medium, evenly spread, with sand showing between them:
- sea bamboo kelp holdfasts with a few long golden-brown fronds lying flat in one direction
- small beds of blue-black mussels on the rocks
- tiny clusters of jewel anemones in pink, orange and lilac, pink coralline algae crusts
- purple sea urchins, small red and orange spiny sea stars, a yellow sea cucumber
- big orange-brown turban shells and abalone shells on the rocks
No tropical hard corals, no bright coral reef colours, no anemone fish, no animals other than the
ones listed, no tall plants standing upright, no wrecks, no man-made objects, no text.

Colours about as cool as the Australian tile, with warmer pink granite: golden browns, olive
greens, warm greys, with small accents of pink, orange, lilac and purple.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects crossing an edge continuing on the opposite side.
Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```
