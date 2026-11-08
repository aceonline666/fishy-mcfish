# Secrets art – generation prompts

Art for the secrets: the rare finds (`Curiosities`, `CurioFind`, the curiosities in the
Fishpedia) and the things in the dark (`DarkThings`).

## 1. Curiosities (rare finds) – `curiosities_sheet.png`

Six rare finds for a curiosities page in the Fishpedia, the message in a bottle first. Attach
`art_source/props/gear_sprite_sheet.png` as the style reference. Cut with
`python tools/extract_magenta_sheet.py art_source/props/curiosities_sheet.png <out_dir> 3 2
message_in_a_bottle old_compass pirate_coin ships_bell rubber_duck sea_glass --scale=0.4`
(writes to `assets/sprites/props`).

```
Sprite sheet of six rare finds for a cozy mobile idle game about catching fish at a beach,
shown as collectible icons. Match the painted cartoon style, the bold dark outline weight, the
colour palette and the light direction (from the upper left) of the attached sheet exactly.
Each find lies on its own, seen from the same 2:1 isometric camera, slightly from above.

1. MESSAGE IN A BOTTLE: a green glass bottle lying on its side, a cork in its neck, a rolled-up,
   yellowed paper with a red string inside, a few barnacles on the glass.
2. OLD COMPASS: a round brass pocket compass with its lid open, a little green patina.
3. PIRATE COIN: one large, worn gold doubloon with a cross stamped on it, standing slightly tilted.
4. SHIP'S BELL: a small bronze ship's bell with a rope pull, green patina and a few barnacles.
5. RUBBER DUCK: a faded yellow rubber duck, a little scuffed from its long journey at sea.
6. SEA GLASS: a small handful of smooth, frosted pieces of sea glass in green, blue and white.

Layout: canvas 1536 × 1024 px, a grid of three columns and two rows, each cell 512 × 512 px.
Finds 1, 2, 3 in the top row and 4, 5, 6 in the bottom row, left to right. Each find is centred
in its cell, about 340 px wide, and stays at least 40 px inside its cell.

Background: a perfectly flat, uniform magenta #FF00FF everywhere, with no gradient, texture,
vignette, grid lines, checkerboard or cell borders. Never use magenta or pink anywhere on the
finds. No shadows on the ground.

Do not draw: water, sand, hands, text, labels, numbers, a frame. Six finds only, nothing cropped.
```

## 2. Things in the dark – `dark_things_sheet.png`

The deep sea horror and the glowing eyes. Both are meant to be drawn faintly at the edge of the
dark in the deepest zones. Cut with `python tools/extract_dark_things.py`. Transparent background (the glow needs real alpha). Attach
`art_source/fish/species_sheet_6.png` as the style reference.

```
Same style as the attached sheet, a new sheet of things lurking in the deep sea, for a cozy
mobile idle game (eerie, but not gory). Canvas 1536 × 1024 px, fully transparent background (PNG
with alpha). No labels, no text, no numbers, no frames, no water, no bubbles.

Top two thirds: an ORIGINAL deep sea horror, a huge creature seen exactly from the side, head
pointing RIGHT, about 1400 px long: a long, eel-like black body that fades to darkness towards
the tail, a ragged mane of thin, pale fin rays along its back, a massive head with a slightly
open jaw full of long, thin, glassy needle teeth, and a row of small, cold blue-white glowing
lights along its flank. One pale, milky eye. Its colours are very dark (near black, dark
blue-grey) so it is only barely visible against a dark background; only the eye, the teeth and
the lights catch the light. It is not any existing monster or character.

Bottom third: four pairs of GLOWING EYES in the dark, each pair on its own, well apart, side by
side in a row: 1. two round, yellow-green eyes with slit pupils; 2. two small red eyes; 3. two
large, pale blue, round eyes; 4. a cluster of six tiny white eyes like a spider's. Each eye has
a soft glow around it (partial alpha) and there is nothing else: no face, no body, no outline
around the eyes.
```
