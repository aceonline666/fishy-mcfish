# Species style test – generation prompt

A test for one consistent species style before regenerating all sheets (README TODO: some sheets
are very comic, some very realistic; we want cute comic, and an isometric view instead of the side
view). Attach `ref_style_sheet_5.png` (the target style) and `ref_game_view.png` (the game's
camera: 2:1 isometric, seen from above at about 30°).

## Prompt

```
Test sprite for a cozy mobile fishing game. Image 1 shows the art style I want: cute comic style,
bold dark outlines, flat colours with soft cel shading, big friendly eyes, yet every animal
recognisable to a marine biologist. Image 2 is a screenshot of the game: the camera looks down on
the sea at the 2:1 isometric angle (about 30 degrees from above).

Draw ONE species, the Atlantic cod (Gadus morhua: olive-brown back with dark spots, pale lateral
line, white belly, barbel on the chin, three dorsal fins, two anal fins), in the style of image 1,
three times on one canvas, well apart, nothing overlapping:
1. top left: swimming towards the lower left of the screen, seen from the game's isometric camera
   (we see its back and its left side, the head closer to the camera than the tail, the body
   foreshortened along the 2:1 isometric diagonal),
2. top right: the same, swimming towards the upper left (we see its back and its left side, the
   head further away from the camera than the tail),
3. bottom: plain side view, head pointing left, for comparison.

Canvas 1536 x 1024 px, fully transparent background (PNG with alpha), no shadows, no water, no
bubbles, no text, no labels, no frames.
```
