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

A new game starts with a short tutorial: a card at the top says what to do next and a golden
arrow shows where to walk: fill the basket, put the catch into the tank, sell a grown fish at
your booth, then go into the gear shop, where a small arrow over each pad says what it is for
until you buy something or leave. Saves from before the tutorial skip it.

Up on the beach, pads act while you stand on them (walking on sand is faster than wading). A
boardwalk in the middle leads from the water to the back of the beach without crossing any pad.
Left of it is the business, right of it the upgrades (net, diving gear, drones, backpack, tank).
Each beach has **one tank and one shop**, which are upgraded instead of building more. The sales
booths continue the pier in a line up the beach, buyers queueing on their east side. The tank is
solid and grows from 1 × 1 west, then up the beach to 3 × 5 cells; a conveyor belt from its back
up to the last booth carries the grown fish in the order they will be sold, each with its price.
The shop is not a building: its level gives every booth its look:
- **Put in tank**, in front of the tank, puts the catch into it (big species need a big tank). Caught fish are
  partly grown already, one in ten fully. Fish grow in the tank, faster in bigger tanks; only grown fish can be sold, for three times their young value.
  A bar above the tank counts down to the next grown fish. The tank shows how full it is: its
  water rises with the fish in it and runs over at 100 %.
- **Sell fish** in front of the shop is greyed out ("No grown fish") until a fish is grown, then
  sells the grown fish from the tank, first grown first, to the buyers lining up there from the start. The shop buys
  every fish; **More selling space** (gear shop) adds booths for more sellers (1, 2, 3 and
  finally 4), and every shop level pays more for the fish (up to 1.4 times the price,
  `price` in `data/shop_levels.csv`); the last two levels only raise the price. The first hired seller takes over your booth and the "Sell fish" pad. While you stand on the pad you
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
lists achievements with coin rewards. Goals marked `hidden` in `data/achievements.csv` are
secrets: they show as "???" until reached (a `stat` goal counts a value in the player's stats,
named in `param`).

**Secrets:** after the tutorial, every location hides a treasure chest on the seabed of the
deepest zone the gear opens, but no further out than the fourth zone (beyond it the dark water
would hide it), with a glint over its coins (`src/sim/treasure.gd`,
`src/scenes/world/treasure_chest.gd`). Scooping it up pays the price of 25 grown fish of that zone
plus five minutes of the location's seller income; it turns up somewhere else 20 hours later.
Secret goals: finding chests, catching a fish between midnight and 4 a.m., and keeping still for
a minute in a location's deepest zone. The **Map** travels between five locations: North Sea,
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
the painted sheets in `art_source/fish/` by `tools/extract_painted.py` (needs Pillow, NumPy and
SciPy; run it once per sheet; a later sheet replaces sprites of an earlier one). A species
without sprites would be drawn as a coloured placeholder. The wader, the tank (one sprite per level), the shop (one per level), the
cashiers, the customers who queue at the shop while sellers work and leave with a fish, and the
beach decoration are painted sprites in `assets/sprites/props/`, cut from the coastal sheet by
`tools/extract_props.py` (its background checkerboard is removed by flood fill). The gear sheet
adds the drones, the buyers carrying their fish, the pictures of the
nets, diving gear, tanks, shops and drones on the upgrade pads, and the location pictures of the
World map. The wader comes from one sheet per depth zone, `art_source/characters/wader_zone_<n>.png`
(waders with basket, snorkel, scuba, rebreather, hard-hat suit, submersible; generated from
`wader_sprite_prompt.md` next to them), cut by `tools/extract_wader_sheet.py` into five views
of a standing frame and four painted walk frames. The landing nets (second
equipment sheet) and the baskets on the backpack pad (first equipment sheet) are cut by
`tools/extract_wader.py`. The ground tiles come from `tools/make_seafloor.py`: a location's own
seamless tiles `art_source/ground/seafloor_<id>.png` (seabed under the water) and
`art_source/ground/beach_<id>.png` (beach sand), otherwise a seabed made from the seafloor sheet;
the prompts they were generated from lie next to them. The props on the seabed are cut by
`tools/extract_seabed.py` from `art_source/ground/seabed_props.png` (temperate water: rocks, kelp,
mussels, starfish, sunken boats and the North Sea wreck) and `seabed_props_coral_reef.png`
(tropical water: corals, sponges, seagrass, a giant clam and the reef's galleon); they fade
into the water colour with depth like the seabed.
Sprites are imported as lossy WebP at quality 0.9 (the project's import default): about a third
of the lossless size, with the same pixel sizes. `build/` and `art_source/` are left out of the
export; the screenshot tools put a `.gdignore` into their output folder so Godot does not import
the shots.
`art_source/` holds the source sheets (generated images) and is not imported by Godot, sorted by
subject: `fish/`, `characters/` (wader and divers), `props/` (coastal and gear sheets),
`buildings/` (booths, gear shop, pier), `tanks/`, `ground/` (beach, seafloor and seabed props),
`ui/`, `plans/` (layout sketches) and `fonts/`. The prompts and perspective guides for generating
an image lie next to it. The boot
splash (`assets/ui/splash.png`: `art_source/ui/splash.png` with the title in its sky) and the menu
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

**Profiling:** `tools/profile.gd` runs the game in a window on a copy of your autosave (or
`--save=<path>`; the save itself is never written), prints the frame time, draw calls and memory,
then hides and pauses each kind of node in turn and lists what each one costs per frame:

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . -s res://tools/profile.gd
```

Something drawn in `_draw()` and redrawn every frame (`queue_redraw()` in `_process`) is rebuilt
from scratch each time: draw static shapes once in their own node and only move the node.

## Building the Google Play release

The **Android Play Store** export preset builds a signed `.aab` (Gradle build, arm64) into
`build/fishy-mcfish.aab`. The **Android** preset stays the quick debug APK for the phone.
`tools/build_android_release.sh` only builds and verifies the bundle; uploading it in Play
Console is done by hand.

It also writes `build/native-debug-symbols.zip`: Godot's published debug symbols for the release
template (downloaded once, 780 MB, into `build/cache/`), cut down to the ABIs in the bundle. Upload
it with each bundle (App bundle explorer > the version > Downloads > Native debug symbols) so crash
reports show Godot's function names. The Play warning about a missing deobfuscation (R8/ProGuard)
file can be ignored: the build does not shrink or obfuscate the Java code, so there is no mapping.

Run it with **Ctrl+Shift+B** in VS Code (`.vscode/tasks.json`), or:

    & "C:/Program Files/Git/bin/bash.exe" tools/build_android_release.sh [--bump]

`--bump` raises `version/code` in the Play Store preset by one (Play rejects a repeated code);
also raise `config/version` in `project.godot` when the player-visible version changes.

The upload keystore and its password are in 1Password (personal account, vault Gaming, item
"Fishy McFish Key"; the keystore is attached and also stored base64 in the `keystore_b64` field).
The script reads the item once, writes the keystore to a temp folder and deletes it on exit, so
no secret lands in `export_presets.cfg` or the repo. Keep one offline backup of the keystore.

**Store graphics** (texts and Console answers in `docs/play_store_listing.md`): the icon, the
feature graphic and the phone screenshots in `art_source/play_store/` are made by
`tools/make_play_store_art.py`. It frames the screenshots with a caption; take the game pictures
for them first, once per language (they land in the git-ignored `build/store_shots/`):

```powershell
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . -s res://tools/store_screenshots.gd -- --out=build/store_shots/en --lang=en
& "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . -s res://tools/store_screenshots.gd -- --out=build/store_shots/de --lang=de
python tools/make_play_store_art.py
```

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
runs the same bot and checks the pacing targets (first tank upgrade after 5–20 min, snorkel 5–25 min,
Coral Reef 25–70 min, open sea charted after 55–120 min). The bot reaches the North Sea's
deep sea after about 3 h and opens Japan, the fourth location, after about 5 h. Its report
every 10 minutes shows how busy each beach's sellers were. Run it after
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
| `src/scenes/world/` | Isometric projection, layout grid (`Grid`), drawing layers (`Layers`), play area and seabed decoration |
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
- Gear shop music: "Buy Something!" ("Shop Theme") by CleytonKauffman, CC0
  ([OpenGameArt](https://opengameart.org/content/shop-theme)).

## TODOs
- Fine tuning for tank fill-up and tank-is-full-animation
- Helipad and tank are too close together. Maybe we can move the tank a bit up north (1 unit?) and also the helipad (1/2 unit?)
- Make the species sprites consistent. Some are very comic-style (sheet 5) and some are very realistic. We want a cute-comic style so I fear we have to regenerate a large part of it. Also want a proper isometric view instead of the current side view. This should look better for the game. Maybe do a test with a single species before we regenerate all sprites.
- Turtle animation should move their flippers instead of "squeeze" them
- The last two zones should get a heavier wave animation to make an "open sea" impression
- More secrets (need new sprites, postponed):
  - an original deep sea horror in the deepest zones, barely visible at the edge of the dark
  - glowing eyes in the dark that vanish when you come close
  - message in a bottle, rare finds (curiosities page in the Fishpedia)
  - secret species per location that only show under a condition (night, charted zone, ...)

### Later 
- ~~Add new locations. Ideas:~~
  - ~~Antarctic sea (Orcas, pengiuins? black smokers in the deep zones?)~~ (penguins and everyday fish still to come: `species_sheet_14_prompt.md`)
  - ~~Jurasic sea (with ichtyosaurs, plesiosaurs, leopleurodon, ammonites etc?)~~ (middle-sized species still to come: `species_sheet_14_prompt.md`)
- Add more species - mostly the well known ones
  - ~~Whale Shark~~
  - ~~Orcas~~
  - Hammerhead Shark
  - ~~Baracuda~~
  - ~~Dolphins~~
  - Seasnakes
  - ~~Seals~~
- Add weather and day cycle: Storms, Lightning, Night. Day and Night could sync with real time.
- Connect the achievements to Google Play Games achievements (needs achievement IDs from the Play Console - which requires a Google Cloud Project - which would cause costs)
  
