# Landing net sprites – generation prompt

The wader's six landing nets, one per net level (`Wader._draw_net`, `src/scenes/fishing/wader.gd`).
They replace `assets/sprites/wader/net_1.png` … `net_6.png`, cut from `equipment_sheet_2.png` with
the grey checkerboard still filling the mesh, in a smaller, busier style than the wader.

The code lays the hoop on the water at the catch point and stretches the handle to the hand. It
needs, per sprite, the hoop centre, the hoop width and the handle's tip (`NET_HOOP`,
`NET_HOOP_WIDTH`, `NET_TIPS`, `NET_HANDLE_START`): measure them again on the new sprites.

One image. Paste the prompt below and attach:

1. `art_source/characters/wader_zone_1.png`, the **style** reference (the wader holding the net).
2. `art_source/characters/equipment_sheet_2.png`, the old nets in its top right, for the **designs**.

## Layout

Canvas 1536 × 1024, three columns × two rows, each cell 512 × 512: nets 1–3 in the top row, 4–6
in the bottom row. In every cell the hoop is on the left, the handle runs to the lower right.

---

## Prompt

```
Sprite sheet for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette and the light
direction (from the upper left) of the attached wader character exactly. Redraw the SIX landing
nets from the top right of the attached equipment sheet, in the same order and with their
colours (1 wooden with an orange hoop, 2 dark wood, 3 red-brown, 4 steel blue-grey, 5 golden,
6 blue high-tech), but in the wader's simpler, bolder style.

Each net: a fishing landing net (hand net) with a round hoop, a mesh bag hanging below it and a
straight handle, seen from slightly above in the same 2:1 isometric camera:
- the hoop is an ellipse exactly twice as wide as tall, about 300 px wide, its centre at about
  40 % of the cell's width and 30 % of the cell's height;
- the bag hangs straight down from the hoop, rounded at the bottom, ending at about 75 % of the
  cell's height;
- the handle is straight, starts at the right end of the hoop and runs to the lower right, at
  about 30 degrees below horizontal, its end about 30 px inside the cell's right edge;
- the mesh is a clear diamond grid of thin, bold-outlined cords (about 10 diamonds across). Every
  hole of the mesh is EMPTY background: no white, grey or coloured fill behind the cords, no
  shading inside the bag. The net is empty (no fish).
The nets grow from simple (1) to fancy (6) in the hoop and handle, not in size: all six have the
same size and layout.

Layout: canvas 1536 × 1024 px, a grid of three columns and two rows, each cell 512 × 512 px.
Nets 1, 2, 3 in the top row and 4, 5, 6 in the bottom row, left to right, each inside its cell.

Background: a perfectly flat, uniform magenta #FF00FF everywhere, also in every hole of the
mesh, with no gradient, texture, vignette, grid lines, checkerboard or cell borders. Never use
magenta or pink anywhere on the nets. No shadows.

Do not draw: a person, hands, fish, water, ground, text, labels, numbers, a frame. Six nets only,
nothing cropped.
```
