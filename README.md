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

**How to play:** tap the water and the wader walks there; hold and drag to steer. Fish that
come within reach of the hand net are scooped up automatically and stack up in the backpack.
Small fish go in at once; bigger ones (herring, mackerel) must stay in the net until the yellow
ring fills. Catches in quick succession build a combo.

Up on the beach, squares act while you stand on them:
- **Store fish** puts the catch into the first tank with room (big species need big tanks).
- **Fish market** sells the catch right away.
- **Build tank / Bigger tank / Bigger backpack** take coins until paid (partial payments are kept).
- **Collect coins** picks up what visitors paid at the ticket booth. Visitors come as long as
  the tanks have fish; fish grow over a few minutes and then bring in three times as much.
  Income keeps coming while the game is closed.
- **Snorkel / Scuba gear** open the deeper zones behind the buoy lines (Sandbanks, Wreck),
  with rarer and bigger fish. Each zone is *charted* after 25 catches there and every
  common/uncommon species of it.
- **Buy drone** (once a zone is charted): drones fish known species in charted zones and bring
  them to the tanks, also while the game is closed. **Hire cashier**: visitors' coins go straight
  to the wallet.

The **Fishpedia** button lists every species, with facts for the ones you have caught. **Goals**
lists achievements with coin rewards. The **Map** travels between locations: the Coral Reef
opens with the "Sandbank surveyor" goal and a one-time fee. Away from home there is a dock that
ships the catch to the tanks at home; tropical fish need the tropical tank row behind the first.

Locations, zones, species, tanks, gear, drones, staff and goals are all data in `data/*.csv`.

Tests and `tools/screenshot.gd` run in a sandboxed save (`SaveSystem.use_sandbox`), never
the real one.

Sprites are hand-written SVGs in `assets/sprites/` (fish: body + tail per species, see
`src/scenes/fishing/fish_art.gd` for the conventions). Species without sprites are drawn as
coloured placeholders.

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

## Project layout

| Path | Contents |
|---|---|
| `data/` | Balancing data as CSV (species, later locations, tanks, ...). Each CSV needs a `.csv.import` file with `importer="keep"`, otherwise Godot imports it as a translation. |
| `src/autoload/` | Global singletons: `EventBus`, `DataRegistry`, `GameState`, `TimeService`, `SaveSystem`, `Haptics`, `Platform` |
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
