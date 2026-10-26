# Fishy McFish

An idle fish-collecting game for Android (iOS later), built with **Godot 4.7.2**
(standard build, GDScript). Catch real ocean species with a drag-net, keep them in
aquariums, sell them and grow your collection.

## Play-testing

**On the PC:** open the project in Godot and press **F5**. The mouse emulates touch.

**From the command line:**

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path .
```

Saves are written to `%APPDATA%\Godot\app_userdata\Fishy McFish\save.json`.
Delete that file to start a new game.

**How to play:** touch the screen and the wader walks towards your finger; drag to steer, lift
the finger to stop. Fish that
come within reach of the hand net are scooped up automatically and stack up in the backpack.
Small fish go in at once; bigger ones (herring, mackerel) must stay in the net until the yellow
ring fills. Catches in quick succession build a combo.

Up on the beach, pads act while you stand on them (walking on sand is faster than wading). A
boardwalk in the middle leads from the water to the back of the beach without crossing any pad.
Each beach has **one tank and one shop**, which are upgraded instead of building more:
- **Store fish** puts the catch into the tank (big species need a big tank). Fish grow in the
  tank and are worth three times as much once grown. Two or more fish of a species **breed**:
  each pair gets young while the tank is less than 80 % full (the rest stays free for the catch).
- **Sell fish** in front of the shop: the backpack first, then grown fish from the tank, most
  valuable first; a breeding pair of each species stays, unless the tank is too full to breed
  (then pairs are sold too, so the tank never clogs up). The shop buys every fish; **Bigger
  shop** makes room for one more seller. Selling speeds up with every fish.
- **Hire seller**: one seller per shop level, each selling 10 grown fish a minute on their own,
  also while the game is closed. With breeding pairs in the tank this is a steady income.
- **Bigger tank / Bigger backpack / Better net** take coins until paid (partial payments are
  kept). Better nets land big fish faster and are a little wider.
- **Diving gear** (snorkel, scuba gear, rebreather, hard-hat suit, submersible) opens the
  deeper zones behind the buoy lines, down to the deep sea, with rarer and bigger creatures
  (sunfish, sharks, octopus, anglerfish, giant squid, whales, coelacanth); better gear also
  swims faster. Each location has six zones; zone N is *charted* after 25 × N catches there and
  every common/uncommon species of it.
- **Buy drone**: drone N fishes zone N once it is charted (where you are, else at another
  location), takes only species you have caught yourself and brings them to the tanks, also
  while the game is closed. Later drones are bigger and carry more.

The **Fishpedia** button lists every species, with facts for the ones you have caught. **Goals**
lists achievements with coin rewards. The **Map** travels between five locations: North Sea,
Coral Reef, Australia, Japan and South Africa. Each opens with a goal on the location before it
(charting its third zone, or the Sandbanks for the Reef) and a one-time fee. Every location has its own beach
business that starts from scratch (smallest net, first zone only, a small tank and a fish stall); building
at the Reef costs 2.5 times as much (`price_factor` in `data/locations.csv`). Coins, the
Fishpedia, charted zones and goals are shared, and sellers and drones keep working at the
locations you are not at.

Locations, zones, species, tanks, gear, drones, staff and goals are all data in `data/*.csv`.

**Game menu** (cog button): save, load (back to the last save) or start a new game after a
confirmation; sound effects and music each with an on/off switch and a volume slider; language. Settings are kept in
`user://settings.cfg`, apart from the save.

**Languages:** English and German. The game follows the device language; the game menu switches it. Texts are written in English and
wrapped in `tr("...")` (or `Lang.text("...")` in static code); data texts are translated where
they are shown. Translations live in `localization/de.po` (gettext, the English text is the
message id). `tests/unit/test_localization.gd` fails for any shown text without a German
translation, and for translations nothing uses any more, so add new texts to `de.po` too.

Tests and `tools/screenshot.gd` run in a sandboxed save (`SaveSystem.use_sandbox`), never
the real one.

Fish sprites are a body and a tail image per species (see `src/scenes/fishing/fish_art.gd` for
the conventions): painted PNGs in `assets/sprites/fish_painted/` (85 of 86 species), cut from
the painted sheets in `art_source/` by `tools/extract_painted.py` (needs Pillow, NumPy and
SciPy; run it once per sheet). The vampire squid has no painted sprite yet and keeps its SVG in
`assets/sprites/fish/`; a species without any sprite would be drawn as a coloured placeholder. The wader, the tank (one sprite per level), the shop (one per level), the
cashiers, the customers who queue at the shop while sellers work and leave with a fish, and the
beach decoration are painted sprites in `assets/sprites/props/`, cut from the coastal sheet by
`tools/extract_props.py` (its background checkerboard is removed by flood fill). The gear sheet
adds the drones, the buyers carrying their fish, the pictures of the
nets, diving gear, tanks, shops and drones on the upgrade pads, and the location pictures of the
World map. The wader and his equipment come from the equipment sheet, cut by
`tools/extract_wader.py`: the figure in four views, painted leg frames for the walk cycles, the
snorkel mask, scuba gear, rebreather, hard-hat suit, submersible and the baskets of the backpack
levels.
`art_source/` holds the source sheets (generated images) and is not imported by Godot. The logo,
the boot splash and the app icons (`assets/ui/logo.png`, `splash.png`, `icon*.png`) are rendered
by `tools/make_logo.py` from the painted sprites and the Luckiest Guy font (Apache 2.0, in
`art_source/fonts/`).

The view is 2:1 isometric (like Diablo II). Game logic runs in flat ground coordinates and only
drawing projects to the screen, see `src/scenes/world/iso.gd`.

**Screenshots:** `tools/screenshot.gd` runs the game in a window, optionally performs a scripted
net drag through the real input path, and saves PNGs:

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . -s res://tools/screenshot.gd -- --out=C:/temp/shots --drag
```

## Tests

Unit tests use [GUT](https://github.com/bitwes/Gut) 9.7.1, vendored in `addons/gut`.

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s addons/gut/gut_cmdln.gd
```

Tests can also be run from the GUT panel in the editor. CI runs them on every push.

**Balance:** `tools/balance_sim.gd` plays the game headless with a greedy bot using the real
rules and prints a timeline of purchases, charted zones, goals and income. `tests/unit/test_pacing.gd`
runs the same bot and checks the pacing targets (first tank upgrade < 5 min, snorkel 5–25 min,
Coral Reef 25–70 min, open sea charted after 55–120 min). The bot reaches the North Sea's
deep sea after about 3 h and has charted all five locations after about 12 h. Run it after
changing prices or income:

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s res://tools/balance_sim.gd -- --hours=3 --seed=1
```

## Project layout

| Path | Contents |
|---|---|
| `data/` | Balancing data as CSV (species, later locations, tanks, ...). Each CSV needs a `.csv.import` file with `importer="keep"`, otherwise Godot imports it as a translation. |
| `src/autoload/` | Global singletons: `EventBus`, `DataRegistry`, `GameState`, `TimeService`, `Settings`, `SaveSystem`, `Haptics`, `Platform` |
| `localization/` | Translations (`de.po`) |
| `src/model/` | Pure data and logic classes with no scene dependencies (`PlayerState`, `SpeciesDef`, `SaveFile`, ...) |
| `src/sim/` | Pure game rules and systems (`CatchRules`, `SpawnTable`, `LiveWell`, `Economy`) |
| `src/scenes/fishing/` | The fishing screen, swimming fish and the wader |
| `src/scenes/world/` | Isometric projection, play area and seabed decoration |
| `src/scenes/fx/` | Reusable feedback effects (`Juice`, `Ripple`) |
| `tools/` | Developer tools (screenshots) |
| `src/scenes/` | Scenes and their scripts |
| `tests/unit/` | GUT tests |

Rules of thumb:
- All GDScript is statically typed. Untyped declarations are errors.
- Game logic lives in `src/model/` and `src/sim/` so it can be tested and simulated headless.
- Platform-specific code only goes into `Platform`.

## Credits

- Music: "Feel Good Island Loop" by Brandon Morris, loop edit by AntumDeluge, CC0
  ([OpenGameArt](https://opengameart.org/content/feel-good-island-loop)).
