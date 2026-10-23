# Fishy McFish: Design Draft & Technical Implementation Plan

## Context
Greenfield project (`d:\WORKSPACE\Games\Fishy McFish` is an empty git repo). Goal: a simple, satisfying **idle fish-collecting game**, Android first with iOS later. You catch real ocean species by dragging on the screen, keep them in aquariums, sell them to afford bigger tanks and infrastructure, unlock new locations and depths through achievements, and later automate catching (drones) and selling (sales staff).

**Decisions made:**
- **Engine:** Godot 4 (latest stable at project start, pinned), with statically typed GDScript.
- **Business model:** a premium game, paid upfront, with no ads and no IAP. That means no ad SDKs and no receipt backend, and the economy must be fair rather than built around paywalls.
- **Backend:** offline first, with local saves. Cloud saves come later via Google Play Games Saved Games (and iCloud/Game Center on iOS).
- **Art:** AI-assisted with manual cleanup, so the pipeline must enforce a consistent style.

---

# PART A: DESIGN DRAFT

## A1. Design pillars
1. **One-finger satisfaction.** Every catch has punchy feedback: splash, wiggle, coin pop and haptics. Catching several fish in one swipe triggers combos.
2. **Real ocean, comic charm.** Every species is real (common name plus scientific name), drawn as an expressive cartoon with a short fun fact.
3. **Space is the pressure.** The tension comes from tanks filling up. You sell, then upgrade, then catch bigger fish. That is the whole loop.
4. **Earn your automation.** You can only automate what you have done by hand. Exploring stays manual; repetition becomes idle.
5. **Respect the player (premium).** There are no timers made to annoy, no fish deaths and no lost progress. Neglect slows growth but never punishes.

## A2. Core loop
```
          ┌──────────── upgrade (tanks, filters, food, gear) ◄─────────────┐
          ▼                                                               │
  [FISHING] drag net → catch → boat live-well ─► [AQUARIUM HALL] place fish │
     ▲                                             │ fish grow (value ↑)   │
     │ travel / dive deeper                        ▼                       │
  [WORLD MAP] ◄── achievements unlock ──  [SELL] manually or by staff ──► money
                                                  ▲
                      drones auto-catch on charted layers (idle)
```
- **Short loop (30 s):** go fishing, then put the catch into tanks.
- **Mid loop (5 to 15 min):** tanks fill up, so you sell grown fish and buy an upgrade.
- **Long loop (hours or days):** chart a depth layer, automate it, meet an achievement, then travel to a new location.

## A3. Fishing mechanic (the "feel" core)
- **View:** a top-down ocean patch (portrait, about 1.5 screens tall, with a slight scroll). Fish swim with simple steering: wander, school together and flee from the net.
- **Net drag:** touching the water spawns a net under your finger, and dragging moves it. Small fish the net passes over are scooped up instantly. Larger fish start a **struggle meter**: you keep the net on them for 0.3 to 2 s while they wriggle and try to escape. That gives a little skill moment.
- **Net capacity:** the net holds N fish (upgradeable). Lifting your finger "lands" the haul into the boat's **live-well** (trip capacity). Catching several fish in one drag gives a **combo** bonus (+XP and a bigger splash).
- **Rare fish** appear briefly (with a sparkle and a sound cue), move faster and dart away. Some need a **lure** (a consumable bought with money) to appear at all.
- **Trip end:** when the live-well is full, or you tap "Return", the catch goes to the **Intake Tank** in the hall. From there you drag fish into display tanks; auto-place is available.
- **Depth layers:** a depth slider on the side switches layers. Deeper layers get darker, with a vignette and bioluminescence, and require gear.

## A4. Aquarium mechanics (kept deliberately simple)
Each tank has these properties:

| Property | Meaning |
|---|---|
| **Volume (L)** | Each fish occupies `space_L`. A species may also need `min_tank_L`, so big fish need big tanks. |
| **Environment** | Temperate (default), Tropical (needs a heater), Polar (needs a chiller), Abyssal (needs a pressure and darkness module). Fish only go into a matching tank. |
| **Filter capacity** | The sum of fish `bioload` values must not exceed it. If it does, water turns murky and growth pauses. Nothing dies. |
| **Food** | Each species needs a food tier: Flakes, then Pellets, Frozen krill, Live shrimp, Squid & fish, and Deep-sea mix. Food is a stock in the shed that is used up per hour. Without food, growth pauses. |

- **Growth:** fish arrive as juveniles. Over `growth_time` (from minutes for common fish to hours for legendary ones) their sale value rises from ×1 to ×3. A grown fish shows a ⭐ badge. That is the idle reward and a reason to hold fish before selling.
- **Hall:** a top-down floor with tank slots. Expanding the floor adds slots. Tanks are upgraded in place (Bucket 20 L → Small 100 L → 500 L → 2,000 L → Exhibit 10,000 L → Ocean Dome 250,000 L).

## A5. Economy (first-pass formulas, tuned via a balance sim)
- `sale_price = base_value × growth_mult(1→3) × condition(0.8 to 1.0)`
- `upgrade_cost(n) = base_cost × growth_rate^n` (growth_rate between 1.12 and 1.25 per item type)
- `base_value` roughly ×8 to ×15 per rarity tier (Common, Uncommon, Rare, Epic, Legendary)
- Optional **Market demand:** each day one or two "hot species" sell at ×2. This adds variety at no cost.
- **Target pacing for a premium game:** the first upgrade within 2 min, the first new location around 45 to 60 min, the full game about 25 to 40 h. After that comes an optional prestige (A12).

## A6. Progression: locations, depth layers and species
Each location has three or four **depth layers**. Every layer starts **uncharted** (fogged). You **chart** a layer by hand by discovering all of its Common and Uncommon species and catching 25 fish there. Only charted layers can take drones.

| # | Location (unlock) | Layers | Example species (real) | Env. |
|---|---|---|---|---|
| 1 | **North Sea Harbour** (start) | Pier · Sandbanks · Wreck | European sprat, Atlantic herring, Lesser sand eel, Atlantic mackerel, European plaice, Lumpsucker, Atlantic cod, Atlantic wolffish, Conger eel | Temperate |
| 2 | **Coral Reef (Indo-Pacific)**: chart Sandbanks, own a heater, travel fee | Lagoon · Reef crest · Drop-off | Ocellaris clownfish, Blue-green chromis, Blue tang, Mandarinfish (live food), Red lionfish, Blacktip reef shark, Humphead wrasse | Tropical |
| 3 | **Kelp Forest (California)**: 30 species in the Fishpedia, a 2,000 L tank | Canopy · Mid-kelp · Rocky floor | Garibaldi, Kelp bass, Pacific seahorse, California sheephead, Leopard shark, Giant sea bass | Temperate |
| 4 | **Open Ocean (Atlantic)**: hire 3 staff, own a Trawler | Surface · Epipelagic · Mesopelagic | Flying fish, Mahi-mahi, Atlantic bluefin tuna, Swordfish, Ocean sunfish, Whale shark | Tropical, large |
| 5 | **Arctic Waters**: chart every layer of 2 locations, own a chiller | Ice edge · Shelf · Fjord deep | Polar cod, Greenland halibut, Atlantic wolffish (polar morph), Greenland shark | Polar |
| 6 | **Deep-Sea Trench**: Submersible, pressure module, 75 species | Twilight · Midnight · Abyss | Lanternfish, Marine hatchetfish, Pacific viperfish, Humpback anglerfish, Giant oarfish, West Indian Ocean coelacanth | Abyssal |

- **Gear gates depth:** Rowboat, then Trawler, Diving bell and Submersible. Each one unlocks deeper layers.
- **Achievements** serve two roles: they are unlock keys and they are a checklist with small rewards. Examples are "Catch 5 in one swipe", "First Legendary" and "Fill a 10,000 L tank".
- **Fishpedia:** a collection book with a side-profile illustration, scientific name, real size, habitat and a fun fact for each species. Completion percentage is a long-term goal.

## A7. Automation
- **Sales staff** (hired in the Staff screen): each person sells X fish per minute from the tanks assigned to them. Their policy can be "only grown ⭐", "overflow only" or "everything except favourites". Levelling up raises speed and adds a price bonus. There are 1 to 2 slots per hall section.
- **Drones:** each drone is assigned to one **charted** location and layer. It catches Y fish per hour from that layer's spawn table (weighted toward common fish) and delivers them to the Intake Tank. When intake is full, the drone idles and shows a 💤 icon. That gives soft pressure to expand. Drone tiers cap the reachable depth.
- **Auto-feeder** (per tank) and **Supply contract** (food is bought automatically with money).
- **Rule:** drones never discover new species. Discovery is always manual.

## A8. Offline progress
On resume, the game simulates the elapsed time with the same sim code, using large time steps (staff sells, drones catch, fish grow and food is consumed). Offline time is capped at 8 h, and upgrades raise the cap to 24 h. A "While you were away…" summary card plays a satisfying coin count-up.

## A9. Screens & UI (portrait 1080×1920, one-handed)
A bottom nav bar holds **Hall · Fishing · Map · Staff · Shop**. Fishpedia and Settings sit in the top-right menu. The top bar shows money, current trip capacity and a notification bell.

```
┌──────────────────────────┐   ┌──────────────────────────┐
│ 💰 12.4K      📖  ⚙     │   │ 💰 12.4K  North Sea·Pier │
│──────────────────────────│   │ ~~~~~ 🐟 ~~~~ 🐟🐟 ~~~~ │ ▲ depth
│ ┌──────┐ ┌──────┐ ┌───┐ │   │ ~~ 🐟 ~~~~~~ (net) ~~~ │ │ slider
│ │~🐟~🐟│ │~~🐠~~│ │ + │ │   │ ~~~~~~ 🐡 ~~~~~ 🐟 ~~~ │ ▼
│ │ 4/6  │ │ 2/3⚠ │ │   │ │   │ ~~ 🐟🐟 ~~~~~~~~~~~ 🦈~ │
│ └──────┘ └──────┘ └───┘ │   │──────────────────────────│
│  [Intake: 7 fish ▸]     │   │ Live-well ▓▓▓▓░░ 8/12    │
│  🧑‍💼 Selling… +240/min   │   │ [Return to harbour]      │
│──────────────────────────│   │──────────────────────────│
│ Hall  Fish  Map  Staff Shop│ │ Hall  Fish  Map  Staff Shop│
└──────────────────────────┘   └──────────────────────────┘
        Aquarium Hall                    Fishing
```
- **Tank detail sheet** (tap a tank): fish list with growth bars, filter and food meters, Sell / Move / Upgrade.
- **World map:** an illustrated comic map with location pins, a lock icon plus the achievement checklist, and per-layer chart status and drone slots.

## A10. Art direction & AI-assisted pipeline
- **Style:** a bold comic look with thick dark outlines (about 6 px at 1080p), flat colours with one cel-shade step, saturated water blues and a warm UI (wood or rope harbour theme).
- **The POV issue:** real species are hard to recognise from directly above. **The fix:** in-world sprites use a **high three-quarter top-down** angle (tilted about 30°, so the side and fins stay visible) with exaggerated signature features such as the clownfish stripes and the swordfish bill. Fishpedia cards use a **side-profile** illustration.
- **Animation without frame sheets:** one sprite per species plus a **swim shader** (a sine-based vertex or UV wobble along the body axis, with tail amplitude larger than head). Separate fin or tail parts are added only for hero species. This keeps AI asset volume small and consistent.
- **Pipeline:**
  1. Write a style bible: palette, outline weight, three reference fish and a prompt template.
  2. Generate several variants per species.
  3. Clean up in Krita or Aseprite: fix anatomy against reference photos, unify outlines and palette.
  4. Export at 2× (for example 512 px on the long edge).
  5. Pack into atlases using the Godot import presets.
- Check the AI tool's commercial-use licence. Keep a `ART_SOURCES.md` log.
- **Placeholder phase:** coloured silhouette shapes with the species name, so gameplay never waits for art.

## A11. Audio & haptics
Use short splash and pop sounds with pitch variation, a combo "ding" ladder, a coin cascade, and calm ambient water and harbour loops per location. Haptics: a light tick per catch and a stronger one for rare fish and combos. All of it can be toggled.

## A12. Premium positioning
- Expect 6 locations, about 60 species and around 30 h of progression, with no ads and no IAP.
- **Post-game:** the **Marine Conservation Foundation** prestige. You release your collection into reserves for "Reputation", which gives a permanent sale and catch multiplier. Its scope is decided after launch.
- **Content updates** add new locations, which the data-driven design makes cheap.

---

# PART B: TECHNICAL IMPLEMENTATION PLAN

## B1. Stack
- **Godot 4.x stable**, pinned in `project.godot` and the README. Use **statically typed GDScript** with warnings treated as errors where practical.
- **Compatibility renderer** (GLES3) for the widest Android device support. The stretch mode is `canvas_items` with aspect `expand` and a portrait base of 1080×1920.
- **Testing:** GUT (Godot Unit Test) for logic.
- **CI:** GitHub Actions with a headless Godot container, running tests and building a debug APK.
- **Android export:** Gradle build, AAB for Play, `targetSdk` at the current Play requirement.

## B2. Project structure
```
Fishy McFish/
├─ project.godot
├─ data/                 # balancing source of truth (CSV, edited in a spreadsheet)
│  ├─ species.csv  locations.csv  layers.csv  tanks.csv  filters.csv
│  ├─ foods.csv  gear.csv  staff.csv  drones.csv  achievements.csv
│  └─ localization.csv   # EN + DE to start
├─ src/
│  ├─ autoload/          # GameState, DataRegistry, SaveSystem, TimeService, EventBus, Audio, Haptics, Platform
│  ├─ sim/               # pure logic, no Nodes: Economy, TankSim, GrowthSim, StaffSim, DroneSim, OfflineSim, Achievements
│  ├─ model/             # typed data classes: SpeciesDef, FishInstance, TankState, ...
│  ├─ scenes/
│  │  ├─ main/           # Main.tscn (scene router + bottom nav + top bar)
│  │  ├─ hall/           # AquariumHall.tscn, Tank.tscn, TankDetailSheet.tscn
│  │  ├─ fishing/        # FishingScene.tscn, Net.tscn, SwimmingFish.tscn, FishSpawner.gd
│  │  ├─ map/            # WorldMap.tscn, LocationPin.tscn
│  │  ├─ staff/ shop/ fishpedia/ settings/
│  │  └─ ui/             # shared widgets: MoneyLabel, ProgressMeter, CoinBurst, Toast
│  ├─ shaders/           # fish_swim.gdshader, water_caustics.gdshader, depth_tint.gdshader
│  └─ platform/          # PlatformServices interface + AndroidServices / IOSServices / DesktopServices
├─ assets/ (sprites/, atlases/, audio/, fonts/)
├─ tests/                # GUT tests (unit/ + balance/)
├─ tools/                # balance_sim.gd (headless playthrough), csv_validate.gd
└─ .github/workflows/ci.yml
```

## B3. Architecture
- **The simulation is separate from presentation.** `src/sim/*` holds `RefCounted` classes with a deterministic `tick(state, dt)` and no scene dependencies. Scenes only *read* `GameState` and react to `EventBus` signals. Player actions go through command methods such as `GameState.sell_fish(id)` and `GameState.buy_tank(slot, tank_id)`. This makes the sim unit-testable, reusable for offline catch-up and runnable headless for balancing.
- **Autoloads:**
  - `DataRegistry`: parses the CSVs at boot into typed definitions and validates IDs and references. It fails loudly in debug builds.
  - `GameState`: the single mutable save model (money, tanks, fish, unlocked, charted, staff, drones, achievements, stats).
  - `TimeService`: a 1 Hz sim tick while the app is open, plus offline catch-up on resume using `Time.get_unix_time_from_system()`. It has a guard so clock rollback grants nothing.
  - `SaveSystem`, `EventBus` (typed signals: `fish_caught`, `money_changed`, `tank_changed`, `achievement_unlocked`, …), `Audio`, `Haptics` (`Input.vibrate_handheld`).
  - `Platform`: a façade over Android, iOS and desktop services (cloud save, review prompt, safe area).
- **Fish identity:** a `FishInstance` holds `{uid, species_id, caught_at, growth (0..1), tank_id, favourite}`. When a tank holds many fish, only up to about 12 are rendered as sprites and a "+N" label covers the rest. The model still holds every fish.

## B4. Key systems
- **Fishing scene:**
  - `FishSpawner` draws from the layer's weighted spawn table, with a rarity roll modified by lures and gear.
  - `SwimmingFish` is a `Node2D` with a steering behaviour (wander, edge avoidance, flee when the net is within its radius, light schooling for small species). It uses an `Area2D` for overlap.
  - `Net` is an `Area2D` that follows `InputEventScreenDrag`, with mouse emulation for desktop testing. On overlap with a small fish it catches immediately. With a large fish it fills a struggle meter while overlap lasts, and the fish's escape impulse fights the player.
  - When the finger lifts, catches are committed to the live-well and a combo is computed. Juice is centralised in a `Juice` helper (tweens, particles, screen shake, haptics, SFX).
- **Tanks:** `TankSim` validates placement (environment, `min_tank_L`, free space) and computes water quality from bioload and filter capacity. `GrowthSim` advances growth only when the fish is fed and the water is good.
- **Selling:** manual selling uses the tank sheet or a drag to the Market stall. `StaffSim` sells using each person's policy.
- **Drones:** `DroneSim` uses an expected-value catch rate per hour applied over `dt`, with a fractional accumulator. This keeps it deterministic and cheap offline.
- **Achievements:** declarative conditions in CSV (`type,target,param`, for example `catch_count,100,` or `charted_layer,1,north_sea.sandbanks`), evaluated on relevant EventBus signals.
- **Numbers:** money is a `float` (64-bit), formatted with K/M/B/T suffixes via a `NumberFormat` util. The premium pacing does not need big-number libraries.

## B5. Save system
- `user://save.json` holds `{version, saved_at_unix, state}`. Writes are atomic: write to `save.tmp`, then rename, and keep `save.bak`.
- **Autosave** every 30 s, after major purchases, and on `NOTIFICATION_APPLICATION_PAUSED` and `NOTIFICATION_WM_CLOSE_REQUEST`.
- **Versioned migrations:** a `migrations[from_version] -> Callable` chain.
- **Cloud save (later phase):** the same JSON blob goes through `Platform.cloud_save()`. Android uses the Google Play Games Services Saved Games plugin for Godot; iOS uses iCloud key-value or Game Center. Conflicts are resolved with "most progress" (a `total_earned` stat), then the newest timestamp.

## B6. Platform & iOS readiness
- From day one, respect safe areas via `DisplayServer.get_display_safe_area()` and avoid platform APIs outside `src/platform/`.
- **Android:** a premium paid listing on Play. Play Integrity licence checking is optional.
- **iOS later:** the Godot iOS export produces an Xcode project. It needs a Mac or cloud Mac, an Apple Developer account and Game Center/iCloud entitlements.

## B7. Performance targets
- 60 fps on a mid-range device (around 2020 class) and 30 fps minimum on low-end devices.
- At most about 60 animated fish on screen. The swim shader replaces frame animation.
- Use atlased textures and object-pooled fish, particles and coin pops.
- APK/AAB size under 150 MB at launch.
- Profile with Godot's remote debugger over USB.

## B8. Milestones
| # | Milestone | Content | Exit criteria |
|---|---|---|---|
| M0 | **Setup** | Godot project, folder structure, autoload stubs, GUT, CI (tests plus debug APK), Android export preset, deploy to a phone | An empty app runs on an Android device from CI output |
| M1 | **Fishing feel prototype** (greybox) | Net drag, 3 placeholder species, struggle meter, combo, live-well, juice v1 | Playtest: catching feels fun for 5 minutes with no economy at all |
| M2 | **Core economy** | Hall with 3 tank slots, intake, placement, growth, filter and food, manual sell, shop, save/load | The full loop is playable for 20 min in North Sea Pier |
| M3 | **Progression** | CSV data pipeline, 3 layers in North Sea plus the Coral Reef, charting, gear, world map, achievements, Fishpedia | A player can unlock and travel to the Reef |
| M4 | **Automation & offline** | Sales staff, drones, auto-feeder, offline sim plus the summary card | Closing the app for 2 h gives a correct, tested payout |
| M5 | **Balance tooling** | `tools/balance_sim.gd`, a headless scripted player that outputs a time-to-milestone CSV | The pacing targets from A5 are met in simulation |
| M6 | **Art & audio pass** | Style bible, AI pipeline, the first 2 locations fully illustrated, swim shader, UI skin, SFX/music, EN/DE localisation | Vertical slice at release quality |
| M7 | **Content complete** | Locations 3 to 6, about 60 species, all achievements | The whole game can be completed in the balance sim and in manual playtests |
| M8 | **Android launch** | Device matrix testing, performance, store listing, closed test track, then production | Live on Google Play |
| M9 | **Post-launch** | Cloud saves, iOS port, prestige, new locations | |

Build M1 before investing in art. If the drag-net does not feel good with grey boxes, iterate there first.

## Verification
- **Unit tests (GUT, run headless in CI):** economy formulas, tank placement rules, growth and food and filter interactions, staff and drone sims, offline catch-up (equivalence: one 2 h step matches 7,200 one-second ticks within a tolerance), save round-trip and migrations, achievement triggers, and CSV integrity (all IDs resolve, every layer has a valid spawn table).
- **Balance sim:** `godot --headless -s tools/balance_sim.gd` plays a scripted strategy and asserts the pacing windows (for example, Reef unlocked between 30 and 90 min).
- **On-device:** one-click deploy from the Godot editor to an Android phone over USB, plus a manual checklist: drag feel, haptics, pause and resume, offline payout, rotation and safe areas, kill during save.
- **Desktop debug build:** mouse emulates touch, plus a debug overlay (F1) for granting money, time-skip and unlocking a location to speed up QA.

## Main risks
- **The fun of the core mechanic.** Mitigation: the M1 greybox playtest gate.
- **AI art consistency** across about 60 species. Mitigation: the style bible, cleanup pass and a shader-based animation that needs only one sprite.
- **Premium idle pacing** with no ads to smooth the grind. Mitigation: the balance sim and a playtest cohort in the closed track.
- **Recognising species from top-down sprites.** Mitigation: the three-quarter angle plus side-profile Fishpedia art.
