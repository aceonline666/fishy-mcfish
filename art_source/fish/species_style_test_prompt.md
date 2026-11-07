# Species style test – generation prompt

A test for one consistent species style before regenerating all sheets (README TODO: some sheets
are very comic, some very realistic; we want cute comic, and an isometric view instead of the side
view). Attach `art_source/fish/species_sheet_5.png` (the target style) and a screenshot of the open sea
(`tools/store_screenshots.gd --only=open_sea`; the game's camera: 2:1 isometric).

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

## Follow-up (2026-11-07)

The first result kept the style but drew the two "isometric" cods as tilted side views, which the
game already does with the side sprites. This follow-up gave a real view from above:

```
The style is perfect, keep it exactly. But the top two are only tilted side views. I need a real
view FROM ABOVE: the camera looks steeply down on the fish (like a drone looking down at 60
degrees), so we see the whole width of its back from above, the spotted back and the dorsal fins
seen from the top, both eyes visible on top of the head, both pectoral fins sticking out left and
right, and only a thin strip of the left flank. Redraw the same canvas: top left the cod swimming
towards the lower left in that top-down view, top right swimming towards the upper left in that
top-down view, bottom the side view as before. Fully transparent background, no checkerboard
drawn.
```

Result (ChatGPT chat "Generate cod sprites"): style right; the top views read well. ChatGPT warns
that the background may not be truly transparent (the cutters remove a checkerboard anyway).
