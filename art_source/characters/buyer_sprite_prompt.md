# Buyer sprite sheets – generation prompts

The buyers who queue at the booths and walk off with a fish (`Customer`). The first ones were
cut small (about 112 px tall) from the coastal sheet and looked blurry and too small next to the
sellers. Two sheets with three buyers each, every buyer in four poses, painted at the sellers'
size.

Attach `art_source/characters/cashier_sheet.png` as the **style, size and camera** reference
(the sellers they buy from). Cut each sheet with
`python tools/import_buyers.py art_source/characters/buyer_sheet_N.png assets/sprites/buyers N`.

## Layout

Canvas 1536 × 1024 px, 4 columns × 3 rows, cells 384 × 341 px, one buyer per row, the soles on
the lines y = 321, 662 and 1003, figures about 285 px tall (as the sellers).

| Column | Pose |
|---|---|
| 1 | front: three-quarter view facing the LOWER RIGHT, standing, arms relaxed |
| 2 | back: three-quarter view from behind, walking away to the UPPER RIGHT |
| 3 | as 1, holding a small clear water bag with an orange fish in the right hand |
| 4 | as 2, holding the same bag in the right hand |

## Prompt (sheet 1; sheet 2 only swaps the three people)

```
Character sprite sheet for a cozy mobile idle game about catching and selling fish at a beach.
Match the painted cartoon style, the bold dark outline weight, the colour palette, the shading
and the light of the attached seller sheet exactly, and draw the figures at EXACTLY the same size
as the sellers there: about 285 px from the soles to the top of the head, the same slightly
chunky body proportions with a big friendly head.

Subject: three different beach visitors who come to buy fish, one per row:
- Row 1: <person 1>
- Row 2: <person 2>
- Row 3: <person 3>
Each keeps exactly the same face, hair, clothes and colours in all four cells of their row.

Layout: canvas 1536 × 1024 px, 4 columns × 3 rows, one figure centred in each cell, column
centres at x = 192, 576, 960, 1344, the soles of the feet on the lines y = 321, 662 and 1003.
Columns, left to right:
1. FRONT: a three-quarter view from the front, the figure turned to face the LOWER RIGHT of the
   picture (towards the viewer and to the right), standing relaxed, both hands empty;
2. BACK: a three-quarter view from BEHIND, the figure turned away towards the UPPER RIGHT, the
   back of the head and the back visible, no face, both hands empty;
3. as column 1, but holding a small clear plastic water bag, tied at the top, with one orange
   fish inside, hanging from the right hand at hip height;
4. as column 2, holding the same water bag in the right hand.
Seen from about 30° above, like the sellers. Same view in each column for all three people.

Background: fully transparent (PNG with alpha). Do not draw: ground, shadows, grid lines, cell
borders, labels, text, letters, numbers, a border or frame. Nothing cropped, no figure
overlapping another cell.
```

People, sheet 1:
1. a young woman with a wide straw sun hat, sunglasses pushed up, a yellow sundress with white
   flowers and sandals, a straw tote bag over the left shoulder;
2. a cheerful round older man with a bald head and a grey moustache, a loud red Hawaiian shirt
   with white flowers, beige shorts and sandals;
3. a girl of about twelve with two dark braids, a turquoise baseball cap, a white T-shirt with a
   small fish print, denim shorts and sneakers.

People, sheet 2:
4. a chef in a white double-breasted chef's jacket, black-and-white checked trousers, a tall
   white chef's hat and black clogs;
5. a small grandmother with grey hair in a bun, round glasses, a green knitted cardigan over a
   lilac blouse, a brown skirt and sensible shoes;
6. a tall young man with curly black hair, a striped blue-and-white sailor shirt, rolled-up
   jeans and canvas shoes.
