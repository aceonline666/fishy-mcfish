# Species sheets 10 and 11 – generation prompts

Sprites for the two location ideas on the README's "Later" list, generated ahead of the
locations: the Antarctic sea (sheet 10) and the Jurassic sea (sheet 11). Neither location exists
yet, so the creatures are not in `data/species.csv`.

Attach `art_source/fish/species_sheet_6.png` as the **style** reference for both. Cut with
`python tools/extract_painted.py art_source/fish/species_sheet_10.png assets/sprites/fish_painted`
once the species exist (add the sheet to `SHEETS` in the script first).

Notes on the results: on sheet 10 the two seals got fish-like tail fins where seals have hind
flippers (ask again for those two if it matters); sheet 11 came out as asked.

## Sheet 10: Antarctic sea

```
Same style as the attached sheet, a new sheet of eight different creatures of the Antarctic sea.
Canvas 1536 × 1024 px, fully transparent background (PNG with alpha). Eight creatures in two
columns and four rows, each on its own, well apart: no creature touches or overlaps another, no
labels, no text, no numbers, no frames, no water, no ice, no bubbles, no shadows.

Every creature is seen exactly from the side, HEAD POINTING LEFT, its body straight and
horizontal.

1. Antarctic krill (Euphausia superba): a small, translucent orange-pink shrimp-like krill with
   long antennae, about 250 px.
2. Emperor penguin (Aptenodytes forsteri), swimming underwater: streamlined, flippers back,
   black back, white belly, yellow-orange patches at the neck, about 450 px.
3. Adelie penguin (Pygoscelis adeliae), swimming underwater: smaller, black and white with a
   white eye ring, about 350 px.
4. Leopard seal (Hydrurga leptonyx), swimming: long, sleek, grey with dark spots, a big
   reptile-like head, about 650 px.
5. Antarctic toothfish (Dissostichus mawsoni): a big, heavy, grey-brown fish with a large head,
   about 550 px.
6. Crocodile icefish (Chionodraco hamatus): a pale, almost white, translucent fish with a long,
   flat, crocodile-like snout and colourless blood, about 450 px.
7. Giant sea spider (Colossendeis megalonyx): a large, long-legged, orange sea spider seen from
   the side, legs reaching down to one level line, about 400 px.
8. Southern elephant seal (Mirounga leonina), swimming: a huge, grey-brown, blubbery seal with a
   short trunk-like nose, about 650 px.
```

## Sheet 11: Jurassic sea

```
Same style as the attached sheet, a new sheet of six different prehistoric sea creatures from
the Jurassic period. Canvas 1536 × 1024 px, fully transparent background (PNG with alpha). Six
creatures in two columns and three rows, each on its own, well apart: no creature touches or
overlaps another, no labels, no text, no numbers, no frames, no water, no bubbles, no shadows.

Every creature is seen exactly from the side, HEAD (or shell opening) POINTING LEFT, its body
straight and horizontal, painted as a believable animal after current science.

1. Ichthyosaurus: a dolphin-shaped marine reptile with a long, narrow, toothy snout, a huge eye,
   a crescent tail fin and a triangular dorsal fin, blue-grey with a pale belly, about 600 px.
2. Plesiosaurus: a marine reptile with a small head on a long neck, a broad body with four long
   paddle flippers and a short tail, brown-green, about 650 px.
3. Liopleurodon: a big, heavy pliosaur with a huge, crocodile-like head full of teeth, a short
   neck, four strong paddle flippers, dark grey-brown, about 650 px.
4. Ammonite: a coiled, ribbed spiral shell in cream and brown stripes with the squid-like animal
   and its tentacles looking out of the opening, about 300 px.
5. Belemnite: a squid-like animal with a long, bullet-shaped body and ten short hooked arms,
   reddish-brown, about 350 px.
6. Leedsichthys: an enormous, filter-feeding bony fish with a wide gaping mouth, long pectoral
   fins and a forked tail, grey-brown, about 700 px.
```
