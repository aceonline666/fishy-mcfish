# Wader sprite sheets – generation prompts

Six images, one per depth zone (the outfit `Wader._gear()` picks). Zones 1, 2 and 5 walk and use
the **walk grid**. Zones 3 and 4 swim and use the **swim grid**. Zone 6 is the submarine on the
walk grid.

## Order of work

1. Generate **zone 1** first, with `diver_sheet_1.png` attached as the **style** reference only
   (outline weight, palette, shading). Repeat until all 25 cells show the same character.
2. Generate zones 2–6 with the **approved zone 1 sheet** attached as the **character and layout**
   reference, so the face, proportions, colours, grid and walk poses stay the same in every zone.
3. If a sheet drifts (details change between views), generate it one row at a time with the
   approved cells attached, and assemble the rows.

## Decisions behind the prompts

- **Painted walk frames instead of cut legs.** `WalkDraw` swings the left and the right half of a
  single frame. That only works in the front view: in profile both legs are in both halves. Each
  view gets 1 standing frame + 4 walk frames, and the game plays the frames in order.
- **Five views, painted looking screen-left; the game mirrors them for walking right.** Mirroring
  swaps left and right, so a part worn on one side changes sides when the figure turns right.
  That switch happens together with the change of view (front → towards-right), so it is hardly
  noticed. Realism wins over strict symmetry: the snorkel sits on the **character's left** side
  of the head, the side that faces the viewer in the left-facing views. One-sided parts are
  always on the character's left, so the left-facing views show them. Where it doesn't hurt
  realism, parts stay symmetric (twin regulator hoses).
- **A fixed parts list per outfit.** Each part says where it sits and in which views it can be
  seen. The prompt forbids everything else, which stops the generator from inventing backpacks,
  pouches and boxes on the back views.
- **Zones 3 and 4 swim, zone 5 walks.** From zone 3 the water is over the head
  (`SUBMERGE_DEPTH`). The scuba and rebreather divers swim lying flat, with fins instead of
  boots, a short distance above the seabed. The game draws them raised above their shadow, like
  the submarine. The hard-hat diver can't swim in that suit: he walks slowly on the seabed in
  lead boots, which also makes him feel heavy compared with the swimmers.
- **For now zones 3 and 4 walk too.** `wader_zone_3.png` and `wader_zone_4.png` are walk sheets
  (the walk grid, fins on), used until the swim sheets are made.
- **Swimmers have their own grid.** Lying flat, the diver is wider than tall in profile, so the
  swim sheets are landscape. The frames are anchored on the middle of the body, not the feet.
- **From zone 3 the basket is replaced by a towed catch bag.** The tank takes the back. A mesh bag
  floats behind the diver on a short line and holds the catch stack. The game draws it as a
  separate sprite (its own prompt at the end) because its position depends on the walking
  direction. The hard-hat diver and the submersible tow the same bag. Code change needed: the
  stack is drawn into the bag instead of at `STACK_BASE` when the gear level is 3 or higher.
- **No net, water, shadow or glow in the sheets.** The game draws the landing net, the shadow, the
  water line and the tint.

## Walk grid (zones 1, 2, 5, 6)

Canvas **1024 × 1536 px** (portrait), **5 columns × 5 rows**, each cell about 205 × 307 px.
(The generator has so far always added a sixth row, a steeper view from behind, between the
side and the away view. That's fine: `tools/extract_wader_sheet.py` skips it.)

| | Column 1 | Column 2 | Column 3 | Column 4 | Column 5 |
|---|---|---|---|---|---|
| Centre x | 102 | 307 | 512 | 717 | 922 |
| Frame | standing | walk A | walk B | walk C | walk D |

| Row | View (camera looks down on the figure from about 30° above) | Feet line y |
|---|---|---|
| 1 | **front**: walking straight towards the viewer | 287 |
| 2 | **towards**: three-quarter view, walking down-left, face and front visible | 594 |
| 3 | **side**: exact profile, walking left | 901 |
| 4 | **away**: three-quarter view from behind, walking up-left, back visible, face hidden | 1208 |
| 5 | **back**: walking straight away from the viewer | 1515 |

Walk frames: **A** left foot forward, heel down; **B** passing (feet side by side, the right foot
lifted, body highest); **C** right foot forward, heel down; **D** passing, left foot lifted.

## Swim grid (zones 3, 4)

Canvas **1536 × 1024 px** (landscape), **5 columns × 5 rows**, each cell about 307 × 205 px. The
middle of the body (the hips) sits on the cell centre.

| | Column 1 | Column 2 | Column 3 | Column 4 | Column 5 |
|---|---|---|---|---|---|
| Centre x | 154 | 461 | 768 | 1075 | 1382 |
| Frame | gliding | kick A | kick B | kick C | kick D |

| Row | View (camera looks down on the diver from about 30° above) | Centre y |
|---|---|---|
| 1 | **front**: swimming head first straight towards the viewer | 102 |
| 2 | **towards**: three-quarter view, swimming down-left | 307 |
| 3 | **side**: exact profile, swimming left | 512 |
| 4 | **away**: three-quarter view from behind, swimming up-left | 717 |
| 5 | **back**: swimming straight away from the viewer, fins towards the viewer | 922 |

Kick frames (a slow flutter kick from the hips, legs nearly straight): **A** right fin up, left
fin down; **B** fins level, passing; **C** left fin up, right fin down; **D** fins level, passing.

---

## Shared walk prompt (start of the zone 1, 2 and 5 prompts)

```
Character sprite sheet for a cozy mobile game about catching fish at the beach. Match the painted
cartoon style, the bold dark outline, the colour palette and the light from the top left of the
attached reference exactly. Use ONLY its style: no dark background, no vignette, no glow or halo
around the figures.

Canvas 1024 x 1536 px, a strict grid of 5 columns x 5 rows. One figure per cell, the same size in
every cell: about 230 px from the soles of the boots to the top of the head. In each row the boots
stand on the same horizontal line (y = 287, 594, 901, 1208, 1515), and each figure is centred on
its column (x = 102, 307, 512, 717, 922). Nothing touches or crosses a cell border.

Rows are camera views. The camera looks down on the figure from about 30 degrees above, the same
angle in every cell:
Row 1 FRONT: facing the viewer, walking straight towards the camera.
Row 2 TOWARDS: three-quarter view, body turned 45 degrees to the viewer's LEFT, face and chest
visible, walking down-left.
Row 3 SIDE: exact profile looking to the viewer's LEFT, walking left.
Row 4 AWAY: three-quarter view from behind, body turned 45 degrees to the viewer's LEFT, back
visible, face hidden, only the edge of the cheek, walking up-left.
Row 5 BACK: seen straight from behind, walking straight away from the camera.

Columns are animation frames of one walk cycle, the same in every row:
Column 1 STANDING: feet together, arms relaxed at the sides.
Column 2 WALK A: left foot forward with the heel down, right foot back, right arm forward.
Column 3 WALK B: passing pose, left leg straight carrying the weight, right foot lifted next to
it, body at its highest.
Column 4 WALK C: right foot forward with the heel down, left foot back, left arm forward.
Column 5 WALK D: passing pose, right leg straight carrying the weight, left foot lifted next to
it, body at its highest.
Steps are small and calm (a short, sturdy stride). Hands are empty and open; they hold nothing.

CONSISTENCY RULES, most important:
- It is the SAME character with the SAME outfit in all 25 cells. Only the camera angle and the
  leg and arm pose change.
- The outfit consists ONLY of the parts listed below. Draw nothing else: no extra pockets, pouches,
  straps, buckles, logos, badges, numbers, patches, hoses, gauges, lights, boxes or tools.
- Every part is left/right symmetric, unless its description says it is worn on the character's
  LEFT side. The character's left is the viewer's right in the front view, faces the viewer in
  the towards, side and away views, and is on the viewer's left in the back view.
- A part is only visible in the views where the list says so. The back views show the plain back
  of the parts already seen from the side, nothing new.

Background: fully transparent (PNG with alpha). If transparency is not possible, a perfectly flat,
uniform magenta #FF00FF with no gradient, and no magenta or pink anywhere on the figures.
Do not draw: ground, water, cast shadows, a landing net, fish, text, letters, numbers, grid lines,
cell borders or labels. USE REAL TRANSPARENCY!!!
```

## Shared swim prompt (start of the zone 3 and 4 prompts)

Attach the approved zone 2 sheet as the character reference.

```
Character sprite sheet for a cozy mobile game about catching fish. Match the painted cartoon
style, the bold dark outline, the colour palette and the light from the top left of the attached
reference exactly, and keep its character: the same face, beanie, yellow suit and proportions.
Use ONLY its style: no dark background, no vignette, no glow or halo around the figures.

THE DIVER SWIMS. In every cell the body lies flat and horizontal, face down, as a scuba diver
swims: head in front, body straight, legs behind, the back facing up. The arms are bent and held
loosely forward under the chest, hands empty and open, holding nothing.

Canvas 1536 x 1024 px, a strict grid of 5 columns x 5 rows. One diver per cell, the same size in
every cell: in the profile view about 270 px from the top of the head to the tips of the fins.
The middle of the body (the hips) sits exactly on the cell centre: columns x = 154, 461, 768,
1075, 1382, rows y = 102, 307, 512, 717, 922. Nothing touches or crosses a cell border.

Rows are camera views. The camera looks down on the diver from about 30 degrees above, the same
angle in every cell. Because the diver lies flat, the camera always sees the diver's back and
the gear on it from above.
Row 1 FRONT: swimming head first straight towards the viewer. Strongly foreshortened: the head
and the mask in front, the shoulders and the gear on the back behind and above them, the fins
peeking out at the far end above the back.
Row 2 TOWARDS: three-quarter view, swimming towards the viewer and to the viewer's LEFT, head at
the lower left, fins at the upper right.
Row 3 SIDE: exact profile, swimming to the viewer's LEFT, head on the left, fins on the right,
the body a horizontal line.
Row 4 AWAY: three-quarter view from behind, swimming away from the viewer and to the viewer's
LEFT, head at the upper left, fins at the lower right; the face is hidden.
Row 5 BACK: swimming straight away from the viewer. Strongly foreshortened: the fins in front
(nearest to the viewer), the legs, the back with its gear, the back of the head at the far end.

Columns are animation frames of one slow flutter kick, the same in every row. The legs stay
nearly straight and move from the hips; the body, arms and head stay still:
Column 1 GLIDING: legs together and straight, fins together.
Column 2 KICK A: right leg and fin up, left leg and fin down.
Column 3 KICK B: legs passing each other, fins level.
Column 4 KICK C: left leg and fin up, right leg and fin down.
Column 5 KICK D: legs passing each other, fins level.

CONSISTENCY RULES, most important:
- It is the SAME diver with the SAME outfit in all 25 cells. Only the camera angle and the legs
  change.
- The outfit consists ONLY of the parts listed below. Draw nothing else: no extra pockets, pouches,
  straps, buckles, logos, badges, numbers, patches, hoses, gauges, lights, knives, boxes or tools.
- Every part is left/right symmetric, unless its description says it is worn on the character's
  LEFT side.
- A part is only visible in the views where the list says so. No view shows a part the other
  views don't have.

Background: fully transparent (PNG with alpha). If transparency is not possible, a perfectly flat,
uniform magenta #FF00FF with no gradient, and no magenta or pink anywhere on the figures.
Do not draw: seabed, water, bubbles, cast shadows, a landing net, a basket, fish, text, letters,
numbers, grid lines, cell borders or labels. USE REAL TRANSPARENCY!!!
```

## The character (in every zone prompt, after the shared prompt; the swimmers wear fins instead of the boots)

```
THE CHARACTER: a friendly, slightly chubby young fisher with cartoon proportions (head about a
quarter of the body height), a round face with rosy cheeks, small dark eyes and a short smile,
brown hair hidden under a navy-blue knitted beanie with a folded brim. One-piece bright yellow
waterproof suit (#F5C518 with orange-yellow shading), with a round collar, a seam at the waist
and loose trouser legs. Black rubber gloves to the wrist. Black rubber boots to mid-calf with
thick soles.
```

---

## Zone 1 – wader with basket

```
OUTFIT, ZONE 1 (only these parts):
1. The character as described, face fully visible: NO mask, NO goggles, NO snorkel, nothing on
   the forehead or the beanie.
2. A woven wicker basket, light brown, open at the top, worn high on the back between the
   shoulder blades: about as wide as the shoulders, from the shoulders to the waist, its rim
   level with the top of the shoulders. It is empty.
3. Two brown leather shoulder straps holding the basket, one over each shoulder, running straight
   down the chest to the waist.
Visible per view:
FRONT: face, both straps on the chest. The basket's rim shows only as a narrow edge above and
beside the shoulders.
TOWARDS: face, both straps, the basket's side behind the left shoulder.
SIDE: profile, one strap over the near shoulder, the basket's side on the back.
AWAY: the basket from behind and slightly from the side, covering most of the back; the straps
disappear over the shoulders.
BACK: the basket's woven back panel covering the back from the shoulders to the waist, the beanie
above it, the legs below it. Nothing else.
```

## Zone 2 – wader with mask and snorkel

```
OUTFIT, ZONE 2 (only these parts):
1. to 3. Exactly the zone 1 character, basket and straps.
4. A diving mask with one oval glass over the eyes and nose, a blue rubber frame and a blue
   strap that runs around the head over the beanie.
5. A classic snorkel worn on the character's LEFT side of the head, like real snorkellers wear it:
   a blue J-shaped tube with an orange tip. The mouthpiece is ALWAYS in the mouth, in every cell.
   From the mouth the tube bends to the left cheek and runs straight up along the LEFT side of the
   head, OUTSIDE the mask (it never crosses the mask glass or the face), clipped to the mask
   strap at the temple. Its top ends a hand's width above the top of the beanie. Nothing on the
   right side of the head except the mask strap.
Visible per view:
FRONT: the mask glass clear in the middle of the face, the mouthpiece in the mouth, the tube
rising beside the head on the VIEWER'S RIGHT, its tip above the head.
TOWARDS / SIDE / AWAY: the tube on the near side of the head (the side facing the viewer), from
the mouth along the cheek and up past the temple to above the head.
BACK: the mask strap across the back of the beanie, the tube rising beside the head on the
VIEWER'S LEFT, the basket. Nothing else.
```

## Zone 3 – scuba (swim grid)

Twin-hose regulator: a real (vintage) design, and symmetric, so mirroring doesn't move it.

```
OUTFIT, ZONE 3 (only these parts):
1. The character as described, but with fins instead of boots. NO basket, NO snorkel.
2. The same diving mask as zone 2 (oval glass, blue frame, blue strap over the beanie).
3. One yellow steel scuba tank lying lengthwise on the middle of the back, from the shoulders to
   the hips, its silver valve at the head end, just behind the back of the head.
4. A black harness: two shoulder straps and one waist strap.
5. A twin-hose regulator: two black ribbed hoses from the tank valve, one over each shoulder, to a
   black mouthpiece in the middle of the mouth. The mouthpiece is ALWAYS in the mouth.
6. A black weight belt around the hips with four silver lead blocks, evenly spaced, symmetric.
7. Blue full-foot fins, the same blue as the mask, each blade about as long as the lower leg.
Visible per view:
FRONT: the mask and the face looking ahead, the mouthpiece, both hoses running from the mouth
back over the shoulders to the valve behind the head, the tank lying on the back behind it, the
fin tips beyond.
TOWARDS: the face in three-quarter view, the tank on top of the back, both shoulder straps, the
near hose, the weight belt, both fins.
SIDE: the profile with the mask and mouthpiece, the near hose arching from the valve to the
mouth, the tank along the top of the back, the waist strap, the weight belt, the fins.
AWAY: the back of the head with the mask strap, the tank on the back from above and behind, both
hoses going over the shoulders, the weight belt, the fins from above.
BACK: the fin blades nearest to the viewer, the legs, the weight belt, the bottom end of the tank,
the valve and the back of the head beyond it. Nothing else: no labels, gauges or second tank.
```

## Zone 4 – rebreather (swim grid)

```
OUTFIT, ZONE 4 (only these parts):
1. The character as described, but with fins instead of boots. NO basket, NO snorkel, NO scuba
   tank.
2. The same diving mask as zone 2.
3. A heavy rebreather: one large, rounded, box-shaped dark grey casing on the back, wider than the
   shoulders, from the back of the neck to the hips, with a yellow stripe around its edge.
4. Two black counterlung bags like flat pillows, one on each side of the chest, under the arms.
5. Twin hoses: a thick black ribbed hose from the head end of the casing over each shoulder to a
   chunky black mouthpiece in the middle of the mouth. The mouthpiece is ALWAYS in the mouth.
6. The black harness and the weight belt of zone 3.
7. Black full-foot fins with a yellow edge, each blade about as long as the lower leg.
Visible per view:
FRONT: the mask, the mouthpiece, both hoses, the head end of the casing behind the head with its
edges sticking out beyond the shoulders, the counterlungs as narrow edges beside the chest, the
fin tips beyond.
TOWARDS: the face in three-quarter view, the casing on top of the back, the near counterlung
under the arm, the near hose, both fins.
SIDE: the profile with the mask and mouthpiece, the casing's thick side along the top of the
back, the near counterlung under the arm, the near hose, the weight belt, the fins.
AWAY: the back of the head, the casing from above and behind, both hoses going over the
shoulders, the fins from above.
BACK: the fin blades nearest to the viewer, the legs, the weight belt, the bottom end of the
casing with its yellow edge stripe, the back of the head beyond it. Nothing else: no gauges,
lights, valves or panels on the casing.
```

## Zone 5 – hard-hat suit

The headlamp was added later (2026-11-09) by attaching the old sheet and asking for the same sheet
with only the lamp added. ChatGPT painted a checkerboard instead of transparency and a few red
smudges along the outlines; both were removed before cutting, and the bottom rows were moved
apart where boots touched the heads below. The lamp's position per view is in
`Wader.HARDHAT_LAMPS`.

```
OUTFIT, ZONE 5 (only these parts):
1. The character's body in the same yellow suit, but thicker and rounder (heavy canvas).
2. A round yellow-painted diving helmet with dark bolts around the neck, on a yellow breastplate
   that covers the shoulders. Three round portholes with dark rims: a large one at the front
   showing the character's face (beanie off, no mask, no mouthpiece) and two small ones, one on
   each side of the helmet. NO porthole on top, NO porthole at the back.
3. Thick black gloves and big heavy black boots with metal toe caps.
4. A small headlamp: a short round brass lamp housing with a glass lens, on top of the helmet
   just above the front porthole, pointing forward; about a quarter of the helmet's width.
5. NO backpack, NO tank, NO air hose, NO other lights, NO basket.
Visible per view:
FRONT: the front porthole with the face, both side portholes as narrow ovals at the edges, the
lamp's round lens above the front porthole.
TOWARDS: the front porthole at an angle, one side porthole, the lamp at an angle.
SIDE: one side porthole, the front porthole as a narrow oval at the front, the lamp in profile.
AWAY: the round back of the helmet and one side porthole at the edge, the back of the lamp
housing peeking over the top.
BACK: the plain, smooth, round back of the helmet with its bolt ring at the neck, the breastplate,
the plain back of the suit, at most the top of the lamp housing. Nothing on the back: no box,
pack, tank, hose or valve.
```

## Zone 6 – mini-submarine

```
REPLACE the walk cycle for this sheet: the submarine does not walk. Column 1 is it at rest, and
columns 2 to 5 are the same pose with the propeller turned 0, 45, 90 and 135 degrees further.
Everything except the propeller is identical in all five frames of a row. The submarine is about
180 px wide and floats with its bottom on the row's feet line.

SUBJECT, ZONE 6 (only these parts):
1. A small, round, egg-shaped yellow submarine for one person, about as tall as it is long, with a
   dark seam around its middle.
2. A large glass dome at the FRONT, taking up most of the front half. Inside it, the character
   (head and shoulders, beanie on, no mask) looks out.
3. A propeller in a round yellow ring at the centre of the BACK.
4. Two short, flat yellow fins, one on each side, symmetric.
5. One round headlamp on top, above the dome.
6. Two short black skids underneath.
Nothing else: no extra portholes, hatches, pipes, antennas, arms, lamps or panels.
Visible per view:
FRONT: the dome straight on with the character, the headlamp above, both fins at the sides, the
skids below. The propeller is hidden.
TOWARDS: the dome at an angle, one fin, the hull's side.
SIDE: profile pointing left: dome at the front (left), propeller ring at the back (right), one
fin, the headlamp on top.
AWAY: the hull from behind and the side, the propeller ring, the dome's edge at the far side.
BACK: the plain yellow back of the hull with the propeller ring in the centre, both fins at the
sides, the headlamp's top just visible. Nothing else.
```

---

## Catch bag (zones 3–6, one small extra image)

```
Same style as the attached wader sheet. Transparent background, canvas 1024 x 512 px. Three
sprites side by side, centred at x = 170, 512, 854, each about 200 px wide: a floating mesh
catch bag made of orange netting on a round yellow ring, with a short black tow line coming out
of its front (left) end. First EMPTY and limp, then HALF FULL, then FULL and round (the fish
inside only as dark blurry shapes behind the mesh). No fish outside the bag, no shadow, no text.
```
