# Species sheet 7 – generation prompt

Straight side views of the long, eel-like creatures. Their earlier sprites were painted curled
or in an S-bend, so the body wave FishArt sends down them (`Motion.WAVE`) bent an already bent
body and looked wrong. Straight, they wave cleanly.

Attach `art_source/fish/species_sheet_6.png` as the **style** reference. Cut with
`python tools/extract_painted.py art_source/fish/species_sheet_7.png assets/sprites/fish_painted`.

## Prompt

```
Same style as the attached sheet, a new sheet of seven different creatures. Canvas 1536 × 1024 px,
fully transparent background (PNG with alpha). Seven long, eel-like creatures, each on its own
row or half row, well apart: no creature touches or overlaps another, no labels, no text, no
numbers, no frames, no water, no bubbles, no shadows.

Every creature is seen exactly from the side, HEAD POINTING LEFT, and its body is PERFECTLY
STRAIGHT and horizontal from snout to tail tip, like a ruler: not curved, not bent, not curled,
no S-shape, the tail tip level with the head. Each is about 650 px long, so put them in two
columns: rows 1 to 3 hold two each, row 4 holds one.

1. Conger eel (Conger conger): grey-brown eel with a pale belly, a long dorsal fin starting just
   behind the pectoral fin and running round the tail, thick lips, no scales.
2. Frilled shark (Chlamydoselachus anguineus): dark brown eel-like shark with six frilly gill
   slits, a broad flat head with a short snout, the mouth at the tip full of tiny three-pointed
   teeth, small fins set far back.
3. Pelican eel (Eurypharynx pelecanoides): black deep-sea eel with an enormous loose mouth like a
   pelican's pouch (closed, held along the body), a tiny eye at the snout tip, a long whip tail
   ending in a small glowing pink light.
4. Sloane's viperfish (Chauliodus sloani): slender dark silvery-blue deep-sea fish with long
   needle fangs that stick out past its jaws, rows of small glowing dots along the belly, a
   long thin ray on the first dorsal fin.
5. Roundnose grenadier (Coryphaenoides rupestris): brownish-grey rattail with a big head, a
   blunt rounded snout, large eyes, and a body that tapers into a long thin pointed tail
   without a tail fin.
6. Pink ling (Genypterus blacodes): long eel-like cusk-eel with pink skin marbled with orange
   and pale patches, a long low fin along back and belly joining at the pointed tail.
7. Kingklip (Genypterus capensis): long eel-like cusk-eel, pinkish-orange with irregular brown
   blotches, long low fin along back and belly joining the small pointed tail.
```
