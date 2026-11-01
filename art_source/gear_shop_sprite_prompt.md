# Gear shop sprite – generation prompt

One image. Paste the prompt below and attach **two images**:

1. `Isometrische Fischmarkt-Stände im Set.png`, the **style** reference (outlines, palette, light).
2. `gear_shop_perspective_guide.png`, the **layout** reference (angle, footprint, wall and roof
   heights, door, sign). Its colours and grid lines are only markers, not part of the art.

## Geometry (from the code, for reference)

- The shop covers 3 × 2 cells of the layout grid (`FishingScene.GEAR_SHOP_SIZE`): **3 cells
  east–west (ground x), 2 cells north–south (ground y)**. A cell is 240 × 240 ground units.
- In 2:1 isometry ground x runs down-right on screen and ground y down-left (`Iso`). So the
  **3-cell side is the front-left face (south)**, from the left corner down-right to the bottom
  corner, and the **2-cell side is the front-right face (east)**, from the bottom corner up-right
  to the right corner.
- Scale: **200 px per cell edge (200 across, 100 down)**, as for the 3 × 2 ocean dome, so the
  building fits a 1536 × 1024 canvas with room for the roof and sign. The footprint diamond is
  1000 × 500 px. That is about 1.2 sprite px per world px. The engine scales the sprite to the
  footprint anyway.
- The door is centred on the westmost cell of the south face, where the wader walks in
  (`GEAR_SHOP_DOOR_X`). The shop sign's text is drawn in code (translated), so the sign board stays
  blank and faces the viewer flat, not slanted.

| Point | Pixel (x, y) |
|---|---|
| Footprint: left / bottom / right / back corner | (268, 680) / (868, 980) / (1268, 780) / (668, 480) |
| Footprint centre (sprite anchor) | (768, 730) |
| Wall tops: left / bottom / right corner (walls 240 px) | (268, 440) / (868, 740) / (1268, 540) |
| Roof ridge, west / east end (400 px above the ground) | (468, 180) / (1068, 480) |
| Door, bottom edge (100 px across, 180 px tall) | (318, 705) to (418, 755) |
| Sign board, flat to the viewer (520 × 130 px) | x 508–1028, y 185–315 |

When the sprite is in, `gear_shop_node.gd` needs `ANCHOR = (768, 730)`, `SIGN` set to the sign
board's centre relative to the anchor (about `(0, -480)`) and its scale from these footprint
corners (`Grid.fit_scale`) instead of the placeholder's `PAINTED_SIZE`.

---

## Prompt

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached fish-market booth sheet exactly. Use ONLY its
style: do not copy its dark vignette background or its glow halo.

Subject: a FISHING GEAR SHOP, a small seaside shop building made of weathered, painted wooden
planks, seen in strict 2:1 isometric (dimetric) projection, the same camera angle as the booths:
horizontal edges rise or fall at exactly 1 pixel up for every 2 pixels across (26.57°), all vertical
edges perfectly vertical, no perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1536 × 1024 px.

Footprint: the building's ground outline is a diamond with its corners at left (268, 680),
bottom (868, 980), right (1268, 780), back (668, 480). The front-left side is 1.5 times as long
as the front-right side: a long, low building whose long side faces the viewer on the left.
The walls stand exactly on this outline, with nothing sticking out beyond it at ground level.

Walls: 240 px tall, so the wall tops are at left (268, 440), bottom (868, 740), right (1268, 540).
Sun-faded sea-blue painted planks with white trim and white corner boards, on a low stone or
timber footing.

Roof: a gable roof with the ridge running along the LONG side, from (468, 180) to (1068, 480).
The front-left roof slope is fully visible, the front-right wall ends in a triangular gable.
Red-brown wooden shingles, a slight eave overhang, a small chimney or vent near the back.

Front-left (long) wall, from left to right:
- At the far LEFT end, centred on the first third of the wall: the open entrance door, 100 px wide
  and 180 px tall, its bottom edge from (318, 705) to (418, 755). Warm light inside the doorway,
  a small striped awning over it, a doormat, a lantern beside it.
- Along the rest of the wall: two wide shop windows under a blue-and-white striped awning,
  displaying fishing rods, reels, a landing net, a tackle box and colourful floats. A couple of
  rods leaning against the wall and a wooden crate with buoys below the windows.

Front-right (short) gable wall: one small round porthole window, a fishing net with cork floats
draped across it, and a red-and-white life ring hanging on the wall.

Sign: on top of the ridge, a wide wooden sign board, 520 × 130 px, from x 508 to 1028 and y 185 to
315, held by two short posts. The board faces the viewer FLAT (its edges horizontal and vertical,
not slanted with the roof) and is completely BLANK: a plain painted cream-yellow panel with a
wooden frame and a small fish emblem at each end, no letters on it.

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the building itself.

Do not draw: ground, sand, a floor tile or boardwalk under the building, cast shadows, people,
text, letters, numbers or price tags anywhere, a border or frame around the image. The guide's
coloured faces, grid lines and dashed lines must not appear. One building only, nothing cropped.
```
