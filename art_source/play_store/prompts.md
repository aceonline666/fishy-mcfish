# Play Store graphics – generation prompts

Two images are generated: the app icon and the background of the feature graphic. Screenshots
must show the real game (Play policy), so they come from the game, not from a generator.

For both prompts attach `art_source/ui/splash.png` as the **style and character** reference: the
same comic look (bold dark outlines, bright saturated colours, soft cel shading) and the same
wader (yellow waders, dark blue beanie, blue diving mask on the forehead, snorkel, wicker basket).

## 1. App icon (512×512)

Generate at 1024×1024, scale down to 512×512 PNG. Play cuts the corners itself (about 20 %
radius), so the image must fill the whole square: no rounded corners, no transparency, no border,
no shadow around it, no text. Keep the face inside the middle 80 %.

```
Square mobile game app icon, full bleed, filling the entire square edge to edge. Close-up of a
cheerful cartoon kid wader, head and shoulders, from the attached reference: dark blue knitted
beanie, blue diving mask pushed up on the forehead, blue and orange snorkel at the side of the
head, yellow waterproof jacket, big friendly smile and big shiny eyes. The kid holds a wooden
hand net up next to the face, and an orange-and-white clownfish has just jumped into the net,
looking surprised. Background: bright turquoise-to-deep-blue ocean water with sunlight rays and
a few white bubbles. Bold dark outlines, saturated colours, soft cel shading, same comic style
as the reference. Simple, readable silhouette that still works at 48 pixels: one face, one fish,
no small details at the edges. No text, no letters, no logo, no border, no frame, no rounded
corners, no drop shadow, no transparent areas.
```

If the result is too busy at small size, drop the net and keep only the face with the clownfish
next to the cheek.

## 2. Feature graphic background (1024×500)

Generate at about 2048×1000 (or the closest wide format, then crop to 2.048:1). The title
"Fishy McFish" is added afterwards from `tools/make_logo.py`, so the generator draws **no text**
and leaves the left half of the sky free for it. Keep everything important away from the outer
10 % and out of the very centre lower third (Play may place a play button there when a promo
video is set).

```
Wide panoramic illustration for a mobile game banner, 2:1 landscape. A sunny beach at a clear
turquoise sea, seen from slightly above. On the right third, the cheerful cartoon kid wader from
the attached reference stands knee-deep in the shallow water, laughing, swinging a wooden hand
net, wicker basket on the back, yellow waders, dark blue beanie, blue diving mask on the
forehead. Around the kid fish jump out of the water with splashes: a clownfish, a blue tang, a
herring and a tuna; a chambered nautilus floats in the clear water in front. Behind, a wooden
pier with lanterns leads out to sea, a small red-and-white lighthouse on green cliffs far on the
left horizon, a sailboat, seagulls, fluffy white clouds. The left half of the sky is open, calm
blue with soft clouds and no objects, leaving room for a title. Bold dark outlines, bright
saturated colours, soft cel shading, same comic style as the reference. No text, no letters, no
logo, no border.
```

## 3. Phone screenshots (from the game)

Portrait 1080×1920, 4–8 shots, made with `tools/screenshot.gd`. Captions may be added on a band
at the top (English set and German set). Suggested shots:

1. Wading in the North Sea, net full of fish, combo shown – "Catch real sea creatures"
2. The beach business: tank, booths with buyers queueing – "Raise them and sell them"
3. Gear shop with the upgrade pads – "Upgrade your net, tank and gear"
4. A deep zone with a big creature (shark, sunfish or anglerfish) – "Dive down to the deep sea"
5. Coral Reef with clownfish and blue tangs – "Travel to five places around the world"
6. Fishpedia page of a rare species – "Collect 86 hand-painted species"
7. Drones bringing fish to the tank – "Drones and sellers work while you are away"
