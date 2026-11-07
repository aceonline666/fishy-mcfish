# Antarctic beach and seafloor tiles – generation prompts

Two images, one prompt each, for the Antarctic sea location on the README's "Later" list,
generated ahead of the location (it is not in `data/locations.csv` yet). Same rules as the other
ground tiles (see `south_africa_ground_prompt.md`): painted straight from above, seamless on all
four edges, 1254 × 1254, then `python tools/make_seafloor.py` once the location exists.

Save as `art_source/ground/beach_antarctica.png` and `art_source/ground/seafloor_antarctica.png`.
Both tile seamlessly; the seafloor came out sandier and warmer than the grey gravel asked for.

---

## Beach

Attach `beach_north_sea.png` (style, scale, density).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the shore of an Antarctic beach, seen straight from above (top-down orthographic, camera looking
straight down, no perspective, no horizon, soft, cool top light).

Match the painted cartoon style, the fine outline weight, the grain and the size and spacing of
the scattered objects of the attached beach tile exactly.

Ground: dark grey-brown volcanic gravel and coarse sand, with soft, irregular patches of old,
packed snow (white with pale blue shadows) covering about a third of the tile, low contrast.

Scattered on it, small and flat, evenly spread with plenty of empty ground between them, no
clusters and no item near the edges larger than the rest:
- smooth dark grey and black pebbles
- a few small pieces of clear blue-white ice
- empty white limpet shells
- a few small grey penguin feathers
- short, dried pieces of red and brown seaweed
No footprints, no animals, no water, no foam, no shoreline, no man-made objects, no text.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects and snow patches crossing an edge continuing on the
opposite side. Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```

---

## Seafloor

Attach `seafloor_north_sea.png` (style, scale, density).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the shallow seabed of the Antarctic sea, very cold and clear, seen straight from above (top-down
orthographic, camera looking straight down, no perspective, no horizon, soft top light, no water
surface, no light rays, no fish).

Match the painted cartoon style, the fine outline weight, the texture and the density of the
attached seafloor tile exactly.

Ground: grey-brown gravel and silt with scattered rounded dropstones of different sizes, and a
few patches of pale pink coralline crust on the stones.

Scattered on it, evenly spread with plenty of plain ground between them, nothing near the edges
larger than the rest:
- red and orange sea stars, some with many arms
- small white and pale yellow sponges
- a few clumps of red and dark brown seaweed lying flat
- purple-red sea urchins
- small pale anemones
No fish, no ice, no man-made objects, no text.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge. Even brightness across the whole image, no vignette.

Square image, 1254 × 1254 px, full bleed, no border.
```
