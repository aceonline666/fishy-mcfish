# Gear shop display sprites – generation prompts

The props behind the pads in the gear shop (`UpgradeStore.FIXTURES`), one image each. Each stands
on one cell against a wall and shows what its pad sells. They are separate sprites, not part of
the room painting, because the wader can walk behind the ones on the west wall.

This file has the net display (behind "Net", cell 0,−2) and the gear display (behind "Diving
gear", cell 0,−4), both against the **west wall**, and the tank display (behind "Bigger tank",
cell 1,−7) against the **north wall**, the drone pile (beside "Buy drone") and the basket pile (beside
"Bigger basket"), standing **free** in the room's open east side, and the selling space display (behind "More selling
space", around 3.5,−6.5, against the **north wall**), replacing the placeholder desk.

Attach **three images** to each prompt:

1. `art_source/store/room.png`, the **style** reference (the room they stand in: outlines,
   palette, wood, light).
2. `art_source/props/gear_sprite_sheet.png`, the **item** reference: the six landing nets and the
   six pieces of diving gear as they look in the game.
3. `fixture_perspective_guide.png` (west wall) or `fixture_perspective_guide_north.png` (north
   wall), the **layout** reference (angle, footprint, wall, height). Its colours, grid and dashed
   lines are only markers, not part of the art. Regenerate both with
   `python tools/make_fixture_guide.py art_source/store`.

The tank display takes `art_source/tanks/tank_3.png` as its item reference instead of the sheet.

## Geometry (from the code, for reference)

- One cell, 240 × 240 ground units. In 2:1 isometry ground x runs down-right on screen and ground
  y down-left (`Iso`). The west wall stands on the footprint's **upper-left edge** (back corner to
  left corner); the room, and the pad in front of the display, lie towards the **lower right**.
  The north wall stands on the **upper-right edge** (back corner to right corner); the room lies
  towards the **lower left**.
- Scale: **240 px per cell edge (240 across, 120 down)** on a 1024 × 1024 canvas, the same as the
  level 1 tank. The engine scales the sprite to the cell (`Grid.fit_scale`).
- At most 360 px tall, below the room's wall (about 430 px at this scale).

| Point | Pixel (x, y) |
|---|---|
| Footprint: left / bottom / right / back corner | (272, 760) / (512, 880) / (752, 760) / (512, 640) |
| Footprint centre (sprite anchor) | (512, 760) |
| Highest point allowed (360 px): left / bottom / right / back corner | (272, 400) / (512, 520) / (752, 400) / (512, 280) |

The paintings rarely keep to this canvas, so each is fitted by hand: `tools/import_store_art.py`
crops it into `assets/sprites/props/` and shifts a measured point by the crop. Its `FIXTURES`
entry in `upgrade_store.gd` gives where it stands on the floor, in cells and free of the grid
(placed where it looks good), the point in the sprite that stands there (its foot) and the
sprite's pixels per cell edge across (its scale). The room's painted walls are thick and stand
about a quarter cell inside the grid's room edge, so a display keeps its back about 0.3 cell off
the room's edge, or it seems to stand in the wall (or, for a tall rack, to hang in the air).
As placed:

| Display | Painting | Foot in the sprite (cropped) | Stands at (cells) | Px per cell edge |
|---|---|---|---|---|
| Gear rack | `gear_display.png` | (652, 873), middle of the rack's back foot line | (0.6, −3.75) | 430 |
| Net barrel | `net_display.png` | (628, 1102), the barrel's foot | (0.75, −1.75) | 600 |
| Tank parts | `tank_display.png` | (635, 808), the platform's middle | (0.75, −6.33) | 590 |
| Drone pile | `drone_display.png` | (625, 812), the pallet's middle | (6.6, −1.5), on the drone pad's row, east of it | 650 |
| Basket pile | `basket_display.png` (imported with `--clear-below=100`: faint halo) | (510, 448), the pile's floor middle | (6.55, −3.5), beside the basket pad | 650 |
| Half-built booth | `selling_display.png` (`--clear-below=100`; painted running along the west wall, so drawn mirrored) | (457, 772), between the posts' feet | (3.5, −6.6), against the north wall | 560 |

---

## Prompt: net display (net barrel)

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached shop room exactly. Use ONLY its style: do not
draw the room, its walls or its floor.

Subject: a shop display of LANDING NETS for sale: a sturdy old wooden barrel with dark iron hoops,
standing on the floor, with the six landing nets of the attached item sheet standing in it,
handles down inside the barrel, their net hoops up and fanned out a little in different
directions, like umbrellas in a stand. Copy the six nets from the item sheet: the plain wooden
one, the grey metal one, the blue, the green, the gold-yellow and the red one, each with its
mesh bag. A small coil of rope leaning against the barrel's foot.

Seen in strict 2:1 isometric (dimetric) projection, the same camera angle as the attached room:
horizontal edges rise or fall at exactly 1 pixel up for every 2 pixels across (26.57°), all
vertical edges perfectly vertical, no perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1024 × 1024 px.
The display stands on a one-cell floor diamond with its corners at left (272, 760),
bottom (512, 880), right (752, 760), back (512, 640). A wall (green in the guide, NOT drawn)
stands along its upper-left edge, so the barrel stands slightly towards that edge and the nets
lean out towards the viewer and the lower right, into the room. The barrel is about 180 px tall
and fills about two thirds of the diamond's width; nothing reaches outside the diamond at floor
level, and nothing rises above the dashed box, 360 px above the floor (top corner (512, 280)).

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the display itself.

Do not draw: the floor, a floor tile, a wall, cast shadows beyond a soft contact shadow right
under the barrel, people, fish, text, letters, numbers or price tags anywhere, a border or frame.
The guide's coloured faces, grid lines and dashed lines must not appear. One display only,
nothing cropped.
```

## Prompt: gear display (diving gear rack)

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached shop room exactly. Use ONLY its style: do not
draw the room, its walls or its floor.

Subject: a shop display of DIVING GEAR for sale: a sturdy wooden clothes rack with a top shelf,
standing with its back against a wall, showing the diving gear of the attached item sheet:
- hanging from the rail: the yellow fishing waders with their shoulder straps, and the orange
  hard-hat diving suit;
- on the top shelf: the round brass diving helmet with its small windows, and the blue snorkel
  mask with its snorkel;
- standing on the floor in front of the rack: the twin yellow scuba tanks and the black-and-green
  rebreather.
Copy the items' shapes and colours from the item sheet. Leave out the submersible.

Seen in strict 2:1 isometric (dimetric) projection, the same camera angle as the attached room:
horizontal edges rise or fall at exactly 1 pixel up for every 2 pixels across (26.57°), all
vertical edges perfectly vertical, no perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1024 × 1024 px.
The display stands on a one-cell floor diamond with its corners at left (272, 760),
bottom (512, 880), right (752, 760), back (512, 640). A wall (green in the guide, NOT drawn)
stands along its upper-left edge: the rack runs parallel to that edge, its back against it, and
everything on it faces into the room, towards the viewer and the lower right. The rack is about
330 px tall; the tanks stand in the front half of the diamond. Nothing reaches outside the
diamond at floor level, and nothing rises above the dashed box, 360 px above the floor
(top corner (512, 280)).

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the display itself.

Do not draw: the floor, a floor tile, a wall, cast shadows beyond a soft contact shadow right
under the rack, people or mannequin faces, text, letters, numbers or price tags anywhere, a
border or frame. The guide's coloured faces, grid lines and dashed lines must not appear. One
display only, nothing cropped.
```

## Prompt: tank display (tank parts)

Attach `room.png`, `art_source/tanks/tank_3.png` (the item reference: the tanks' posts, glass and
base) and `fixture_perspective_guide_north.png`.

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached shop room exactly. Use ONLY its style: do not
draw the room, its walls or its floor.

Subject: the PARTS FOR A BIGGER FISH TANK, waiting to be built, as a shop display: NOT a finished
tank, no water and no fish. Copy the parts from the attached aquarium exactly: its square
polished orange-wood corner posts with shiny brass end caps, its clear glass panes with light
blue edges and white glints, its wooden base. Show:
- a low wooden A-frame stand holding three or four large glass panes upright on edge, side by
  side, with a little straw packing between them;
- a bundle of four or five long corner posts with brass caps, tied with rope and leaning upright
  against the wall behind;
- on the floor in front: a short section of the wooden base with its drawer front and brass
  handle, lying loose, a small wooden toolbox with a mallet, and a rolled-up blueprint tied with
  a ribbon.
It should read as "a bigger tank comes in parts", tidy and inviting, not as a mess.

Seen in strict 2:1 isometric (dimetric) projection, the same camera angle as the attached room:
horizontal edges rise or fall at exactly 1 pixel up for every 2 pixels across (26.57°), all
vertical edges perfectly vertical, no perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1024 × 1024 px.
The display stands on a one-cell floor diamond with its corners at left (272, 760),
bottom (512, 880), right (752, 760), back (512, 640). A wall (green in the guide, NOT drawn)
stands along its UPPER-RIGHT edge: the A-frame with the glass panes runs parallel to that edge,
the posts lean against it, and the loose parts lie in the front half of the diamond, towards
the viewer and the lower left, into the room. The panes are about 240 px tall, the posts about
340 px. Nothing reaches outside the diamond at floor level, and nothing rises above the dashed
box, 360 px above the floor (top corner (512, 280)).

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the display itself.

Do not draw: the floor, a floor tile, a wall, water, fish, plants, sand, cast shadows beyond a
soft contact shadow right under the parts, people, text, letters, numbers or price tags anywhere
(the blueprint shows only simple lines), a border or frame. The guide's coloured faces, grid
lines and dashed lines must not appear. One display only, nothing cropped.
```

## Prompt: drone display (drone pile)

Attach `room.png`, `art_source/props/gear_sprite_sheet.png` (the item reference: its row of six
fishing drones) and `fixture_perspective_guide_free.png`.

It stands free, east of the "Buy drone" pad (5,−2), so it is seen from the front on both sides and
kept low (240 px at this scale, one cell edge): the pads are drawn over the sprites, and a taller
pile would reach up into the pad on screen.

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached shop room exactly. Use ONLY its style: do not
draw the room, its walls or its floor.

Subject: a PILE OF FISHING DRONES for sale, a cheerful heap of the six drones from the attached
item sheet, copied in shape and colour: the small yellow one, the blue one, the lime-green one,
the red one, the bigger blue-and-white one and the big orange one with its large net basket. Each
is a small quadcopter with four propellers and a mesh net basket hanging below. They lie in a
low, loose heap on and around a flat wooden shipping pallet: the biggest at the bottom, smaller
ones on top and leaning against it, one tipped on its side, propellers and net baskets
overlapping, a couple of spare propellers and a coiled charging cable on the pallet's edge.
Every drone is clearly recognisable. Tidy enough to read as a shop display, not as junk.

Seen in strict 2:1 isometric (dimetric) projection, the same camera angle as the attached room:
horizontal edges rise or fall at exactly 1 pixel up for every 2 pixels across (26.57°), all
vertical edges perfectly vertical, no perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1024 × 1024 px.
The pile stands on a one-cell floor diamond with its corners at left (272, 760),
bottom (512, 880), right (752, 760), back (512, 640); the pallet is aligned with the diamond and
covers most of it. It stands free in the room, seen from the front on both sides, with no wall.
Keep it LOW and wide: nothing reaches outside the diamond at floor level, and nothing rises
above the dashed box, 240 px above the floor (top corner (512, 400)).

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the display itself.

Do not draw: the floor, a floor tile, a wall, cast shadows beyond a soft contact shadow right
under the pallet, people, fish, text, letters, numbers or price tags anywhere, a border or frame.
The guide's coloured faces, grid lines and dashed lines must not appear. One pile only, nothing
cropped.
```

## Prompt: basket display (basket pile)

Attach FOUR images: `room.png` (style), `art_source/characters/equipment_sprite_sheet.png` (the
item reference: its "Basket (all sizes)" row), `drone_display.png` (the drone pile, the
reference for the view, size and composition) and `fixture_perspective_guide_free.png`.

A first try (`basket_display_rejected_1.png`) came out in the wrong view: the crate faced the
viewer almost flat with its side receding steeply, the basket rims were too flat, it was a wide
scene instead of a pile on one cell, and most "baskets" were landing nets with handles. Hence
the explicit angle rules and the drone pile as an extra reference below.

Like the drone pile, it stands free in the open east side, beside the "Bigger basket" pad
(5.25,−3.5), around 6.5,−3.5, and is kept low (240 px at this scale) so the pad, drawn over the
sprites, does not cut into it. The baskets match `data/backpacks.csv`: wicker baskets and creels
growing in size, then wooden fish crates for the last two levels.

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached shop room exactly. Use ONLY its style: do not
draw the room, its walls or its floor.

Subject: a PILE OF FISH BASKETS for sale, a compact heap like a market display, built exactly
like the attached drone pile, same camera, same size on the canvas, but with baskets instead of
drones: the rectangular woven wicker baskets of the attached item sheet's "Basket" row, copied
in shape, weave and colour, in several sizes from small to large, plus one deep wicker creel
with a lid and a leather shoulder strap, and one sturdy slatted wooden fish crate with rope
handles. The crate and the biggest baskets at the bottom, smaller baskets stacked on top and
nested inside each other, all of them EMPTY. A coil of rope at the foot of the pile. Tidy enough
to read as a shop display, not as junk.
These are BASKETS, not nets: no landing nets, no mesh bags, no net rings, no handles or poles
sticking out of anything.

Camera: strict 2:1 isometric (dimetric) projection, exactly the camera of the attached room and
drone pile, looking down from high above at a corner of each box:
- every box-shaped thing (the crate, the rectangular baskets) is turned 45° so that one CORNER
  points straight at the viewer; its bottom and top edges run down-left and down-right from
  that corner at exactly 1 pixel down for every 2 pixels across (26.57°). No face is seen flat
  from the front.
- every round rim or opening is an ellipse exactly TWICE as wide as it is tall.
- all vertical edges perfectly vertical, no perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1024 × 1024 px.
The pile stands on a one-cell floor diamond with its corners at left (272, 760),
bottom (512, 880), right (752, 760), back (512, 640), and covers most of it. It stands free in
the room, seen from the front on both sides, with no wall and no pallet or platform under it.
Keep it LOW and wide: nothing reaches outside the diamond at floor level, and nothing rises
above the dashed box, 240 px above the floor (top corner (512, 400)).

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the display itself.

Do not draw: the floor, a floor tile, a wall, fish or anything inside the baskets, cast shadows
beyond a soft contact shadow right under the pile, people, text, letters, numbers or price tags
anywhere, a border or frame. The guide's coloured faces, grid lines and dashed lines must not
appear. One pile only, nothing cropped.
```

## Prompt: selling space display (half-built booth)

Attach `room.png`, `art_source/buildings/booth_row_1.png` (the item reference: the market row's
posts, counter planks and red-and-white awning) and `fixture_perspective_guide_north.png`.

It stands against the north wall behind the "More selling space" pad (3.5,−5.25), where the
placeholder desk is now, and shows what that upgrade buys: room for another booth of the market
row, still being built.

```
Game sprite for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the warm wood
textures and the light direction of the attached shop room exactly. Use ONLY its style: do not
draw the room, its walls or its floor.

Subject: a HALF-BUILT MARKET STALL, a shop display for "more selling space": one segment of the
attached market row under construction, copied in its materials: its square wooden posts, its
plank counter and its red-and-white striped awning canvas. Show:
- two wooden posts already standing, joined by the counter's frame, with only the lower few
  planks of the counter front nailed on and the rest missing;
- a neat stack of new planks lying on the floor in front of it, a few leaning against a post;
- the awning canvas still rolled up and tied with rope, lying across the top of the plank stack;
- a hammer, a saw and a small tin of nails on the planks.
It should read as "a new booth is coming", tidy and inviting, not as a mess. No fish, no
aquariums, no scale yet.

Seen in strict 2:1 isometric (dimetric) projection, the same camera angle as the attached room:
horizontal edges rise or fall at exactly 1 pixel up for every 2 pixels across (26.57°), all
vertical edges perfectly vertical, no perspective convergence, no vanishing points.

Follow the attached perspective guide for every position and size. Canvas 1024 × 1024 px.
The display stands on a one-cell floor diamond with its corners at left (272, 760),
bottom (512, 880), right (752, 760), back (512, 640). A wall (green in the guide, NOT drawn)
stands along its UPPER-RIGHT edge: the half-built stall runs parallel to that edge, its back
to the wall, its counter facing the viewer and the lower left, into the room; the plank stack
lies in the front half of the diamond. Nothing reaches outside the diamond at floor level, and
nothing rises above the dashed box, 360 px above the floor (top corner (512, 280)).

Background: fully transparent (PNG with alpha). If transparency is not possible, use a perfectly
flat, uniform magenta #FF00FF background with no gradient, no texture and no vignette, and never
use magenta or pink anywhere on the display itself.

Do not draw: the floor, a floor tile, a wall, cast shadows beyond a soft contact shadow right
under the parts, people, fish, text, letters, numbers or price tags anywhere, a border or frame.
The guide's coloured faces, grid lines and dashed lines must not appear. One display only,
nothing cropped.
```
