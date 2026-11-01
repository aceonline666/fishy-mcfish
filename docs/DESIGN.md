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
- **View:** a 2:1 isometric fishing spot (like Diablo II), one portrait screen. Fish swim with simple steering: wander, school together and startle when the character comes close.
- **Character:** a **wader** with a hand net at shallow spots. Gear upgrades turn the character into a snorkeler, then a scuba diver, then a submersible for deeper layers.
- **Walk and scoop:** touch the screen and the character walks towards the finger; drag to steer, lift to stop. Fish that come within reach of the net are scooped up automatically. Larger fish start a **struggle meter**: they must stay in the net for 0.3 to 2 s while they wriggle. That gives a little skill moment.
- **Capacity and combos:** catches stack up visibly in the wader's **backpack** (the boat's **live-well** at deeper layers), which is the trip capacity. Catches in quick succession build a **combo** with rising feedback.
- **Storing:** walk onto the **"Store fish" square** and the fish fly one by one from the backpack into the first tank with room. Fish are **stored, not sold**.
- **Beach aquarium (M2):** the business is on the beach of the same walkable spot, and the camera follows the wader. Squares act while you stand on them: Store fish, Fish market (sell the catch directly), Collect coins, and pay-to-build squares (build tank, bigger tank, bigger backpack; partial payments are kept). **Visitors** come while the tanks have fish, pay at the ticket booth, and admire a tank; their coins pile up at the booth until collected. Income per fish = 1 % of its current value per second, and value grows ×1 → ×3 as the fish grows up. The first version has **tank space only**; food and filters come with rarer species.
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

> **As built (locations):** locations come from data/locations.csv and unlock with a goal plus a one-time travel fee; the World map travels between them. The home spot holds the aquarium; other spots only have a dock ("Ship home", market). Tank slots have an environment (data/tank_slots.csv): a temperate row and a tropical row behind it, opened once a tropical location is unlocked. Drones working in another location's zone deliver home without being seen.

> **As built (shops):** visitors and the ticket booth were replaced by fish shops, as in the original design: money comes from selling. Each shop has a "Sell fish" square (one fish every 0.3 s: the backpack first, then the most valuable fish from the tanks). Shops are built like tanks, in a row behind the first tanks; one hired seller per shop sells grown fish automatically, also offline. A "Better net" upgrade lands struggling fish faster.

> **As built (zones for shops and drones):** shop N sells only the fish of zone N (a species belongs to the shallowest zone it lives in, at any location), so every new zone calls for another shop (1K, 8K). Its seller sells that shop's fish, most valuable first, grown or not, for steady automatic income. Drone N fishes zone N once charted and is bigger, carrying 3/4/5 fish. Backpack fish that no shop buys and no tank takes are let go on a shop pad, so they never block the backpack. Pads are big rounded slabs on the isometric grid (360 × 220 ground units), and the home beach is laid out in five columns (2100 units wide); zone fish populations scale with the spot's width.

> **As built (shop buys everything):** on the phone a Reef tank filled up with moon jellyfish that the level-3 shop was not allowed to buy (they live in the fourth zone); they kept breeding to the breeding limit and the sellers earned nothing. Now the shop buys every fish and a shop level only makes room for one more seller. When the tank is too full to breed, sellers also sell from the breeding pairs, so no tank can clog up.

> **As built (one tank, one shop, breeding):** playtests on the phone showed that sellers dried up (they sold the tanks empty) and that many tanks and shops made the beach crowded. Now each beach has **one tank and one shop**, both upgraded in place (tank: 7 levels, 60 L to 60,000 L; shop: 6 levels from fish stall to seafood palace, level N buys the fish of zones 1 to N). Two or more fish of a species in the tank **breed** (one young per pair every 2 growth times) while the tank is under 80 % full, so the tank keeps producing. Sellers (one per shop level, 10 fish/min each) and the "Sell fish" pad sell only grown fish from the tank and always leave a breeding pair, which makes sellers a steady income. Pad selling speeds up with every fish (0.15 s down to 0.04 s). Time away is simulated in up to 24 steps so breeding and selling continue offline. The beach is 2920 units wide with a pad-free boardwalk in the middle; fish populations no longer scale with the width (fewer, less crowded fish), and off-screen fish are neither drawn nor school.

> **As built (no breeding, tank water):** breeding was removed: it was hard to explain and would have needed an inventory to manage which fish stay. The tank holds what the player or the drones stored, fish grow to adults, and sellers sell every grown fish in the order they grew up: a fish that grows up queues behind the grown ones, so the line in the pipe never jumps. The idle income now comes from the drones, which fish until the tank is full (100 %) and then rest on the ground; offline they do the same. The tank draws how full it is: its water rises with the fish in it and, once not even the smallest fish fits any more, spills over the rim into a puddle while fish jump. Only grown fish can be sold: the store pad is called "Put in tank" and stands in front of the tank, and the "Sell fish" pad is greyed out ("No grown fish") until a fish in the tank is grown; small common fish grow in 30 s to 75 s, and caught fish come in at a random stage of growth (one in ten already grown), so the first sale comes quickly and fish grow up one after the other; it sells one fish every 2 s at the player's booth, which only takes buyers while the player stands on the pad; every seller has a booth of their own and sells as fast (30 fish a minute), also offline. One line of buyers feeds the next free booth, so a seller doubles the selling rate and bigger tanks call for more sellers; each shop level adds booths (1, 2, 4, 7, 11, 15 sellers), so the small stall grows into a busy seafood palace; the backpack is never sold. Bigger tanks grow fish faster (the `speed` column of tanks.csv, ×1 to ×3), and a bar above the tank counts down to the next grown fish. Buyers line up at the shop from the start, one every 3 s, until the line reaches past the screen; each sale, by the player or a seller, serves the first in line. Catch that does not fit into the tank stays in the backpack: there is no bin and no letting go, as in idle arcade games; a blocked backpack is the reason to upgrade the tank. The net lets through fish the tank cannot hold yet (too big for it), so the backpack never fills with fish that cannot be stored; they still count as caught for the Fishpedia, charting and goals, and a bubble names the tank they need. The backpack belongs to its location and is saved, so the player can travel with fish in it and find them again on return. The beach is split by the pier: left the business (tank and shop at the back, joined by a sales pipe that shows the grown fish in selling order (first grown first) with their prices; pads stand in front of what they belong to: "Put in tank" before the tank, "Sell fish" before the player's booth, "Hire seller" before the sellers' booths; the sales booths stand in a row at the back of the beach, beyond the wader's reach, facing north: sellers seen from behind, buyers facing the player, who come in along a lane behind the booths and leave up the beach; booths and sellers are drawn as placeholders), right the upgrades (net, diving gear, drones, backpack, bigger tank), later perhaps a shop of its own. The pipe is drawn in code as a placeholder. The water, air, overflow and puddle layers are SVG placeholders in `assets/sprites/props/tank_*.svg` until the final tank art (empty glass, no painted water) exists.

## A7. Automation
> **As built (M4, walking world):** depth zones are bands of water further from the shore (data/zones.csv), opened by diving gear bought on the beach. A zone is charted after 25 catches there plus every common and uncommon species of it. **Drones** (bought on the drone pad once a zone is charted) fly over charted zones, deepest first, lift only species the player has caught, and deliver to the tanks (sold if no room). Offline they fill tanks at a reduced rate. Instead of sales staff, a **cashier** at the ticket booth takes visitors' coins straight to the wallet.

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
- **Perspective:** **2:1 isometric**, like Diablo II. The ground (beach, seabed tiles, rocks) is drawn in the projection, and characters stand upright facing the camera.
- **Fish are drawn side-on**, as isometric sprites usually are: chunky comic bodies with a big eye, mirrored when swimming left, slightly tilted with the swim direction and shortened when swimming toward or away from the camera. Side-on also makes real species easy to recognise. Exaggerate signature features such as the clownfish stripes and the swordfish bill. **Flatfish** (plaice, halibut) are the exception and need a top-down variant.
- **Animation without frame sheets:** one side-on sprite per species, cut into body and tail fin. Most fish beat the tail fin; eels, whales, rays, turtles and other slow swimmers bend as a mesh with a wave running down the body; jellyfish and octopuses squeeze the bell or head and let the arms trail; squids squeeze the mantle and pull the arms together (`FishArt.MOTIONS`). This keeps AI asset volume small and consistent. The wader needs 4 to 8 facing directions with a short walk cycle.
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

> **As built (localisation):** English and German. Texts are written in English and used as gettext message ids; translations live in `localization/de.po` (no `localization.csv`). Data texts (species, zones, goals, ...) are translated where they are shown. The game follows the device language; the game menu switches it and the choice is kept in `user://settings.cfg`. A test fails for any shown text without a German translation.

> **As built (a business per location):** every location has its own beach business (`Site`: tanks, shops, sellers, drones, backpack, net, gear, payments in progress), started from scratch on the first visit; coins, the Fishpedia, charted zones and goals are shared. Prices scale with the location's `price_factor` (Coral Reef 2.5). Tanks hold their location's water, so the tropical tank row at home is gone; old saves move their tropical tanks to the Reef. Sellers and drones keep working at the other locations (drones at the slower unwatched rate).

> **As built (deep sea):** both locations have six zones down to the deep sea (North Sea: Pier shallows, Sandbanks, Wreck, Open sea, Norwegian Trench, Deep sea; Coral Reef: Lagoon, Reef crest, Drop-off, Open ocean, Twilight zone, Trench) with 23 more species, among them jellyfish, tuna, sunfish, sharks, octopus, anglerfish, giant squid, whales, turtle, manta ray, nautilus and coelacanth. Gear, nets, backpacks, tanks (up to a 25,000 L Ocean dome), shops, sellers and drones go up to six levels; each diving gear swims faster (its `capacity`). The water darkens towards the abyss. The bot charts the North Sea's deep sea after about 4 h and finishes both maps after about 7 h.

> **As built (more maps):** Australia (Great Southern Reef), Japan and South Africa follow the Coral Reef, each with six zones down to the deep and its own species (86 in all), among them seadragons, the blue-ringed octopus, stingrays, great white and goblin sharks, the Japanese spider crab, fugu, opah, giant isopod, oarfish, the Knysna seahorse, the sardine run, the leatherback turtle, the Portuguese man o' war, southern right and humpback whales and the colossal squid. Each opens by charting the third zone of the previous map plus a fee; prices scale 6, 15 and 40 times. Global giants (sunfish, giant squid, sperm whale, loggerhead) appear where they really live. The bot finishes all five maps after about 15 h.

> **As built (game menu):** a cog button opens the menu: save, load (back to the last save, without offline progress) and new game with an inline confirmation; sound effects and music (a CC0 tropical loop) on their own audio buses (`Sfx`, `Music`), each with an on/off switch and a volume slider; and the language. Panels rebuild themselves when the language changes.

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
