# Top-view species sprites

All species redrawn in one style and seen from above, as decided after the style test
(`art_source/fish/species_style_test_prompt.md`, 2026-11-08): the cute comic style of sheet 5,
the steep view from above of the cod in `reference_top_cod.png` (cut from
`../species_style_test.png`).

Every species gets two sprites: `assets/sprites/fish_painted/<id>_top.png` swimming towards the
lower left and `<id>_top_up.png` towards the upper left; the game mirrors them for the right.
(Flipping the first upside down instead showed the bellies.) Each sheet holds 8 species on a
4 × 2 grid, drawn as two images in one chat: first all heading lower left, then the same creatures
heading upper left. Larger grids with both views in one image did not work (first try of sheet
01): ChatGPT fell back to tilted side views and kept them when asked to redraw.

15 sheets for 116 species: the 102 in the game and the 14
planned on sheet 14 (`../species_sheet_14_prompt.md`), which skip the side view. Sheets are grouped
by body type (fish, eels, sharks, flat, cephalopods, jellyfish, crawlers, upright swimmers, big
animals), so each creature's hint on how it looks from above stays short.

Workflow per sheet (details in `top_sheet_NN_prompt.md`): a NEW ChatGPT chat with only
`reference_top_cod.png` and the first prompt, saved as `top_sheet_NN.png`; then in the same chat
`reference_top_cod_up.png` and the second prompt, saved as `top_sheet_NN_up.png`. Cut both with
`python tools/extract_top_sheet.py NN` and `... NN --up`, import in Godot and turn mipmaps on for
the new sprites. ChatGPT's free daily limit allows about two sheets.
Regenerate the prompts with `python tools/make_top_view_prompts.py`.

| Sheet | Species id | Species |
|---|---|---|
| 01 | `european_sprat` | European sprat (Sprattus sprattus) |
| 01 | `atlantic_herring` | Atlantic herring (Clupea harengus) |
| 01 | `atlantic_mackerel` | Atlantic mackerel (Scomber scombrus) |
| 01 | `lumpsucker` | Lumpsucker (Cyclopterus lumpus) |
| 01 | `atlantic_cod` | Atlantic cod (Gadus morhua) |
| 01 | `atlantic_wolffish` | Atlantic wolffish (Anarhichas lupus) |
| 01 | `roundnose_grenadier` | Roundnose grenadier (Coryphaenoides rupestris) |
| 01 | `rabbit_fish` | Rabbit fish (Chimaera monstrosa) |
| 02 | `ocellaris_clownfish` | Ocellaris clownfish (Amphiprion ocellaris) |
| 02 | `blue_green_chromis` | Blue-green chromis (Chromis viridis) |
| 02 | `blue_tang` | Blue tang (Paracanthurus hepatus) |
| 02 | `mandarinfish` | Mandarinfish (Synchiropus splendidus) |
| 02 | `red_lionfish` | Red lionfish (Pterois volitans) |
| 02 | `humphead_wrasse` | Humphead wrasse (Cheilinus undulatus) |
| 02 | `atlantic_bluefin_tuna` | Atlantic bluefin tuna (Thunnus thynnus) |
| 02 | `yellowfin_tuna` | Yellowfin tuna (Thunnus albacares) |
| 03 | `humpback_anglerfish` | Humpback anglerfish (Melanocetus johnsonii) |
| 03 | `atlantic_footballfish` | Atlantic footballfish (Himantolophus groenlandicus) |
| 03 | `skinnycheek_lanternfish` | Skinnycheek lanternfish (Benthosema pterotum) |
| 03 | `west_indian_ocean_coelacanth` | West Indian Ocean coelacanth (Latimeria chalumnae) |
| 03 | `australian_salmon` | Australian salmon (Arripis trutta) |
| 03 | `blue_groper` | Blue groper (Achoerodus viridis) |
| 03 | `old_wife` | Old wife (Enoplosus armatus) |
| 03 | `orange_roughy` | Orange roughy (Hoplostethus atlanticus) |
| 04 | `blobfish` | Blobfish (Psychrolutes marcidus) |
| 04 | `common_fangtooth` | Common fangtooth (Anoplogaster cornuta) |
| 04 | `red_sea_bream` | Red sea bream (Pagrus major) |
| 04 | `japanese_horse_mackerel` | Japanese horse mackerel (Trachurus japonicus) |
| 04 | `tiger_puffer` | Tiger puffer (Takifugu rubripes) |
| 04 | `japanese_amberjack` | Japanese amberjack (Seriola quinqueradiata) |
| 04 | `opah` | Opah (Lampris guttatus) |
| 04 | `mariana_snailfish` | Mariana snailfish (Pseudoliparis swirei) |
| 05 | `hottentot_seabream` | Hottentot seabream (Pachymetopon blochii) |
| 05 | `south_african_sardine` | South African sardine (Sardinops sagax) |
| 05 | `galjoen` | Galjoen (Dichistius capensis) |
| 05 | `cape_hake` | Cape hake (Merluccius capensis) |
| 05 | `sloanes_viperfish` | Sloane's viperfish (Chauliodus sloani) |
| 05 | `great_barracuda` | Great barracuda (Sphyraena barracuda) |
| 05 | `crocodile_icefish` | Crocodile icefish (Chionodraco hamatus) |
| 05 | `antarctic_toothfish` | Antarctic toothfish (Dissostichus mawsoni) |
| 06 | `leedsichthys` | Leedsichthys (Leedsichthys problematicus) |
| 06 | `antarctic_silverfish` | Antarctic silverfish (Pleuragramma antarctica) – new (sheet 14), add to data/species.csv |
| 06 | `emerald_rockcod` | Emerald rockcod (Trematomus bernacchii) – new (sheet 14), add to data/species.csv |
| 06 | `bald_notothen` | Bald notothen (Pagothenia borchgrevinki) – new (sheet 14), add to data/species.csv |
| 06 | `mackerel_icefish` | Mackerel icefish (Champsocephalus gunnari) – new (sheet 14), add to data/species.csv |
| 06 | `marbled_rockcod` | Marbled rockcod (Notothenia rossii) – new (sheet 14), add to data/species.csv |
| 06 | `antarctic_jonasfish` | Antarctic jonasfish (Neopagetopsis ionah) – new (sheet 14), add to data/species.csv |
| 06 | `leptolepis` | Leptolepis (Leptolepis coryphaenoides) – new (sheet 14), add to data/species.csv |
| 07 | `dapedium` | Dapedium (Dapedium politum) – new (sheet 14), add to data/species.csv |
| 07 | `pachycormus` | Pachycormus (Pachycormus macropterus) – new (sheet 14), add to data/species.csv |
| 07 | `lepidotes` | Lepidotes (Lepidotes elvensis) – new (sheet 14), add to data/species.csv |
| 07 | `lesser_sand_eel` | Lesser sand eel (Ammodytes tobianus) |
| 07 | `conger_eel` | European conger (Conger conger) |
| 07 | `pink_ling` | Pink ling (Genypterus blacodes) |
| 07 | `kingklip` | Kingklip (Genypterus capensis) |
| 07 | `pacific_blackdragon` | Pacific blackdragon (Idiacanthus antrostomus) |
| 08 | `giant_oarfish` | Giant oarfish (Regalecus glesne) |
| 08 | `pelican_eel` | Pelican eel (Eurypharynx pelecanoides) |
| 08 | `blacktip_reef_shark` | Blacktip reef shark (Carcharhinus melanopterus) |
| 08 | `basking_shark` | Basking shark (Cetorhinus maximus) |
| 08 | `greenland_shark` | Greenland shark (Somniosus microcephalus) |
| 08 | `bluntnose_sixgill_shark` | Bluntnose sixgill shark (Hexanchus griseus) |
| 08 | `port_jackson_shark` | Port Jackson shark (Heterodontus portusjacksoni) |
| 08 | `great_white_shark` | Great white shark (Carcharodon carcharias) |
| 09 | `frilled_shark` | Frilled shark (Chlamydoselachus anguineus) |
| 09 | `goblin_shark` | Goblin shark (Mitsukurina owstoni) |
| 09 | `copper_shark` | Copper shark (Carcharhinus brachyurus) |
| 09 | `ragged_tooth_shark` | Ragged-tooth shark (Carcharias taurus) |
| 09 | `shortfin_mako` | Shortfin mako (Isurus oxyrinchus) |
| 09 | `whale_shark` | Whale shark (Rhincodon typus) |
| 09 | `hybodus` | Hybodus (Hybodus hauffianus) – new (sheet 14), add to data/species.csv |
| 09 | `european_plaice` | European plaice (Pleuronectes platessa) |
| 10 | `reef_manta_ray` | Reef manta ray (Mobula alfredi) |
| 10 | `smooth_stingray` | Smooth stingray (Bathytoshia brevicaudata) |
| 10 | `giant_guitarfish` | Giant guitarfish (Rhynchobatus djiddensis) |
| 10 | `ocean_sunfish` | Ocean sunfish (Mola mola) |
| 10 | `curled_octopus` | Curled octopus (Eledone cirrhosa) |
| 10 | `giant_squid` | Giant squid (Architeuthis dux) |
| 10 | `chambered_nautilus` | Chambered nautilus (Nautilus pompilius) |
| 10 | `vampire_squid` | Vampire squid (Vampyroteuthis infernalis) |
| 11 | `southern_blue_ringed_octopus` | Southern blue-ringed octopus (Hapalochlaena maculosa) |
| 11 | `japanese_flying_squid` | Japanese flying squid (Todarodes pacificus) |
| 11 | `giant_pacific_octopus` | Giant Pacific octopus (Enteroctopus dofleini) |
| 11 | `common_octopus` | Common octopus (Octopus vulgaris) |
| 11 | `colossal_squid` | Colossal squid (Mesonychoteuthis hamiltoni) |
| 11 | `ammonite` | Ammonite (Dactylioceras commune) |
| 11 | `belemnite` | Belemnite (Passaloteuthis bisulcata) |
| 11 | `lions_mane_jellyfish` | Lion's mane jellyfish (Cyanea capillata) |
| 12 | `moon_jellyfish` | Moon jellyfish (Aurelia aurita) |
| 12 | `blubber_jellyfish` | Blubber jellyfish (Catostylus mosaicus) |
| 12 | `nomuras_jellyfish` | Nomura's jellyfish (Nemopilema nomurai) |
| 12 | `portuguese_man_o_war` | Portuguese man o' war (Physalia physalis) |
| 12 | `japanese_spider_crab` | Japanese spider crab (Macrocheira kaempferi) |
| 12 | `giant_isopod` | Giant isopod (Bathynomus giganteus) |
| 12 | `antarctic_krill` | Antarctic krill (Euphausia superba) |
| 12 | `giant_sea_spider` | Giant sea spider (Colossendeis megalonyx) |
| 13 | `weedy_seadragon` | Weedy seadragon (Phyllopteryx taeniolatus) |
| 13 | `leafy_seadragon` | Leafy seadragon (Phycodurus eques) |
| 13 | `knysna_seahorse` | Knysna seahorse (Hippocampus capensis) |
| 13 | `sperm_whale` | Sperm whale (Physeter macrocephalus) |
| 13 | `blue_whale` | Blue whale (Balaenoptera musculus) |
| 13 | `humpback_whale` | Humpback whale (Megaptera novaeangliae) |
| 13 | `southern_right_whale` | Southern right whale (Eubalaena australis) |
| 13 | `orca` | Orca (Orcinus orca) |
| 14 | `common_bottlenose_dolphin` | Common bottlenose dolphin (Tursiops truncatus) |
| 14 | `leopard_seal` | Leopard seal (Hydrurga leptonyx) |
| 14 | `southern_elephant_seal` | Southern elephant seal (Mirounga leonina) |
| 14 | `ichthyosaurus` | Ichthyosaurus (Ichthyosaurus communis) |
| 14 | `plesiosaurus` | Plesiosaurus (Plesiosaurus dolichodeirus) |
| 14 | `liopleurodon` | Liopleurodon (Liopleurodon ferox) |
| 14 | `metriorhynchus` | Metriorhynchus (Metriorhynchus superciliosus) – new (sheet 14), add to data/species.csv |
| 14 | `green_sea_turtle` | Green sea turtle (Chelonia mydas) |
| 15 | `loggerhead_turtle` | Loggerhead turtle (Caretta caretta) |
| 15 | `leatherback_turtle` | Leatherback turtle (Dermochelys coriacea) |
| 15 | `emperor_penguin` | Emperor penguin (Aptenodytes forsteri) – new (sheet 14), add to data/species.csv |
| 15 | `adelie_penguin` | Adélie penguin (Pygoscelis adeliae) – new (sheet 14), add to data/species.csv |
