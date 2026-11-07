# Species sheet 9 – generation prompt

Sprites for the well-known species on the README's "Later" list: whale shark, orca, scalloped
hammerhead, great barracuda and common bottlenose dolphin. Generated ahead of the species
themselves: they are not in `data/species.csv` yet.

Attach `art_source/fish/species_sheet_6.png` as the **style** reference. Cut with
`python tools/extract_painted.py art_source/fish/species_sheet_9.png assets/sprites/fish_painted`
once the species exist (add the sheet to `SHEETS` in the script first; all face left, the tail
fin cut off to beat, except the whales and dolphins, which beat theirs up and down and are
waved instead, like the other whales).

## Prompt

```
Same style as the attached sheet, a new sheet of five different creatures. Canvas 1536 × 1024 px,
fully transparent background (PNG with alpha). Five creatures, each on its own, well apart: no
creature touches or overlaps another, no labels, no text, no numbers, no frames, no water, no
bubbles, no shadows.

Every creature is seen exactly from the side, HEAD POINTING LEFT, its body straight and
horizontal, fins spread so their shapes read clearly.

Row 1 (full width): Whale shark (Rhincodon typus), about 1200 px long: a huge, broad, flat-headed
shark with a wide straight mouth at the very front of the snout, dark blue-grey back with a
pattern of white spots and pale stripes, white belly, long ridges along its flank, tall
crescent tail fin.
Row 2, left: Orca (Orcinus orca), about 650 px: black with the white patch behind the eye, white
belly and the grey saddle patch, a tall, straight dorsal fin, paddle-shaped flippers, the tail
flukes horizontal (seen edge-on).
Row 2, right: Scalloped hammerhead (Sphyrna lewini), about 650 px: bronze-grey shark with the
wide, flat hammer-shaped head (seen from the side, so the hammer shows as a slim bar with the eye
at its end), tall first dorsal fin, long upper tail lobe.
Row 3, left: Great barracuda (Sphyraena barracuda), about 550 px: long, slim, silver fish with a
pointed, jutting lower jaw full of sharp teeth, dark bars on the upper flank, black blotches near
the tail, forked tail fin.
Row 3, right: Common bottlenose dolphin (Tursiops truncatus), about 550 px: grey, darker on the
back, pale belly, short thick beak, curved dorsal fin, friendly look, the tail flukes horizontal
(seen edge-on).
```
