# Booth row – generation prompt

The sales booths become one continuous market row instead of separate stalls: a segment per
booth that joins its neighbours seamlessly, so the row grows by one segment per hired seller
("endless wall"). It replaces `booth_1..6.png`, which were painted with the counter the other
way round and drawn mirrored (wrong light, wrong depth) and do not join (doubled posts, a sign
per cell, sawtooth outline).

Start with level 1 (Fish stall). Once a row tiles well in the game, the other shop levels get
the same prompt with a richer look.

Paste the prompt below and attach **three images**:

1. `art_source/buildings/booth_row_1.png`, the **look** reference (the first try: its counter,
   aquariums, scale and awning are liked; its size, closed back wall and camera are not).
2. `art_source/characters/cashier_sheet.png`, the **size** reference: the cashiers stand behind
   the counter and must fit under the awning.
3. `booth_row_perspective_guide.png`, the **layout** reference. Its colours, grid and dashed
   lines are only markers, not part of the art. Regenerate it with
   `python tools/make_booth_guide.py art_source/buildings`.

## Why three segments

An image generator cannot be trusted to paint a tile whose left and right edges match. So the
painting shows a run of **three identical segments** with shared posts, and the game uses only
the **middle one** (blue in the guide), cut between the centres of its two posts: its edges
then meet their neighbours by construction. The row's two ends get a post each, cut from the
painting's outer posts.

## Geometry (from the code, for reference)

- The booths stand in a line up the beach, a column east of the pier (`FishingScene.BOOTH_COLUMN`),
  one cell each. A booth's counter runs along its cell's **east edge** and faces east, to the
  buyers' queue; the seller stands behind it, on the west (pier) side.
- In 2:1 isometry ground x runs down-right on screen and ground y down-left (`Iso`). The row runs
  along ground y: on screen from the upper right down to the lower left. The counter's front
  faces the **lower right**, towards the viewer; the seller stands up-left of it.
- Scale: **300 px per cell edge (300 across, 150 down)** on a 1536 × 1024 canvas. A booth is
  0.45 cell deep (135 px across). A cashier is as tall as the wader (`Wader.FIGURE_HEIGHT`,
  216 world px against 170 world px per cell edge across): **1.27 cell edges, 381 px**. So the
  counter top is at 190 px (waist height), the awning's front edge at about 420 px (above the
  cashiers' heads), nothing above 480 px.
- Seen from this camera, a cashier standing behind the middle of a counter would be right
  behind the next front post on screen; they stand a little south of the middle instead, between
  the posts (red in the guide), and that part of the counter stays free of tall things.

| Point | Pixel (x, y) |
|---|---|
| Front posts' feet, north to south (on the cells' east corners) | (1286, 560), (986, 710), (686, 860), (386, 1010) |
| Back posts' feet (0.45 cell behind) | (1151, 492), (851, 642), (551, 792), (251, 942) |
| Counter top at the front posts (190 px) | (1286, 370), (986, 520), (686, 670), (386, 820) |
| Awning's front edge at the front posts (420 px) | (1286, 140), (986, 290), (686, 440), (386, 590) |
| Highest point at the front posts (480 px) | (1286, 80), (986, 230), (686, 380), (386, 530) |
| Cashiers' feet / heads (red) | (896, 605) / (896, 224), (596, 755) / (596, 374), (296, 905) / (296, 524) |
| Middle segment (the repeating tile) | between the posts at (986, 710) and (686, 860) |

## As built (booth_row_1.png)

`tools/import_booth_row.py` straightens the painting (its camera was a little off: the row rose
0.38 instead of 0.5, the end faces fell 0.67), cuts the middle segment along its seams (back
post's cap, awning seam, front post's middle) into `assets/sprites/props/booth_row.png` and the
two outer ends into `booth_row_south.png` and `booth_row_north.png`, each stretched to meet the
segment's seam. `Booth` draws one segment per booth, the first booth adds the south end, the last
the north end. A new painting needs its points measured again (the constants at the top of the
tool, and the anchors it prints go into `booth.gd`).

Known issues, why it is being painted again: the painting has a closed back wall behind the
aquariums, so the cashiers behind the counter cannot be seen; and it is too small for them: its
awning's front edge is about one cell edge above the floor, but a cashier as tall as the wader is
1.27, so a cashier covers the awning and the counter reaches only to their knees.

---

## Prompt

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached market row exactly, and keep its look: wooden
counter with a plank front, aquariums and a brass scale, red-and-white awning. But build it
TALLER and OPEN at the back, as described below: the attached cashiers must fit behind it.

Subject: a section of a long seaside FISH MARKET ROW: three IDENTICAL market stall segments
standing in one straight line and joined into one continuous counter under one continuous
awning, like a street of stalls that goes on beyond the picture at both ends. The three
segments must be exact copies of each other: same counter, same stripes, same display, same
details, so that any one of them could be repeated endlessly.

Seen in strict 2:1 isometric (dimetric) projection: horizontal edges rise or fall at exactly
1 pixel up for every 2 pixels across (26.57°), all vertical edges perfectly vertical, no
perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1536 × 1024 px.
The row runs from the upper right down to the lower left. Its counter front faces the viewer
and the lower right (green and blue in the guide).

- Posts: four slim square wooden posts at the front, their feet exactly at (1286, 560),
  (986, 710), (686, 860) and (386, 1010), and four at the back at (1151, 492), (851, 642),
  (551, 792) and (251, 942). Neighbouring segments SHARE the post between them: there is
  exactly one post at each join, never two side by side.
- Counter: a waist-high wooden counter along the whole front, its top 190 px above the floor
  (at (1286, 370), (986, 520), (686, 670), (386, 820) above the front posts), 135 px deep, with
  a plank front. On it, in each segment, the same LOW aquarium (no taller than 70 px) with a few
  colourful fish, and a small brass scale at the same spot in every segment, both towards the
  segment's NORTH end (its upper right), leaving the counter's southern half low and free.
- Behind the counter, between the counter and the back posts: OPEN, no back wall, no panels,
  no shelves above the counter, just the wooden floor and the back posts, so the cashiers
  standing there (red in the guide, 381 px tall, as tall as the attached cashiers) are seen from
  the waist up above the counter.
- Awning: one continuous striped canvas awning over the whole row, held by the posts, sloping
  down towards the front, its scalloped front edge 420 px above the floor (at (1286, 140),
  (986, 290), (686, 440), (386, 590) above the front posts), ABOVE the cashiers' heads.
  Red-and-white stripes running front to back, EXACTLY six stripes per segment, so the stripe
  pattern starts the same way at every post.
- Nothing rises higher than 480 px above the floor (the dashed box).
- No signs, no lanterns or flags on single segments, nothing that would make one segment
  different from the others. The row simply stops at the two outer posts at both ends, cut
  cleanly, as if it continued.

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the row itself.

Do not draw: sand, ground or a floor tile around the row, cast shadows beyond a soft contact
shadow right under the counter, people, customers, sellers, text, letters, numbers or price
tags anywhere, a border or frame. The guide's coloured faces, grid lines and dashed lines must
not appear. Nothing cropped.
```
