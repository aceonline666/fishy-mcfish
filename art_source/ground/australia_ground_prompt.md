# Australia beach and seafloor tiles – generation prompts

Two images, one prompt each. Australia is the Great Southern Reef: cool temperate water, kelp
forests and seagrass meadows of southern Australia, not the tropical Great Barrier Reef. Its zones
start with a seagrass bay, then kelp forest and rocky reef (data/zones.csv).

Today the beach is the plain sand colour `#f0d8a8` with the tile grid, and the seabed is a small
patch cut from `seafloor_sheet.png` by `tools/make_seafloor.py`.

## How the tiles are used (from the code, for reference)

- `tools/make_seafloor.py` takes `art_source/beach_australia.png` and
  `art_source/seafloor_australia.png` when they exist, scales each to 1024 × 1024 and writes
  `assets/sprites/beach/australia.png` and `assets/sprites/seafloor/australia.png`. It does
  **not** make them seamless, so each image must already tile on all four edges.
- `water.gdshader` repeats both tiles every 900 ground units in ground coordinates and projects
  them to 2:1 isometry, so they are painted **straight from above**, not in isometry.
- Beach: the shader darkens the wet strip at the waterline and tints the dunes itself, so the
  tile is even dry sand. Pads, booths, the tank and the wader stand on it, so it stays calm and
  low in contrast.
- Seafloor: it shows through the water, clearly in the shallows and fading into the water colour
  (`#4fd0c4` to `#0f4f86`) with depth, and fish swim over it. It can be richer than the beach,
  but it should not be so busy that the fish get lost on it.

Save as `art_source/beach_australia.png` and `art_source/seafloor_australia.png` (square,
ideally 1254 × 1254 like the others) and run `python tools/make_seafloor.py`.

---

## Beach

Attach `beach_north_sea.png` (style, scale, density) and `beach_coral_reef.png` (how paler
colours were handled).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the dry sand of a cool-water beach on the southern coast of Australia, seen straight from above
(top-down orthographic, camera looking straight down, no perspective, no horizon, soft top light).

Match the painted cartoon style, the fine outline weight, the sand grain, the size of the
wind ripples and the size and spacing of the scattered objects of the attached beach tiles
exactly.

Sand: warm golden-cream quartz sand (base colour around #f0d8a8), a little warmer and more
golden than the North Sea sand, fine grain with a few darker amber specks. Soft, shallow wind
ripples running diagonally across the whole tile, low contrast.

Scattered on the sand, small and flat, evenly spread with plenty of empty sand between them,
no clusters and no item near the edges larger than the rest:
- short pieces of dried brown kelp and olive-green strings of Neptune's necklace seaweed
- white cuttlebones
- abalone shells showing their pearly blue-green inside, small turban shells, pale scallops
- round pale sea urchin shells without spines
- smooth grey and ochre pebbles
No starfish larger than a shell, no plants standing upright, no footprints, no water, no wet
sand, no foam, no shoreline, no dunes, no driftwood logs, no man-made objects, no text.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects crossing an edge continuing on the opposite side.
Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```

---

## Seafloor

Attach `seafloor_coral_reef.png` (style, scale, density) and `seafloor_north_sea.png`
(how a cooler sea was handled).

```
Seamless tileable ground texture for a cozy mobile idle game about catching and selling fish:
the shallow seabed of the Great Southern Reef off southern Australia, a cool temperate sea,
seen straight from above (top-down orthographic, camera looking straight down, no perspective,
no horizon, soft top light, no water surface, no light rays, no fish).

Match the painted cartoon style, the fine outline weight, the sand texture and ripples and the
size and spacing of the objects of the attached seafloor tiles exactly.

Ground: pale golden sand with soft ripples, broken up by patches of bright green, ribbon-like
seagrass meadow lying flat and swaying in one direction, and a few low, flat granite rock
shelves in grey and warm ochre.

Scattered, small to medium, evenly spread, with sand showing between them:
- small clumps of golden-brown kelp holdfasts with a few short fronds lying flat
- pink coralline algae crusts on the rocks
- red and orange sponges, purple sea urchins, small orange and blue sea stars
- abalone and turban shells, scallops half in the sand
No tropical hard corals, no bright coral reef colours, no anemone fish, no animals other than the
ones listed, no tall plants standing upright, no wrecks, no man-made objects, no text.

Colours cooler and a little more muted than the coral-reef tile, but still bright and friendly:
greens, golden browns, ochre, with small accents of red, orange and purple.

The image must tile perfectly: the left edge continues seamlessly into the right edge and the
top edge into the bottom edge, with objects crossing an edge continuing on the opposite side.
Even brightness across the whole image, no vignette, no lighter centre.

Square image, 1254 × 1254 px, full bleed, no border.
```
