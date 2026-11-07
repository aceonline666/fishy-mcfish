# Jurassic sea beach and seafloor tiles – generation prompts

Two images, one prompt each, for the Jurassic sea location on the README's "Later" list,
generated ahead of the location (it is not in `data/locations.csv` yet). Same rules as the other
ground tiles (see `south_africa_ground_prompt.md`): painted straight from above, seamless on all
four edges, 1254 × 1254, then `python tools/make_seafloor.py` once the location exists.

Save as `art_source/ground/beach_jurassic_sea.png` and `art_source/ground/seafloor_jurassic_sea.png`.

---

## Beach

Attach `beach_north_sea.png` (style, scale, density).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the warm sand of a beach in the Jurassic period, seen straight from above (top-down
orthographic, camera looking straight down, no perspective, no horizon, soft, warm top light).

Match the painted cartoon style, the fine outline weight, the sand grain, the size of the wind
ripples and the size and spacing of the scattered objects of the attached beach tile exactly.

Sand: warm golden-ochre sand (base colour around #e8cf96), fine grain with a few rust-red and
dark specks, soft shallow wind ripples running diagonally, low contrast.

Scattered on the sand, small and flat, evenly spread with plenty of empty sand between them, no
clusters and no item near the edges larger than the rest:
- small coiled ammonite shells in cream and brown
- bullet-shaped belemnite guards (small amber-brown cones)
- small fern fronds and short cycad leaves washed up, dried green-brown
- flat grey and rust-red pebbles
No footprints, no bones, no animals, no water, no foam, no shoreline, no man-made objects, no text.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects crossing an edge continuing on the opposite side.
Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```

---

## Seafloor

Attach `seafloor_north_sea.png` (style, scale, density).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the shallow seabed of a warm Jurassic sea, seen straight from above (top-down orthographic,
camera looking straight down, no perspective, no horizon, soft top light, no water surface, no
light rays, no fish).

Match the painted cartoon style, the fine outline weight, the texture and the density of the
attached seafloor tile exactly.

Ground: pale cream lime mud and fine sand with soft ripples and a few flat limestone slabs.

Scattered on it, evenly spread with plenty of plain ground between them, nothing near the edges
larger than the rest:
- feathery stalked crinoids (sea lilies) lying on the ground, in pale orange and purple-grey
- small coiled ammonite shells
- ribbed brachiopod and oyster shells (Gryphaea, curled "devil's toenails")
- small, simple sponges and clumps of green algae
- a few sea urchins with thick club-shaped spines
No fish, no bones, no man-made objects, no text.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge. Even brightness across the whole image, no vignette.

Square image, 1254 × 1254 px, full bleed, no border.
```
