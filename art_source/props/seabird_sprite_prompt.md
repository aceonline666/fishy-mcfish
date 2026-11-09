# Seabirds – generation prompts

Now and then a seabird flies over the beach (`Seabirds`): one kind per location, a flying
reptile in the Jurassic Sea. Each bird is painted in four poses, all flying screen-left (the game
mirrors them for flying right): gliding, and three flap poses (wings up, wings level, wings
down) that the game plays in a loop while it flaps.

Four images, two birds each (one per row). A first try said "seen from above at about 50
degrees": ChatGPT drew tilted side views. The view paragraph below asks for the back and both
wings explicitly. Attach `art_source/props/gear_sprite_sheet.png` as
the style reference. Cut with `tools/extract_seabirds.py`, which lines the four poses up on the
head (its position in the gliding cell, measured by eye):

    python tools/extract_seabirds.py art_source/props/seabirds_1.png herring_gull great_frigatebird --heads=95,253/90,236
    python tools/extract_seabirds.py art_source/props/seabirds_2.png australian_pelican black_tailed_gull --heads=125,240/100,255
    python tools/extract_seabirds.py art_source/props/seabirds_3.png cape_gannet wandering_albatross --heads=80,253/80,256
    python tools/extract_seabirds.py art_source/props/seabirds_4.png rhamphorhynchus pterodactylus --heads=60,250/85,248

On `seabirds_4.png` the "wings up" poses came out with four wings; the pterosaurs use their
"wings down" sprite for it (copy `<id>_down.png` to `<id>_up.png` after cutting). Then import in
Godot and turn mipmaps on.

| Image | Row 1 | Row 2 |
|---|---|---|
| `seabirds_1.png` | herring gull (North Sea) | great frigatebird (Coral Reef) |
| `seabirds_2.png` | Australian pelican (Australia) | black-tailed gull (Japan) |
| `seabirds_3.png` | Cape gannet (South Africa) | wandering albatross (Antarctica) |
| `seabirds_4.png` | Rhamphorhynchus (Jurassic Sea) | Pterodactylus (Jurassic Sea) |

## Prompt (one per image; replace the two bird descriptions)

```
Sprite sheet of two flying seabirds for a cozy mobile idle game about catching fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette and the light
direction (from the upper left) of the attached sheet exactly. Friendly and cute, but every bird
recognisable to a bird watcher.

VIEW, most important: a 2D isometric game view FROM ABOVE, NOT a side view and NOT a tilted
three-quarter view. We look down on the bird's BACK, as from a plane above it: the body lies
flat and horizontal, head and beak pointing LEFT, tail pointing right, BOTH eyes on top of the
head, the whole back and the upper side of BOTH wings visible. The wings spread to both sides of
the body: one wing reaches UP the image (away from the camera), the other DOWN the image
(towards the camera), mirror images of each other. Like everything in a 2:1 isometric game, the
picture is squashed vertically to about half its height: the wings reaching up and down the
image look shorter than they are. No belly, no legs, no side of the body visible.

Layout: canvas 1536 x 1024 px, a grid of 4 columns and 2 rows, each cell 384 x 512 px. Row 1 is
bird 1, row 2 is bird 2. Each row shows the same bird four times, identical in size, colours and
markings, centred in its cell, the wingspan about 330 px, at least 20 px inside its cell:
Column 1 GLIDING: wings spread wide and flat, slightly bent at the wrists.
Column 2 WINGS UP: the top of the wing beat; seen from above both wings are raised towards
the camera, so they look narrower and closer together over the back, tips pointing up and down
the image.
Column 3 WINGS LEVEL: halfway down the beat, both wings spread flat to both sides, as in the
glide.
Column 4 WINGS DOWN: the bottom of the beat; both wings swept down below the body, so from above
they look shorter, the tips curving back towards the tail.

Bird 1: <description>
Bird 2: <description>

Background: a perfectly flat, uniform magenta #FF00FF everywhere, with no gradient, texture,
vignette, grid lines, checkerboard or cell borders. Never use magenta or pink anywhere on the
birds. No shadows, no water, no sky, no clouds, no text, no labels, no numbers, no frames.
Eight birds only, nothing cropped.
```

Descriptions:

- **Herring gull** (Larus argentatus): white head and body, pale silver-grey back and wings,
  black wing tips with small white spots, a yellow beak with a red spot, pink legs tucked in.
- **Great frigatebird** (Fregata minor): long, narrow, sharply bent black wings, a long deeply
  forked tail, a hooked grey beak, a small red throat pouch.
- **Australian pelican** (Pelecanus conspicillatus): big, white with black wing tips and a black
  band on the upper wing, a very long pale pink-yellow beak with its pouch, the neck folded back.
- **Black-tailed gull** (Larus crassirostris): white head and body, dark slate-grey back and
  wings with black tips, a white tail with a broad black band, a yellow beak with a red and black
  tip.
- **Cape gannet** (Morus capensis): white with black flight feathers along the wing edges and a
  black tail, a golden-yellow head, a pale blue-grey dagger beak with a black stripe down the
  throat.
- **Wandering albatross** (Diomedea exulans): very long, narrow wings, white body, white wings
  with black tips and dark trailing edges, a big pink beak.
- **Rhamphorhynchus** (Jurassic pterosaur): narrow leathery wings stretched from a long fourth
  finger, a long thin tail ending in a diamond-shaped vane, a long narrow jaw with forward-
  pointing needle teeth, brown-olive with a paler belly.
- **Pterodactylus** (Jurassic pterosaur): smaller, a short tail, broad leathery wings, a long
  slender head with a small crest, fine teeth, grey-brown.
