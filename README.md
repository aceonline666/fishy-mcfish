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
| `src/sim/` | Simulation systems (from M2) |
| `src/scenes/` | Scenes and their scripts |
| `tests/unit/` | GUT tests |

Rules of thumb:
- All GDScript is statically typed. Untyped declarations are errors.
- Game logic lives in `src/model/` and `src/sim/` so it can be tested and simulated headless.
- Platform-specific code only goes into `Platform`.
