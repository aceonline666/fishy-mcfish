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
Left of it is the business, right of it the upgrades (net, diving gear, drones, backpack, tank).
Each beach has **one tank and one shop**, which are upgraded instead of building more. A pipe
between them holds the grown fish in the order they will be sold, each with its price:
- **Put in tank**, in front of the tank, puts the catch into it (big species need a big tank). Caught fish are
  partly grown already, one in ten fully. Fish grow in the tank, faster in bigger tanks; only grown fish can be sold, for three times their young value.
  A bar above the tank counts down to the next grown fish. The tank shows how full it is: its
  water rises with the fish in it and runs over at 100 %.
- **Sell fish** in front of the shop is greyed out ("No grown fish") until a fish is grown, then
  sells the grown fish from the tank, first grown first, to the buyers lining up there from the start. The shop buys
  every fish; **Bigger shop** adds booths for more sellers (1, 2, 4, 7, 11 and finally 15 in
  the seafood palace). While you stand on the pad you
  sell one fish every 2 s at your own booth; one line of buyers feeds the next free booth.
- **Hire seller**: one seller per free booth, each as fast as you,
  also while the game is closed. With bigger tanks you need more of them to keep up; the drones
  refill the tank, so this is a steady income.
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
the conventions): painted PNGs in `assets/sprites/fish_painted/` for all 86 species, cut from
the painted sheets in `art_source/` by `tools/extract_painted.py` (needs Pillow, NumPy and
SciPy; run it once per sheet; a later sheet replaces sprites of an earlier one). A species
without sprites would be drawn as a coloured placeholder. The wader, the tank (one sprite per level), the shop (one per level), the
cashiers, the customers who queue at the shop while sellers work and leave with a fish, and the
beach decoration are painted sprites in `assets/sprites/props/`, cut from the coastal sheet by
`tools/extract_props.py` (its background checkerboard is removed by flood fill). The gear sheet
adds the drones, the buyers carrying their fish, the pictures of the
nets, diving gear, tanks, shops and drones on the upgrade pads, and the location pictures of the
World map. The wader comes from the two diver sheets, cut by `tools/extract_diver.py`: one
sprite per gear level (waders with basket, snorkel, scuba, rebreather, hard-hat suit,
submersible) in five views, whose legs swing in step while walking. The landing nets (second
equipment sheet) and the baskets on the backpack pad (first equipment sheet) are cut by
`tools/extract_wader.py`. The ground tiles come from `tools/make_seafloor.py`: a location's own
seamless tiles `art_source/seafloor_<id>.png` (seabed under the water) and
`art_source/beach_<id>.png` (beach sand), otherwise a seabed made from the seafloor sheet. The props on the seabed are cut by
`tools/extract_seabed.py` from `art_source/seabed_props.png` (temperate water: rocks, kelp,
mussels, starfish, sunken boats and the North Sea wreck) and `seabed_props_coral_reef.png`
(tropical water: corals, sponges, seagrass, a giant clam and the reef's galleon); they fade
into the water colour with depth like the seabed.
`art_source/` holds the source sheets (generated images) and is not imported by Godot. The boot
splash (`assets/ui/splash.png`: `art_source/splash.png` with the title in its sky) and the menu
icons (`icon_coins/map/trophy/book/cog.png`, cut from the menu sheet) are made by
`tools/make_menu_art.py`; the logo and the app icons (`logo.png`,
`icon.png`, `icon_foreground/background.png`) are rendered by `tools/make_logo.py` from the
painted sprites and the Luckiest Guy font (Apache 2.0, in `art_source/fonts/`).

The UI theme (`src/scenes/ui/main_theme.tres`) uses Luckiest Guy for buttons and titles
(`TitleLabel` type variation) and Fredoka (OFL, semi-bold) for body text, both in
`assets/fonts/`. Buttons, panels, cards, bars and the panel backdrop are hand-written SVGs in
`assets/ui/frames/`, used as nine-patch `StyleBoxTexture`s; cards are drawn in grey and tinted
by `OverlayPanel.card_style()`.

The view is 2:1 isometric (like Diablo II). Game logic runs in flat ground coordinates and only
drawing projects to the screen, see `src/scenes/world/iso.gd`.

**Screenshots:** `tools/screenshot.gd` runs the game in a window, optionally performs a scripted
net drag through the real input path, and saves PNGs:

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . -s res://tools/screenshot.gd -- --out=C:/temp/shots --drag
```

## Building the Google Play release

The **Android Play Store** export preset builds a signed `.aab` (Gradle build, arm64) into
`build/fishy-mcfish.aab`. The **Android** preset stays the quick debug APK for the phone.
`tools/build_android_release.sh` only builds and verifies the bundle; uploading it in Play
Console is done by hand.

Run it with **Ctrl+Shift+B** in VS Code (`.vscode/tasks.json`), or:

    & "C:/Program Files/Git/bin/bash.exe" tools/build_android_release.sh [--bump]

`--bump` raises `version/code` in the Play Store preset by one (Play rejects a repeated code);
also raise `config/version` in `project.godot` when the player-visible version changes.

The upload keystore and its password are in 1Password (personal account, vault Gaming, item
"Fishy McFish Key"; the keystore is attached and also stored base64 in the `keystore_b64` field).
The script reads the item once, writes the keystore to a temp folder and deletes it on exit, so
no secret lands in `export_presets.cfg` or the repo. Keep one offline backup of the keystore.

One-time setup: install `platform-tools`, `build-tools;35.0.1`, `platforms;android-35` and
`cmdline-tools;latest` in the Android SDK. The `android/` build template is generated and
git-ignored (Project > Install Android Build Template).

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


## TODOs
- Improve walking animation
- Animate all species properly, replace un-animateable sprites for species
- Replace wrong species sprites and fact-check species info panels
- Beach and seafloor textures for all locations
- Improve layout of the "walk-on" buttons to avoid accidental buys
- Sprite errors for the wader
  - Swimming Mask even in first zone doesn't make sense
  - Snorkel still there for scuba gear and breather
  - Submarine back sometimes has details and sometimes not - flickering when moving - could be fixed by just mirroring the one without details
- Clarify what the basket logic is when in the hardhat suit / submarine. Basket + Scuba gear?
- Clarify if the wader should swim on deeper levels?
- Replace too small buyers, sellers, shop and tanks with better sprites
- Fix the buyers queue and where the selling spots are
- Replace drone sprites with transparent ones where the nets are see-through. Animate the rotors. Sound?
- Placed objects sometimes hide the wader. Depending on the object the wader should completely walk over it (like stones) or he should be blocked by the object (like the tank and shop)
- It looks like the wader falls of the pier. Maybe make the pier sprite without poles? Or some "fall down" animation? Could be funny.
- Some zones have names like "seagrass bay" but you don't see seagrass. We should add these objects depending on the names. Will require more sprites.
- Comic style sprites for the zone-barriers
- Barriers to the left and right could be more natural. Make them rocks or some other obstacles instead of invisible walls
- English texts still say "backpack" while the item is a basket
- Basket, net and snorkel buying should be next to each other since they all "equip" the wader
- Achievements should be harder to reach and should be celebrated more. Possible connection to Google Gamecenter Achievements?
- Walking sound is annoying. Replace with a better sound
- Improve coin look when the coins are flying. They are too small and not comic-style enough. Maybe they could spin?