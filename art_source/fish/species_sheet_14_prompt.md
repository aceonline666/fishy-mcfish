# Species sheet 14 – generation prompt

More everyday species for the two new locations:

- **Antarctica** had mostly seals, the orca and a few odd ones. The two penguins come back, drawn
  again (the ones on sheet 10 had two flippers on one side and three feet), and the common
  Antarctic fish join them: the notothenioids that make up most of the fish there.
- **Jurassic Sea** had small ammonites and belemnites and then only giants. Small and
  middle-sized fish, a shark and a sea crocodile fill the gap.

None of them is in `data/species.csv` yet: add them with the sprites. Attach
`art_source/fish/species_sheet_6.png` and `art_source/fish/species_sheet_10.png` (the style the
new locations already use). Cut with
`python tools/extract_painted.py art_source/fish/species_sheet_14.png assets/sprites/fish_painted`
after adding the sheet to `SHEETS` in the script.

Planned places (zone, rough size):

| # | Species | Zone | Size |
|---|---|---|---|
| 1 | Emperor penguin | Pack ice | 115 cm |
| 2 | Adélie penguin | Ice shore, Krill swarm | 70 cm |
| 3 | Antarctic silverfish | Ice shore, Krill swarm | 20 cm |
| 4 | Emerald rockcod | Ice shore | 25 cm |
| 5 | Bald notothen | Krill swarm, Pack ice | 25 cm |
| 6 | Mackerel icefish | Pack ice, Polar front | 50 cm |
| 7 | Marbled rockcod | Polar front, Ice shelf slope | 80 cm |
| 8 | Antarctic jonasfish | Ice shelf slope | 50 cm |
| 9 | Leptolepis | Lime lagoon, Ammonite reef | 20 cm |
| 10 | Dapedium | Ammonite reef, Sponge reef | 40 cm |
| 11 | Pachycormus | Sponge reef, Open Tethys | 100 cm |
| 12 | Lepidotes | Sponge reef, Deep basin | 150 cm |
| 13 | Hybodus | Open Tethys, Deep basin | 200 cm |
| 14 | Metriorhynchus | Deep basin | 300 cm |

---

## Prompt

```
A sprite sheet for a cozy mobile game about fish. Match the painting style, the outline, the
soft shading and the light of the attached species sheets exactly: friendly but accurate, every
species recognisable by a marine biologist or palaeontologist. Use only their style, not their
animals.

Canvas 1536 × 1024 px, fully transparent background (PNG with alpha). Fourteen creatures in a
grid of four columns and four rows of 384 × 256 px cells (the last row has two, in its first two
cells), each centred in its own cell and filling about 85 % of its width, well apart: no creature
touches or overlaps another, no labels, no text, no numbers, no frames, no water, no bubbles, no
shadows.

Every creature is seen EXACTLY FROM THE SIDE, HEAD POINTING LEFT, its body straight and
horizontal.

1. Emperor penguin (Aptenodytes forsteri), swimming underwater, seen exactly from the side: a
   streamlined body, black back and head, white belly, golden-yellow patches on the neck, a
   pinkish-orange stripe on the beak. Anatomically correct: only ONE flipper is visible (the
   near one, held back along the side), and exactly TWO feet, together at the tail, pointing
   back.
2. Adélie penguin (Pygoscelis adeliae), swimming underwater, seen exactly from the side: smaller
   and rounder, black back and head, white belly, a white ring round the eye, a short beak.
   Anatomically correct: only ONE visible flipper, held back along the side, and exactly TWO
   feet together at the tail.
3. Antarctic silverfish (Pleuragramma antarctica): a small, slim, silvery, almost see-through
   fish with a big eye and a forked tail.
4. Emerald rockcod (Trematomus bernacchii): a stocky bottom fish, mottled green-brown with dark
   bands and a pale belly, a big head and wide pectoral fins.
5. Bald notothen (Pagothenia borchgrevinki): a slim, silvery-grey fish with dark spots, a pointed
   head and a long second dorsal fin.
6. Mackerel icefish (Champsocephalus gunnari): a long, pale, see-through grey-white icefish with
   dark bands on the back, a long flat snout and large fins.
7. Marbled rockcod (Notothenia rossii): a heavy fish with a big head, olive-brown with a marbled
   pattern of darker patches, two dorsal fins.
8. Antarctic jonasfish (Neopagetopsis ionah): a large, pale icefish with a long, duck-billed
   snout, faint dark bands, a tall spiny first dorsal fin.
9. Leptolepis (Leptolepis coryphaenoides), Jurassic: a small, slender, herring-like silver fish
   with thin round scales and a forked tail.
10. Dapedium (Dapedium politum), Jurassic: a deep, almost round-bodied fish covered in thick,
    shiny, diamond-shaped bronze scales, a small mouth with peg-like teeth.
11. Pachycormus (Pachycormus macropterus), Jurassic: a streamlined, tuna-like fish with long,
    sickle-shaped pectoral fins, a pointed snout and a deep forked tail, blue-grey.
12. Lepidotes (Lepidotes elvensis), Jurassic: a large, thick-bodied fish covered in heavy, shiny,
    square enamel scales, a blunt head and a short tail, olive-bronze.
13. Hybodus (Hybodus hauffianus), Jurassic: a shark about two metres long with a blunt snout and
    a long, sharp spine at the front of each of its two dorsal fins, grey-brown, pale belly.
14. Metriorhynchus (Metriorhynchus superciliosus), Jurassic: a sea crocodile with smooth skin and
    no armour plates, a long narrow toothy snout, four small paddle flippers and a shark-like
    tail fin, grey-green.
```
