# Location pictures – generation prompts

The world map shows a painted picture of every location on its card
(`assets/sprites/props/location_<id>.png`, about 250 × 315 px, portrait 4:5). The first five
were cut from `art_source/props/gear_sprite_sheet.png` by `tools/extract_props.py`; the ones
added later are generated one at a time and cut by `tools/cut_location_picture.py`.

Generate each in a NEW ChatGPT chat. Attach `art_source/props/location_pictures_reference.png`
(the five existing pictures side by side) as the style reference. Save the result as
`art_source/props/location_<id>.png`, then cut it:
`python tools/cut_location_picture.py art_source/props/location_<id>.png <id>`.

## Antarctica

```
Paint ONE new picture in exactly the same style as the five attached location pictures for a
cozy mobile fishing game: bright, saturated painted cartoon style, soft light, seen from a high
coastal viewpoint looking out over the water, the same level of detail and the same colours of
water and sky. Portrait format, 1024 × 1280 px (4:5), the picture fills the whole canvas edge to
edge, no border, no frame, no rounded corners, no text, no labels.

The place: an Antarctic coast. In the foreground a snowy, rocky shore with a few emperor
penguins standing on it; dark, icy-blue water with floating ice floes and a small iceberg; in the
middle distance a long white ice shelf with a blue ice cliff, and snowy mountains behind it under
a clear pale blue sky. Perhaps a whale's spout far out. Friendly and inviting, not gloomy.
```

## Jurassic Sea

```
Paint ONE new picture in exactly the same style as the five attached location pictures for a
cozy mobile fishing game: bright, saturated painted cartoon style, soft light, seen from a high
coastal viewpoint looking out over the water, the same level of detail and the same colours of
water and sky. Portrait format, 1024 × 1280 px (4:5), the picture fills the whole canvas edge to
edge, no border, no frame, no rounded corners, no text, no labels.

The place: a warm prehistoric sea 150 million years ago. In the foreground a pale limestone
shore with cycads and tree ferns; a turquoise lagoon with a few ammonite shells on the sand
under the clear water; in the middle distance the long neck of a plesiosaur rising from the
sea, and two pterosaurs gliding over the water; behind them a hazy green volcanic island with a
thin plume of smoke, under a warm, slightly misty sky. Friendly and full of wonder, not scary.
No people, no buildings.
```
