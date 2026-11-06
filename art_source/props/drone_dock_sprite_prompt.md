# Drone dock (helipad) sprite – generation prompt

The drones' landing pad on the beach, in front of the gear shop (`FishingScene.DRONE_DOCK_CELL`,
cell 8,−2). The drones start from it and deliver to it. It replaces the placeholder
`assets/sprites/props/drone_dock.svg`.

One image. Paste the prompt below and attach **two images**:

1. `art_source/buildings/gear_shop.png`, the **style** reference (outlines, palette, wood, light;
   the dock lies right in front of it).
2. `art_source/props/gear_sprite_sheet.png`, the **item** reference: its row of fishing drones,
   for the size and colours of what lands here.

## Geometry (from the code, for reference)

- One cell of the layout grid, 240 × 240 ground units. In 2:1 isometry ground x runs down-right
  on screen and ground y down-left (`Iso`).
- It lies **flat on the ground** on the floor layer (`Layers.FLOOR`): the wader walks over it and
  the drones land on it. So nothing on it may stand up more than a thin rim; anything taller
  would be drawn under the wader's feet.
- Scale: **400 px per cell edge (400 across, 200 down)** on a 1024 × 1024 canvas, for detail.
  The footprint diamond is 800 × 400 px.

| Point | Pixel (x, y) |
|---|---|
| Footprint: left / bottom / right / back corner | (112, 512) / (512, 712) / (912, 512) / (512, 312) |
| Footprint centre (sprite anchor) | (512, 512) |
| Highest point allowed (rim, 30 px) | 30 px above the footprint edges |

When the sprite is in (cropped into `assets/sprites/props/drone_dock.png`), `fishing_scene.gd`
needs `DRONE_DOCK_TEXTURE` pointed at it, `DRONE_DOCK_ANCHOR` set to the footprint centre shifted
by the crop, and the sprite scaled to the cell: the placeholder is drawn at ground scale (one
cell edge ≈ 170 px across), so a painting at 400 px per cell edge needs a scale of about 0.42
(`Grid.fit_scale` from the footprint corners).

---

## Prompt

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached gear shop exactly. Use ONLY its style: do not
draw the shop.

Subject: a small DRONE LANDING PAD on the beach, a low square wooden deck lying flat on the sand,
where the little fishing drones of the attached item sheet take off and land:
- weathered, sun-bleached wooden planks with dark nail heads, framed by a slightly darker
  wooden edge beam, a low rim only;
- on the deck, painted in chipped paint: a big yellow circle and inside it a big white "H",
  both lying flat on the planks (the H is the only letter allowed);
- small round yellow landing lights set into the deck at its four corners;
- along the two BACK edges only (upper left and upper right), lying flat: a coiled charging
  cable, a couple of rope coils and one flat wooden battery crate, all very low.
Leave the middle of the deck clear: the drones land there. No drone on it.

Seen in strict 2:1 isometric (dimetric) projection, the same camera angle as the attached shop:
horizontal edges rise or fall at exactly 1 pixel up for every 2 pixels across (26.57°), all
vertical edges perfectly vertical, no perspective convergence, no vanishing points. The deck is
a diamond on screen, the circle on it an ellipse exactly TWICE as wide as it is tall, and the H
is painted flat on the deck in the same projection, not facing the viewer.

Canvas 1024 × 1024 px. The deck's outline is a diamond with its corners at left (112, 512),
bottom (512, 712), right (912, 512), back (512, 312). Its planks run parallel to one pair of the
diamond's edges. It is FLAT: the deck's visible side faces are at most 30 px tall, and nothing on
it rises higher than that. Nothing reaches outside the diamond.

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the pad itself.

Do not draw: sand, ground, water or grass around the deck, poles, a windsock, railings, lamps on
posts or anything standing up, drones, cast shadows beyond a soft contact shadow at the deck's
front edges, people, text, letters other than the H, numbers, a border or frame. One pad only,
nothing cropped.
```
