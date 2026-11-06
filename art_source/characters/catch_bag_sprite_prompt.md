# Catch bag sprite – generation prompt

From the third zone on the diver swims with a tank on the back, so the catch can no longer stack
on a backpack basket. It goes into a mesh catch bag the diver tows on a short line (`Wader`,
`TOW_FROM_GEAR`); the caught fish poke out of its opening.

One image. Attach `art_source/characters/wader_zone_3.png` as the **style** reference (the diver
who tows it). Cut with `python tools/import_store_art.py art_source/characters/catch_bag.png
assets/sprites/wader/catch_bag.png --clear-below=100`.

## Prompt

```
Game sprite for a cozy mobile game about catching fish. Match the painted cartoon style, the
bold dark outline, the colours and the light of the attached diver sheet exactly. Use only its
style: do not draw the diver.

Subject: a diver's CATCH BAG, seen from slightly above in 2:1 isometric view: a round, bulging
bag of sturdy ORANGE NETTING with a fine mesh, hanging from a round brass ring at its top. The
ring is the bag's open mouth and is seen from above as an ellipse exactly twice as wide as it is
tall; inside it the bag is dark and EMPTY. A short coil of yellow tow rope with a metal snap
hook is tied to the ring on the left. The bag is about as wide as it is tall and fills about
two thirds of the canvas, centred; the ring is about 360 px wide.

Canvas 1024 × 1024 px, fully transparent background (PNG with alpha). One bag only, no fish,
no water, no bubbles, no shadow, no text, no frame, nothing cropped.
```
