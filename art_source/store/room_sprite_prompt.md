# Gear shop room sprite – generation prompt

One image: the empty inside of the gear shop (`UpgradeStore`), floor and back walls only. The
shelves and the desk are separate sprites (the wader walks behind the west-wall shelves), and the
pads are drawn in code on top of the floor.

Paste the prompt below and attach **two images**:

1. `art_source/buildings/gear_shop.png`, the **style** reference (the same shop from outside:
   outlines, palette, wood, light).
2. `room_perspective_guide.png`, the **layout** reference (angle, floor, wall heights, where the
   walls stay plain). Its colours and grid lines are only markers, not part of the art.
   Regenerate it with `python tools/make_room_guide.py art_source/store`.

## Geometry (from the code, for reference)

- The room is `UpgradeStore.ROOM_SIZE`, **7 × 7 cells** (columns 0–6, rows −7…−1). A cell is
  240 × 240 ground units.
- In 2:1 isometry ground x runs down-right on screen and ground y down-left (`Iso`). So the room's
  north-west corner is the **back (top) corner**, the **north wall** runs from it down-right, the
  **west wall** down-left. The south (front-left) and east (front-right) sides are open: no wall,
  so the wader is never hidden. The door back to the beach is the middle of the south side
  (cell 3,−1).
- Scale: **100 px per cell edge (100 across, 50 down)**, so the floor diamond is 1400 × 700 px on a
  1536 × 1024 canvas. That is about 0.59 sprite px per world px; the engine scales the sprite to
  the room anyway.
- Walls 180 px tall (about 300 world px, above the shelves at about 240).

| Point | Pixel (x, y) |
|---|---|
| Floor: back / right / front / left corner | (768, 250) / (1468, 600) / (768, 950) / (68, 600) |
| Floor centre (sprite anchor, the room's middle) | (768, 600) |
| Wall tops: left / back / right end | (68, 420) / (768, 70) / (1468, 420) |
| West wall, plain behind the shelves (rows −4, −2) | from (468, 400)–(368, 450) and (268, 500)–(168, 550) up |
| North wall, plain behind shelf and desk (columns 1, 3) | from (868, 300)–(968, 350) and (1068, 400)–(1168, 450) up |
| North wall, sea chart (column 5) | left edge x 1278, y 355–455; right edge x 1358, y 395–495 |
| Doormat on the south edge (cell 3,−1) | between (368, 750) and (468, 800) |

`tools/import_store_art.py` crops the painting into `assets/sprites/props/store_room.png` and
prints its floor corners; `StoreRoom` (`store_room.gd`) scales it with `Grid.fit_scale` so the
floor covers the room's cells. A new painting's floor corners go into both. Moving a fixture means
its wall segment must stay plain, so keep the wall art sparse.

---

## Prompt

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached fishing gear shop exactly: this is the INSIDE of
that same shop. Use ONLY its style, do not draw the building from outside.

Subject: the EMPTY INTERIOR of a small seaside fishing gear shop, shown as a cut-away room: a
square wooden floor with only the two back walls standing, the two front walls removed. Seen in
strict 2:1 isometric (dimetric) projection, the same camera angle as the attached shop:
horizontal edges rise or fall at exactly 1 pixel up for every 2 pixels across (26.57°), all
vertical edges perfectly vertical, no perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1536 × 1024 px.

Floor: a diamond with its corners at back (768, 250), right (1468, 600), front (768, 950),
left (68, 600), divided in the guide into 7 × 7 square cells. Warm honey-coloured wooden
floorboards running parallel to the right-hand wall, evenly lit, calm and low in contrast:
coloured pads will be drawn on top of it later, so no rugs, no patterns, no stains, nothing
standing on the floor. Along the two open front edges the floor shows its cut edge, a 16 px thick
plank slab (the brown strip in the guide); nothing beyond it.

Walls: only the two back walls, 180 px tall, meeting at the back corner (768, 250) with a white
corner board. The left wall runs from the back corner to the left corner (68, 600), the right
wall from the back corner to the right corner (1468, 600); their tops are at (68, 420),
(768, 70) and (1468, 420). Sun-faded sea-blue painted vertical planks with white trim, a darker
wooden skirting board along the floor and a narrow wooden top rail showing the wall's thickness.
Both walls end cleanly at the front corners, cut straight down.

The ORANGE wall sections in the guide (two on the left wall, two on the right wall) must stay
PLAIN planks: shelves and a counter will stand in front of them. Decorate only the rest, and
keep it sparse:
- On the right wall, at the PURPLE rectangle: a framed old nautical sea chart with a compass rose.
- On the left wall, near the back corner: a ship's wheel or a life ring, and a small round
  porthole window with daylight.
- Near the left front end of the left wall: a hanging oil lantern.
- At the BROWN square on the front-left edge (where the door to the beach is): a small woven
  doormat lying flat on the floor, aligned with the floorboards.
Light: warm daylight, from the same direction as on the attached shop.

Background: fully transparent (PNG with alpha) outside the floor and walls. If transparency is
not possible, use a perfectly flat, uniform magenta #FF00FF background with no gradient, no
texture and no vignette, and never use magenta or pink anywhere in the room itself.

Do not draw: front walls, a ceiling or roof, furniture, shelves, a counter, crates, fishing gear
on the floor, people, cast shadows outside the room, text, letters, numbers or price tags
anywhere, a border or frame around the image. The guide's coloured faces, grid lines and outlines
must not appear. One room only, nothing cropped.
```
