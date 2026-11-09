# Ice floes – generation prompt

The ice floes drifting on the Antarctic pack ice (`IceFloes`, zone `pack_ice`). Six floes of
different shapes; the game scatters them over the zone at different sizes, so the same few floes
do not look repeated. Attach `art_source/props/gear_sprite_sheet.png` as the style reference.
Cut with

    python tools/extract_magenta_sheet.py art_source/props/ice_floes_sheet.png assets/sprites/props 3 2 ice_floe_1 ice_floe_2 ice_floe_3 ice_floe_4 ice_floe_5 ice_floe_6 --scale=0.5

then import in Godot and turn mipmaps on.

```
Sprite sheet of six floating sea-ice floes for a cozy mobile idle game about catching fish, for
the Antarctic pack ice. Match the painted cartoon style, the bold dark outline weight, the colour
palette and the light direction (from the upper left) of the attached sheet exactly.

VIEW: the same 2:1 isometric game camera as the attached sheet, looking down from above at about
30 degrees. Each floe is a flat, irregular slab of ice lying flat on the water: we mostly see its
flat top, squashed vertically to about half its width like everything in a 2:1 isometric game,
and along its front (lower) edge a thin band of its side, about 1/12 of the floe's width high,
showing the thickness of the ice down to the waterline.

Each floe: a white top with a few soft drifts of snow and pale blue shadows, a little crack or a
small ridge of pressed ice on some, the side band in icy cyan-blue with darker blue streaks, the
waterline at the bottom of the side band cut straight (the rest is under water). Rounded,
irregular outlines, like pancake ice broken from a larger sheet: no two alike, two nearly round,
two longer and lumpy, one with a bite taken out of one side, one with a small snow mound on top.

Layout: canvas 1536 x 1024 px, a grid of three columns and two rows, each cell 512 x 512 px.
Each floe is centred in its cell, about 400 px wide, and stays at least 40 px inside its cell.

Background: a perfectly flat, uniform magenta #FF00FF everywhere, with no gradient, texture,
vignette, grid lines, checkerboard or cell borders. Never use magenta or pink anywhere on the ice.
No water, no foam, no reflections, no shadows, no penguins or seals, no text, no labels, no
numbers, no frames. Six floes only, nothing cropped.
```
