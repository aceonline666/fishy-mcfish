# Species sheet 8 – generation prompt

New sprites for the Japanese spider crab and the giant squid (the kraken). The old ones did not
animate well:

- the spider crab was painted from above with its legs spread to all sides, so the side-on body
  wave (`Motion.WAVE`) bent it like a fish;
- the giant squid had curled arms and a long tentacle looping back, so the jet squeeze
  (`Motion.JET`, the arms pulled together behind the mantle) twisted the curls.

Both are now drawn straight and side-on, the way FishArt expects (head or mantle tip to the
right after the cut, the rest trailing behind).

Attach `art_source/fish/species_sheet_6.png` as the **style** reference. Cut with
`python tools/extract_painted.py art_source/fish/species_sheet_8.png assets/sprites/fish_painted`
(add the sheet to `SHEETS` in the script first).

## Prompt

```
Same style as the attached sheet, a new sheet of two creatures. Canvas 1536 × 1024 px, fully
transparent background (PNG with alpha). Two creatures, one above the other, well apart: they do
not touch or overlap, no labels, no text, no numbers, no frames, no water, no bubbles, no shadows.

1. Top half: Japanese spider crab (Macrocheira kaempferi), seen EXACTLY FROM THE SIDE, walking to
   the RIGHT: an orange-red, knobbly, pear-shaped body in the middle, seen side-on (not from
   above); its very long, thin, white-spotted orange legs reach down and out to the front and to
   the back in a calm walking pose, the tips of all legs on one level line below the body like on
   a floor; the two long claw arms reach forward to the right. About 1100 px wide, 420 px tall.

2. Bottom half: giant squid (Architeuthis dux), seen EXACTLY FROM THE SIDE, swimming to the
   RIGHT mantle first: a long, deep red, smooth torpedo-shaped mantle with two small fins at its
   tip on the right, a huge round eye on the head behind the mantle, and the eight arms trailing
   to the LEFT in a STRAIGHT, loose, parallel bundle, plus the two long feeding tentacles lying
   straight along the bundle and ending in small clubs. Nothing is curled, coiled or looped back:
   the whole squid is straight and horizontal like a ruler, mantle tip and arm tips on one level.
   About 1300 px long.
```
