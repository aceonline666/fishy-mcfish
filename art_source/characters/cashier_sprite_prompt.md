# Cashier sprite sheet – generation prompt

The hired sellers ("cashiers") who stand behind the booth counters. One image with **three
different cashiers**, one per row, so a row of up to ten booths does not look cloned; the game
cycles through them like the pad icons (`FishingScene.CASHIER_LOOKS`, `cashier_1..3.png`).

Attach **two images**:

1. `art_source/characters/wader_zone_1.png`, the **style, size and camera** reference: the
   cashiers are exactly as tall as the wader in its cells, drawn the same way.
2. `assets/sprites/props/cashier_1.png` (and `_2`, `_3`), the small pad icons, for the cashiers'
   look (cap, apron).

## Geometry (from the code, for reference)

- The wader is `Wader.FIGURE_HEIGHT` = 216 world px tall; in its sheet a figure fills about
  285 px of a 205 × 307 px cell, feet on the cell's bottom line. The cashier sheet uses the same
  cell size and feet line, so a cashier drawn at the wader's scale is the wader's height.
- A cashier stands behind a counter that runs along the booth's east edge and faces the buyers in
  the east: on screen they face the **lower right** (a three-quarter view from the front, like the
  wader's "towards" row, but turned to the right). Only about the upper half shows above the
  counter, but the whole figure is drawn, so the counter can change.
- Canvas **1024 × 1024 px**, **5 columns × 3 rows**, cells about 205 × 341 px. Column centres x:
  102, 307, 512, 717, 922. Feet lines y: 321, 662, 1003. Figure height about 285 px.

| Column | Frame |
|---|---|
| 1 | standing, idle, hands resting on the counter height |
| 2 | standing, idle breath (shoulders slightly raised), for a two-frame idle |
| 3 | taking coins: one hand held out forward, palm up |
| 4 | handing over a fish: one arm stretched forward and to the right, holding a small clear water bag with a fish |
| 5 | happy: a short wave with one hand, smiling |

When the sheet is in, `Booth` draws the cashier from it at the wader's scale instead of the
placeholder `seller_back.svg` (`SELLER_HEIGHT` becomes `Wader.FIGURE_HEIGHT`), idle frames by
default, frames 3–5 when a fish is sold.

---

## Prompt

```
Character sprite sheet for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the shading
and the light direction of the attached wader sprite sheet exactly, and draw the figures at
EXACTLY the same size as the wader there: about 285 px from the soles to the top of the head.

Subject: three friendly fish-market CASHIERS who sell fish at a seaside market stall, one per
row, each a different person:
- Row 1: a young man with a blue baseball cap and a navy-blue apron over a white T-shirt, like
  the attached small cashier icon.
- Row 2: a young woman with a brown ponytail, a red-and-white striped apron over a light blue
  shirt, rolled-up sleeves.
- Row 3: an older man with a short white beard and a knitted navy fisherman's sweater under a
  yellow oilskin apron, a flat cap.
All three wear practical rubber boots, and have the same body proportions as the attached wader
(slightly chunky, big friendly head). Their faces and clothes stay exactly the same in all five
frames of their row.

View: every figure stands in a three-quarter view from the front, turned to face the LOWER RIGHT
of the picture (towards the viewer and to the right), face and front visible, seen from about
30° above like the wader. Same view in every cell.

Layout: canvas 1024 × 1024 px, 5 columns × 3 rows, one figure centred in each cell, column
centres at x = 102, 307, 512, 717, 922, the soles of the feet on the lines y = 321, 662 and 1003.
Columns, left to right:
1. standing idle, relaxed, hands in front at counter height;
2. the same, mid-breath, shoulders a little higher (for a two-frame idle);
3. taking coins: one hand held out forward to the lower right, palm up;
4. handing over a sold fish: one arm stretched forward to the lower right, holding a small clear
   plastic water bag tied at the top with one orange fish inside;
5. happy: waving with one raised hand, big smile.

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the figures.

Do not draw: a counter, a stall, ground, shadows, grid lines, cell borders, labels, text,
letters, numbers anywhere, a border or frame. Nothing cropped, no figure overlapping another
cell.
```
