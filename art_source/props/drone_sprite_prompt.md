# Drone sprites – generation prompt

The six fishing drones (`Drone`, `src/scenes/fishing/drone.gd`), one look per drone in order of
purchase. They replace `assets/sprites/props/drone_1.png` … `drone_6.png`, which were cut from
`gear_sprite_sheet.png` with the grey checkerboard still filling the gaps of the nets.

Two changes against the old sprites:

- **See-through nets**: the background must show through every mesh hole. The sheet's background
  is flat magenta so every magenta pixel can be keyed out, also the enclosed ones.
- **No propeller blades**: each rotor is an empty ring guard around a small hub. The engine draws
  the spinning blades at the hubs, so the rotors animate.

One image. Paste the prompt below and attach `art_source/props/gear_sprite_sheet.png` (the old
drones in its second row are the style and design reference).

## Layout

Canvas 1536 × 1024, three columns × two rows, each cell 512 × 512: drones 1–3 in the top row,
4–6 in the bottom row, left to right. Each drone's body centred in its cell, net below it.

---

## Prompt

```
Sprite sheet for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette and the light
direction (from the upper left) of the attached sheet exactly. Redraw the SIX fishing drones from
its second row (yellow, blue, olive green, red-white, blue-white with lights, orange-black), in
the same order, each keeping its colours and design, and with the changes below.

Each drone: a quadcopter with a rounded body and four arms, seen from slightly above in the same
2:1 isometric camera as the attached sheet, with a round fishing net hanging below the body on
short struts or ropes. The drones grow from small and simple (1) to large and high-tech (6).

Two changes against the attached drones:
1. NO PROPELLER BLADES. Each of the four rotors is an empty round ring guard (an ellipse twice as
   wide as tall, seen from above) with a small round hub at its centre and nothing else: the
   inside of each ring between the hub and the ring is EMPTY background.
2. SEE-THROUGH NETS. The net is a mesh of thin cords with a coloured hoop at its opening. Every
   hole of the mesh is EMPTY background: no white, grey or coloured fill behind the cords, no
   shading inside the net. The net is empty (no fish).

Layout: canvas 1536 × 1024 px, a grid of three columns and two rows, each cell 512 × 512 px.
Drones 1, 2, 3 in the top row and 4, 5, 6 in the bottom row, left to right. Each drone is
centred in its cell, body in the upper half, net below, and stays at least 30 px inside its cell.
Drone 1 fills about half of its cell's height, drone 6 nearly all of it.

Background: a perfectly flat, uniform magenta #FF00FF everywhere, also inside the rotor rings and
in every hole of the nets, with no gradient, texture, vignette, grid lines, checkerboard or cell
borders. Never use magenta or pink anywhere on the drones. No shadows on the ground.

Do not draw: propeller blades, motion blur, fish, water, ground, text, labels, numbers, a frame.
Six drones only, nothing cropped.
```
