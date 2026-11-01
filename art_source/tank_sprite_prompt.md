# Tank sprites – generation prompt

One image per tank level (7 images). Paste the **shared block** and then the block for one
level, and attach:

1. `Isometrische Fischmarkt-Stände im Set.png`, the **style** reference (outlines, palette, light);
2. `tank_<level>_perspective_guide.png`, the **layout** reference (angle, footprint proportions,
   base and glass heights). Made by `tools/make_tank_guides.py` from the table below. Without it
   the generator drew levels 1 to 3 too flat, and level 4 at the wrong proportions (its long side
   2.6 times the short one instead of 1.5) and far too flat (0.27 instead of 0.5). The first
   level 7 also came out too long (2.5 instead of 5/3), too flat (0.38) and with opaque glass, so
   check the alpha of every result;
3. optionally a finished tank (e.g. level 3) for consistency across the series.

## Geometry (from the code, for reference)

- Footprints come from `data/tanks.csv` (`width` × `depth` in cells of 240 × 240 ground units).
  The tank stands with its south-east cell at `FishingScene.TANK_CELL` and grows west, then up
  the beach (north): 1×1, 2×1, 2×2, 2×3, 3×3, 3×4, 3×5.
- In 2:1 isometry ground x runs down-right on screen and ground y down-left (`Iso`). So
  **W (east–west) is the front-left face (south)**, from the left corner down-right to the bottom
  corner, and **D (north–south) is the front-right face (east)**, from the bottom corner up-right
  to the right corner. From level 4 on the long side is the front-right face.
- Each sprite is painted in the same orientation as it stands in the game, so the engine doesn't
  need to mirror it.
- A cell edge spans **e px across and e/2 px down**, so a W × D footprint is a diamond
  e·(W+D) px wide and e·(W+D)/2 px high. The big tanks would not fit a 1536 × 1024 canvas at one
  scale, so e shrinks with the footprint. The engine scales every sprite to its footprint anyway
  (`Grid.fit_scale`). For reference, e = 240 is about 1.4 sprite px per world px, and e = 160
  about 0.9.
- Heights are designed at e = 240 and scaled with e, so all levels share one sense of size: the
  base grows from 80 to 60 px and the glass from 160 to 320 px at e = 240.

| Lvl | Name | W×D | e | Canvas | Left corner | Bottom corner | Right corner | Back corner | Base h | Glass h |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Glass tank | 1×1 | 240 | 1024×1024 | 272,760 | 512,880 | 752,760 | 512,640 | 80 | 160 |
| 2 | Large tank | 2×1 | 240 | 1024×1024 | 152,660 | 632,900 | 872,780 | 392,540 | 80 | 200 |
| 3 | Show tank | 2×2 | 240 | 1536×1024 | 288,700 | 768,940 | 1248,700 | 768,460 | 70 | 240 |
| 4 | Grand tank | 2×3 | 200 | 1536×1024 | 268,760 | 668,960 | 1268,660 | 868,460 | 60 | 215 |
| 5 | Exhibit tank | 3×3 | 200 | 1536×1024 | 168,680 | 768,980 | 1368,680 | 768,380 | 50 | 235 |
| 6 | Giant tank | 3×4 | 180 | 1536×1024 | 138,710 | 678,980 | 1398,620 | 858,350 | 45 | 225 |
| 7 | Ocean dome | 3×5 | 160 | 1536×1024 | 128,740 | 608,980 | 1408,580 | 928,340 | 40 | 215 |

Heights are vertical px above the footprint. The rim is at base h + glass h. Every tank leaves at
least about 40 px free above its back rim.

## Why the sprite is see-through

The engine draws the water, its rising level, the wavy surface, the fish, the overflow and the
puddle. The sprite is an **empty** tank whose transparency comes straight from the generator, as
a real alpha channel:

- background: alpha 0;
- glass panes: partial alpha (a faint blue tint at about 15–25 % opacity, glare streaks a bit
  stronger), so the beach, and later the water, shows through;
- frame, base and sand: opaque.

The transparency is not edited in afterwards. A magenta key could not produce half-transparent
glass. The engine draws the sprite, then the water box and the fish, then the three front corner
posts again, cut from the sprite, so they stay in front of the water. That is why the corner posts
must be straight, vertical and sit exactly on the footprint corners.

**Getting real transparency:**
- In ChatGPT, ask for "a PNG with a transparent background" in the prompt.
- Through the API (`gpt-image-1`), set `background: "transparent"` and `output_format: "png"`.

**Importing:**
- Run `tools/import_tank_art.py` on the painting. It trims and halves the image, and with two
  slopes it straightens a camera that is flatter than 2:1.
- Then set the level's footprint corners (`BASES`) and its glass box (`GLASS`: front floor corner,
  reach to the left and right, height, post half-width, how far the post's top cap reaches above
  the glass) in `tank_node.gd`.

**Check every result before using it.** Open it in an image editor and confirm it has an alpha
channel (RGBA, not RGB) and that the area around the tank is really empty. A **painted
checkerboard** in the pixels is a failed result: regenerate it, don't try to repair it. Level 1's
first attempt (`Leeres Aquarium auf Holzsockel.png`) failed this way: it is RGB with the
checkerboard painted in and seen through the glass. Its footprint is also about 1.45 : 1 instead
of square, on a 1536 × 1024 canvas instead of 1024 × 1024.

When the sprites are in, `tank_node.gd` needs these changes:
- `BASES` gets the left, bottom and right corners from the table, measured again on the final art.
- `_mirrored()` goes away.
- The flat water rectangle (`WATER_X`, `WATER_TOP`, …) becomes an isometric box between the inner
  floor and the rim.
- The front layer is drawn after the fish.

---

## Shared block (paste first)

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette and the light
direction of the attached fish-market booth sheet exactly. Use ONLY its style: do not copy its
dark vignette background or its glow halo.

Subject: an EMPTY aquarium tank on its base, seen in strict 2:1 isometric (dimetric) projection,
the same camera angle as the booths: horizontal edges rise or fall at exactly 1 pixel up for every
2 pixels across (26.57°), all vertical edges perfectly vertical, no perspective convergence, no
vanishing points.

Follow the attached perspective guide exactly for the angle, the footprint, the proportions of the
two front sides and the heights: the base fills the brown box, the glass fills the green and blue
faces, the three front corner posts stand on the black lines. The guide's colours, grid lines and
dashed lines are only markers and must not appear in the art.

The tank is a rectangular glass box with an OPEN TOP (no lid, no cover, no lamp hood) standing on
a solid base. The glass box sits exactly on the base's top face with the same outline, and the
base stands exactly on the given footprint, with nothing sticking out beyond it at ground level.
The four vertical corners of the glass are framed by slim, clearly visible corner posts, and a
slim frame band runs around the top rim and the bottom of the glass. All three front corner posts
(left, front, right) must be completely visible, straight and unbroken from base to rim.

The glass is CLEAR and EMPTY:
- NO water, no water line, no bubbles, no fish, no reflections of a room.
- Through the front glass you see only the back corner post, the back rim and the inner floor.
- At most two or three thin white glare streaks on the front panes, very subtle.

Inside, on the floor of the tank only: a low bed of sand or gravel, at most 1/6 of the glass height,
with decorations kept low and towards the back corner, so the water volume above stays open.

OUTPUT FORMAT, most important: a PNG with a REAL ALPHA CHANNEL and a TRANSPARENT BACKGROUND.
- Every pixel around the tank is fully transparent (alpha 0). Nothing is painted there.
- Do NOT paint a checkerboard pattern, a grey or white backdrop, or any "transparency preview".
  A checkerboard is only how image viewers display transparency; it must never be in the pixels.
- The glass panes are SEMI-TRANSPARENT pixels: a faint light-blue tint at about 15–25 % opacity,
  the glare streaks at about 50–70 % opacity. Whatever is placed behind the image must show
  through the glass. Do not paint any background, pattern or scenery behind or inside the glass.
- The frame, the corner posts, the base, the sand and the decorations are fully opaque.

Do not draw: ground, sand, a floor tile or boardwalk under the tank, cast shadows, pipes, conveyor
belts, hoses or pumps, text, letters, numbers, labels or price tags, people, a border or frame
around the image. One tank only, nothing cropped.
```

## Level blocks (paste one after the shared block)

### Level 1 – Glass tank (60 L), footprint 1 × 1

```
Canvas 1024 × 1024 px. Footprint: the base's ground outline is a diamond with its corners at
left (272, 760), bottom (512, 880), right (752, 760), back (512, 640). Both front sides are
EXACTLY equally long, 240 px across each: a square footprint, a cube-like tank, not a long box.
The canvas is square, 1024 × 1024, not landscape.
Base: 80 px tall, a simple weathered wooden fish crate turned upside down.
Glass: 160 px tall above the base, a plain glass box with thin black plastic corner posts and rim.
Inside: a thin layer of pale sand and two small pebbles.
Mood: humble starter tank, a bit improvised.
```

### Level 2 – Large tank (200 L), footprint 2 × 1

```
Canvas 1024 × 1024 px. Footprint diamond corners: left (152, 660), bottom (632, 900),
right (872, 780), back (392, 540). The front-LEFT side is TWICE as long as the front-right side:
a long tank whose long side faces the viewer on the left.
Base: 80 px tall, a painted wooden cabinet (sea-green paint, slightly chipped) with two small doors.
Glass: 200 px tall above the base, dark green metal corner posts and rim.
Inside: pale sand, a few pebbles and one small tuft of seaweed in the back corner.
Mood: a proper aquarium, neat and sturdy.
```

### Level 3 – Show tank (600 L), footprint 2 × 2

```
Canvas 1536 × 1024 px. Footprint diamond corners: left (288, 700), bottom (768, 940),
right (1248, 700), back (768, 460). Both front sides are equally long (a square footprint).
Base: 70 px tall, a polished warm-wood cabinet with doors on both front sides and a small blank
brass plaque.
Glass: 240 px tall above the base, polished wood corner posts and rim with brass corner caps.
Inside: sand, small rocks, two low seaweed tufts at the back.
Mood: a shop's show piece.
```

### Level 4 – Grand tank (2,000 L), footprint 2 × 3

```
Canvas 1536 × 1024 px. Footprint diamond corners: left (268, 760), bottom (668, 960),
right (1268, 660), back (868, 460). The front-RIGHT side is 1.5 times as long as the front-left
side, NOT more: the front-left side spans 400 px across and 200 px down, the front-right side
600 px across and 300 px up. Both sides slope at the same steep 2:1 angle; the long side must not
look flatter than the short side. A moderately long tank whose long side faces the viewer on the
right, not a narrow trough.
Base: 60 px tall, a plinth of light stone blocks with a darker stone top edge.
Glass: 215 px tall above the base, brushed steel corner posts and rim with small rivets.
Inside: sand, a few rounded rocks, low kelp at the back.
Mood: solid and impressive, clearly bigger and more expensive than level 3.
```

### Level 5 – Exhibit tank (6,000 L), footprint 3 × 3

```
Canvas 1536 × 1024 px. Footprint diamond corners: left (168, 680), bottom (768, 980),
right (1368, 680), back (768, 380). Both front sides are equally long (a square footprint).
Base: 50 px tall, a deep-blue painted steel platform with a single step running along both
front sides.
Glass: 235 px tall above the base, thick deep-blue steel corner posts and rim, chunky bolts.
Inside: sand with a low reef of coral rocks along the back walls.
Mood: a museum exhibit.
```

### Level 6 – Giant tank (20,000 L), footprint 3 × 4

```
Canvas 1536 × 1024 px. Footprint diamond corners: left (138, 710), bottom (678, 980),
right (1398, 620), back (858, 350). The front-RIGHT side is 4/3 as long as the front-left side.
Base: 45 px tall, a concrete plinth faced with small blue-and-white tiles.
Glass: 225 px tall above the base, massive white-painted steel corner posts and rim, with one
extra slim vertical post halfway along each front side.
Inside: sand, a low rock arch in the back corner, scattered shells.
Mood: a public-aquarium pool, wide and grand.
```

### Level 7 – Ocean dome (60,000 L), footprint 3 × 5

```
Canvas 1536 × 1024 px. Footprint diamond corners: left (128, 740), bottom (608, 980),
right (1408, 580), back (928, 340). The front-RIGHT side is 5/3 as long as the front-left side,
NOT more: the front-left side spans 480 px across and 240 px down, the front-right side 800 px
across and 400 px up. Both sides slope at the same steep 2:1 angle; the long side must not look
flatter than the short side. A long tank, but clearly wider than a narrow trough: from the front
corner, the left side reaches more than half as far as the right side.
The glass must be SEMI-TRANSPARENT in the PNG's alpha channel (about 15–25 % opacity), exactly as
in the shared block: do not paint the glass as an opaque light-blue surface. Through it, whatever is
behind the image must show.
Base: 40 px tall, a white marble plinth with a brass band.
Glass: 215 px tall above the base, ornate white-and-brass corner posts and rim, with slim brass
intermediate posts dividing each front side into equal panes.
Crown: on the BACK edges only (behind the open top, never above the front rim), a low arched
brass-ribbed glass canopy rising at most 40 px above the rim, which gives the tank its dome look.
The water area stays a straight-walled box below the rim.
Inside: a colourful low coral reef along the back walls, sand in front.
Mood: the crown jewel, grand and festive.
```
