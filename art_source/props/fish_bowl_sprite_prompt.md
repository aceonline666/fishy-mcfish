# Fish bowl sprite – generation prompt

The round fish glass that each grown fish rides in on the sales belt (`SalesBelt`), from the tank
up to the booths. It replaces the placeholder `assets/sprites/props/fish_bowl.svg`.

One image. Paste the prompt below and attach **two images**:

1. `art_source/buildings/sales_belt.png`, the **style and context** reference: the belt the bowls
   stand on (outlines, palette, light, and the size of a bowl next to the belt).
2. `art_source/tanks/tank_1.png`, the **glass** reference: how glass and water are painted
   (half-transparent glass, highlights, water colour).

## Geometry (from the code, for reference)

- The bowl is small in the game: drawn `SalesBelt.BOWL_WIDTH` = 78 px wide, so paint it large
  (about 600 px wide) for detail; it is scaled down.
- **The fish is drawn by the engine on top of the bowl**, swimming at about 42 % of the bowl's
  height from its bottom, up to 12 % of its width to either side. So the bowl must be EMPTY, and
  the water and glass must stay light enough that a fish drawn over them still reads as being
  inside. Nothing in the bowl (no pebbles, no plants) may rise above the lower fifth.
- The sprite's anchor is the **bottom centre** (the bowl's foot sits 6 px into the belt's top).
- The bowl is seen from the same 2:1 isometric camera as everything else: its rim and foot are
  ellipses exactly twice as wide as tall.

| Point | Pixel (x, y) on 1024 × 1024 |
|---|---|
| Bowl: left / right edge at its widest | (212, 560) / (812, 560) |
| Rim (opening) ellipse | centre (512, 250), 360 × 180 px |
| Foot ellipse (bottom) | centre (512, 880), 320 × 160 px |
| Water surface ellipse | centre (512, 400), 540 × 270 px |

When the sprite is in, cropped to its visible pixels into `assets/sprites/props/fish_bowl.png`
(`tools/import_tank_art.py` without slopes does the trim and scale), point `BOWL_TEXTURE` in
`sales_belt.gd` at it; `BOWL_WIDTH` keeps its on-screen size. The comment that calls the glasses a
PLACEHOLDER goes, and the TODO in the README.

---

## Prompt

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette and the light
direction of the attached conveyor belt exactly, and paint the glass and the water like the
attached glass tank. Use ONLY their style: do not draw the belt or the tank.

Subject: ONE classic round glass FISH BOWL, EMPTY of fish, standing on its own:
- a round, slightly squat glass globe with a wide circular opening at the top and a thick,
  rounded lip around it, standing on a small flat round foot;
- clear, very slightly blue-green glass, HALF-TRANSPARENT (partial alpha), with a bold dark
  outline, two or three crisp white highlight streaks on the upper left (light from the upper
  left) and a soft darker tint along the lower right edge;
- filled with clear, light turquoise water up to a bit above the middle; the water surface is a
  flat ellipse with a thin bright edge; the water is half-transparent too and light, so that a
  fish drawn on top of the bowl later still reads as being inside;
- at the very bottom only, a thin layer of a few small rounded pebbles in sand colours;
- a small cheerful touch: a thin rope tied around the bowl's neck just under the lip, ending in
  a small bow knot on the front, like a market label string (no label, no text).
The bowl is empty: no fish, no plants, no bubbles above the pebbles, nothing in the middle.

Seen in strict 2:1 isometric (dimetric) projection, slightly from above, the same camera angle
as the attached belt: the opening, the water surface and the foot are ellipses exactly TWICE as
wide as they are tall. Symmetric left to right apart from the light.

Canvas 1024 × 1024 px. The bowl is 600 px wide at its widest (from x 212 to x 812, at y 560).
The rim ellipse is centred at (512, 250), 360 × 180 px; the water surface ellipse is centred at
(512, 400), 540 × 270 px; the foot ellipse is centred at (512, 880), 320 × 160 px. Nothing reaches
outside these bounds.

Background: fully transparent (PNG with alpha), and the glass and water themselves partly
transparent, so the background shows through them. If transparency is not possible, use a
perfectly flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette,
and never use magenta or pink anywhere on the bowl itself.

Do not draw: a fish, a table, a belt, sand or ground around it, a cast shadow beyond a soft
contact shadow under the foot, a lid, a label, text, letters, numbers, a border or frame. One
bowl only, nothing cropped.
```
