# Sales belt sprite – generation prompt

The conveyor belt on the beach (`SalesBelt`) that carries the grown fish, each in its glass, from
the tank up the beach to the booths. Its length changes (a bigger tank leaves less belt, every
seller adds a cell), so it is painted like the pier: one painting four sections long, cut into the
tank end, a section that repeats and the booth end (`tools/cut_belt.py`).

One image. Paste the prompt below and attach **two images**:

1. `art_source/buildings/pier.png`, the **style and layout** reference: a long structure running
   diagonally up the canvas with distinct ends and evenly spaced posts.
2. `art_source/buildings/gear_shop.png`, the **style** reference (outlines, palette, light).

## Geometry (from the code, for reference)

- The belt runs **north**, up the beach: on screen from the lower left (tank end, south) to the
  upper right (booth end, north), at 1 px up for 2 px across.
- It is 0.6 cell wide (`SalesBelt.WIDTH_SHARE`) and lies low: the fish glasses stand on its top.
- Painted at 4 sections (cells) of 270 px across and 135 px up each, so a cell edge is about
  302 px on screen; the belt is about 180 px wide across the run.

| Point | Pixel (x, y) |
|---|---|
| Middle of the belt's top at the tank end (lower left) | (230, 790) |
| Middle of the belt's top at the booth end (upper right) | (1310, 250) |

---

## Prompt

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached pier and gear shop exactly. Use ONLY their
style: do not draw the pier or the shop.

Subject: a long, low, straight CONVEYOR BELT standing on the sand, a homemade seaside fish
conveyor built from wood and old metal parts:
- a dark slate-grey rubber belt on top, with thin, evenly spaced raised cleats running across it,
  completely empty;
- framed on both long sides by weathered wooden side boards with brass bolts, a little higher
  than the belt so nothing falls off;
- under the boards, short sturdy wooden legs in pairs, one pair at the start of every section,
  evenly spaced along the whole length, with a cross brace between each pair;
- at the LOWER-LEFT end (where fish come on): a big round roller drum where the belt turns
  under, a small wooden crank box with a red-painted hand crank and a few gears on its side;
- at the UPPER-RIGHT end (where fish are sold): a round roller drum where the belt turns under
  and a short wooden end stop with a little brass bell on a post.
Between the two ends the belt is perfectly uniform: every section looks the same, so a section
can be repeated.

Seen in strict 2:1 isometric (dimetric) projection, the same camera angle as the attached pier:
the belt runs diagonally from the lower left to the upper right, rising exactly 1 pixel for
every 2 pixels across (26.57°); its cleats and the ends run across it, falling 1 pixel for every
2 pixels across the other way; all vertical edges perfectly vertical, no perspective
convergence, no vanishing points, no foreshortening along its length.

Canvas 1536 × 1024 px. The middle of the belt's top runs from (230, 790) at the lower-left end
to (1310, 250) at the upper-right end, exactly four sections long, each section 270 px across
and 135 px up. The belt with its side boards is about 180 px wide across its run. Its top is
about 60 px above the sand, so it reads as a low structure; the crank and the bell post may rise
a little higher. Nothing cropped.

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the belt itself.

Do not draw: sand, ground, water, fish, glasses or anything on the belt, cast shadows beyond a
soft contact shadow under the legs, people, text, letters, numbers or price tags anywhere, a
border or frame. One belt only.
```
