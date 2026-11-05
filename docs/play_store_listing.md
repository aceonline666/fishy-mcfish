# Google Play Console – Fishy McFish

Texts and answers for the Play Console, taken from the game as it is (premium, no ads, no
in-app purchases, no data collected, offline). The image prompts are in
`art_source/play_store/prompts.md`.

## Store listing – English (default language)

**App name** (max. 30): `Fishy McFish`

**Short description** (max. 80):

```
Catch real sea creatures, raise them in your tank and grow a beach fish business
```

**Full description** (max. 4000):

```
Wade into the surf with your hand net and catch real ocean species: sprats, herring, clownfish, seahorses and, much later, sharks, whales and the giant squid.

Fishy McFish is a relaxed idle game about catching, raising and selling fish. Steer your wader with one finger and scoop up fish as they swim past. Catch a few in a row to build a combo. Bigger fish fight back, so hold them in the net until they give up.

GROW YOUR CATCH
Put your catch into the tank on the beach and watch it grow. Grown fish are worth three times as much. Sell them at your booth, where buyers are already queueing.

BUILD A BEACH BUSINESS
Buy a bigger tank, a better net and a bigger basket. Turn your fish stall into a seafood palace with up to ten booths, and hire sellers who keep working while the game is closed.

DIVE DEEPER
Snorkel, scuba gear, rebreather, hard-hat suit and submarine take you past the buoys into deeper water, all the way to the deep sea with its anglerfish, coelacanths and other rare creatures.

AUTOMATE
Chart a zone and send a drone out to fish it for you. Drones only catch species you have caught yourself, and they keep filling your tanks while you are away.

TRAVEL THE WORLD
Five locations, each with six zones and its own beach business: North Sea, Coral Reef, Australia, Japan and South Africa.

COLLECT THEM ALL
86 real species, hand-painted, each with facts in the Fishpedia. Goals with coin rewards keep you busy along the way.

- Play for free: no ads, no in-app purchases
- Plays offline, no account needed
- Progress continues while the game is closed
- English and German
```

## Store listing – German (add as translation "Deutsch – de-DE")

**App name**: `Fishy McFish`

**Short description**:

```
Fang echte Meerestiere, zieh sie im Becken groß und bau dein Fischgeschäft aus
```

**Full description**:

```
Wate mit deinem Kescher in die Brandung und fang echte Meeresbewohner: Sprotten, Heringe, Clownfische, Seepferdchen und viel später Haie, Wale und den Riesenkalmar.

Fishy McFish ist ein entspanntes Idle-Spiel ums Fangen, Großziehen und Verkaufen von Fischen. Steuer deinen Watfischer mit einem Finger und fang die Fische, die vorbeischwimmen. Mehrere Fänge hintereinander ergeben eine Kombo. Große Fische wehren sich: Halt sie im Netz, bis sie aufgeben.

ZIEH DEINEN FANG GROSS
Setz deinen Fang ins Becken am Strand und sieh ihm beim Wachsen zu. Ausgewachsene Fische sind dreimal so viel wert. Verkauf sie an deinem Stand, wo schon Kunden Schlange stehen.

BAU DEIN STRANDGESCHÄFT AUS
Kauf ein größeres Becken, einen besseren Kescher und einen größeren Korb. Mach aus deinem Fischstand einen Meeresfrüchte-Palast mit bis zu zehn Ständen und stell Verkäufer ein, die auch weiterarbeiten, wenn das Spiel geschlossen ist.

TAUCH TIEFER
Schnorchel, Tauchausrüstung, Kreislauftauchgerät, Helmtauchanzug und Tauchboot bringen dich hinter die Bojen in tieferes Wasser, bis hinab in die Tiefsee mit Anglerfischen, Quastenflossern und anderen seltenen Tieren.

AUTOMATISIERE
Kartiere eine Zone und schick eine Drohne los, die dort für dich fischt. Drohnen fangen nur Arten, die du selbst schon gefangen hast, und füllen deine Becken auch, während du weg bist.

REISE UM DIE WELT
Fünf Orte mit je sechs Zonen und einem eigenen Strandgeschäft: Nordsee, Korallenriff, Australien, Japan und Südafrika.

SAMMEL SIE ALLE
86 echte Arten, von Hand gemalt, jede mit Wissenswertem in der Fischpedia. Ziele mit Münzbelohnungen begleiten dich unterwegs.

- Kostenlos spielen: keine Werbung, keine In-App-Käufe
- Offline spielbar, kein Konto nötig
- Fortschritt läuft weiter, wenn das Spiel geschlossen ist
- Deutsch und Englisch
```

## Graphics

| Asset | Source |
|---|---|
| App icon 512×512 | `art_source/play_store/prompts.md` (prompt 1); upload a full square, Play rounds the corners itself. The current `assets/ui/icon.png` has its own rounded corners and would be rounded twice. |
| Feature graphic 1024×500 | Prompt 2, then the title from `tools/make_logo.py` is placed on it. |
| Phone screenshots | Real gameplay (Play policy), 1080×1920 portrait, see the shot list in the prompts file. |
| Tablet screenshots | Optional, the same shots at 1200×1920 (7") and 1600×2560 (10"). |

## Store settings

- **App or game**: Game
- **Category**: Casual (alternatively Simulation)
- **Tags**: Idle, Fishing, Casual, Simulation, Offline, Single player, Cartoon (pick from Google's list, max. 5)
- **Free or paid**: Paid. Needs a payments profile (merchant account). Choose this carefully:
  a free app can never be made paid later.
- **Contact email**: aceonline@gmx.de (shown publicly)
- **Website**: optional
- **Trader status (EU)**: if you sell a paid app you are a trader, and Play shows your name,
  address and email on the listing.

## App content (Policy → App content)

| Question | Answer |
|---|---|
| Privacy policy | URL of `docs/privacy.html` hosted publicly, e.g. GitHub Pages (`https://aceonline666.github.io/fishy-mcfish/privacy.html` if Pages is enabled on the repo) |
| App access | All functionality is available without special access |
| Ads | No, the app does not contain ads |
| Content rating (IARC) | Category "Game". Answer "no" to violence, fear, sexuality, language, controlled substances, crude humour, gambling. Users interact: no. Shares location: no. Digital purchases: no. Expected result: PEGI 3 / USK 0 / Everyone. |
| Target audience | 13+ keeps the Families policy out of the first release. Selecting under 13 is possible (no data, no ads) but adds the Families review. Answer the question "could the listing unintentionally appeal to children" honestly: the cartoon style does. |
| News app | No |
| Data safety | No data collected, no data shared. "Is all user data encrypted in transit": not applicable (nothing sent). Account deletion: no accounts. |
| Advertising ID | No, the app does not use the advertising ID |
| Government app, financial features, health | No |

## Release

- Upload `build/fishy-mcfish.aab` (see README "Building the Google Play release"), Play App
  Signing on.
- Check the current minimum **target API level** in the Console; the preset and the SDK packages
  in the README are set to API 35, and Google raises the minimum every August.
- A **personal** developer account made after November 2023 first needs a **closed test with at
  least 12 testers for 14 days in a row** before production can be applied for.
