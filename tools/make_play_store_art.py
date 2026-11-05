"""Makes the Google Play store graphics.

- art_source/play_store/icon_512.png: the app icon (icon_source.png scaled to 512 x 512, full
  square; Play rounds the corners itself).
- art_source/play_store/feature_graphic.png: the feature graphic (feature_graphic_source.png
  cropped to 1024 x 500, with the title lettering of tools/make_logo.py in its sky). 24-bit PNG,
  Play allows no alpha here.
- art_source/play_store/screenshots/<lang>/NN_<shot>.jpg: the phone screenshots, 1080 x 1920, a
  caption above the game picture. The game pictures are taken first with tools/store_screenshots.gd
  into build/store_shots/<lang>/ (see the README); shots without a caption below are left out.

The prompts for the icon and the feature graphic are in art_source/play_store/prompts.md.

Needs Pillow and NumPy. Usage (from the project folder):
  python tools/make_play_store_art.py
"""
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from make_logo import FONT, NAVY, title  # noqa: E402

DIR = "art_source/play_store/"
RAW_SHOTS = "build/store_shots/"
FEATURE_SIZE = (1024, 500)
# Title width and its top-left corner on the feature graphic.
TITLE_WIDTH = 330
TITLE_POS = (28, 10)

SHOT_SIZE = (1080, 1920)
# Width of the game picture on a screenshot, its top and its corner radius.
PICTURE_WIDTH = 860
PICTURE_TOP = 330
PICTURE_RADIUS = 36
CAPTION_SIZE = 76
CAPTION_TOP = 60
CAPTION_HEIGHT = 230
SKY = (110, 215, 240)
DEEP = (12, 60, 125)
# Raw shot: caption per language, in the order they appear in the store.
CAPTIONS = {
    "01_catch": {"en": "Catch real\nsea creatures", "de": "Fang echte\nMeerestiere"},
    "02_business": {"en": "Sell them at\nyour own booths", "de": "Verkauf sie an\ndeinen Ständen"},
    "04_open_sea": {"en": "Dive deeper for\nbigger fish", "de": "Tauch tiefer nach\ngrößeren Fischen"},
    "06_reef": {"en": "Travel to five places\naround the world", "de": "Reise zu fünf Orten\nauf der Welt"},
    "05_deep_sea": {"en": "Explore the\ndeep sea", "de": "Erkunde\ndie Tiefsee"},
    "03_gear_shop": {"en": "Upgrade your net,\ntank and gear", "de": "Rüste Kescher, Becken\nund Ausrüstung auf"},
    "08_fishpedia_detail": {"en": "Collect 86\nhand-painted species", "de": "Sammle 86\nhandgemalte Arten"},
    "10_map": {"en": "A beach business\nin every place", "de": "Ein Strandgeschäft\nan jedem Ort"},
}


def icon() -> Image.Image:
    return Image.open(DIR + "icon_source.png").convert("RGBA").resize((512, 512), Image.LANCZOS)


def feature_graphic() -> Image.Image:
    source = Image.open(DIR + "feature_graphic_source.png").convert("RGBA")
    # Crop the height to the 1024:500 ratio, evenly from top and bottom.
    height = round(source.width * FEATURE_SIZE[1] / FEATURE_SIZE[0])
    top = (source.height - height) // 2
    out = source.crop((0, top, source.width, top + height)).resize(FEATURE_SIZE, Image.LANCZOS)
    lettering = title(TITLE_WIDTH)
    lettering = lettering.crop(lettering.getbbox())
    out.alpha_composite(lettering, TITLE_POS)
    return out.convert("RGB")


def screenshot(raw: Image.Image, caption: str) -> Image.Image:
    """The game picture with rounded corners and a shadow on a sea gradient, the caption above."""
    width, height = SHOT_SIZE
    rows = np.linspace(0.0, 1.0, height)[:, None]
    colors = np.array(SKY, float) + (np.array(DEEP, float) - np.array(SKY, float)) * rows ** 0.7
    out = Image.fromarray(np.repeat(colors[:, None, :], width, axis=1).astype(np.uint8)).convert("RGBA")

    picture = raw.convert("RGBA").resize((PICTURE_WIDTH, round(raw.height * PICTURE_WIDTH / raw.width)), Image.LANCZOS)
    mask = Image.new("L", picture.size)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, picture.width - 1, picture.height - 1], PICTURE_RADIUS, fill=255)
    left = (width - picture.width) // 2
    shadow = Image.new("RGBA", out.size)
    shadow.paste((0, 20, 40, 140), (left + 6, PICTURE_TOP + 14), mask)
    out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(18)))
    frame = Image.new("L", (picture.width + 16, picture.height + 16))
    ImageDraw.Draw(frame).rounded_rectangle([0, 0, frame.width - 1, frame.height - 1], PICTURE_RADIUS + 8, fill=255)
    out.paste(NAVY, (left - 8, PICTURE_TOP - 8), frame)
    out.paste(picture, (left, PICTURE_TOP), mask)

    font = ImageFont.truetype(FONT, CAPTION_SIZE)
    draw = ImageDraw.Draw(out)
    text = caption.upper()
    box = draw.multiline_textbbox((0, 0), text, font=font, align="center", spacing=14, stroke_width=8)
    x = (width - (box[2] - box[0])) // 2 - box[0]
    y = CAPTION_TOP + (CAPTION_HEIGHT - (box[3] - box[1])) // 2 - box[1]
    draw.multiline_text((x + 3, y + 7), text, font=font, fill=(0, 20, 40, 150), align="center", spacing=14,
                        stroke_width=8, stroke_fill=(0, 20, 40, 150))
    draw.multiline_text((x, y), text, font=font, fill=(255, 214, 60), align="center", spacing=14,
                        stroke_width=8, stroke_fill=NAVY)
    return out.convert("RGB")


def screenshots() -> int:
    written = 0
    for lang in ("en", "de"):
        source = RAW_SHOTS + lang + "/"
        if not os.path.isdir(source):
            print(f"no raw shots in {source}, run tools/store_screenshots.gd first")
            continue
        target = DIR + "screenshots/" + lang + "/"
        os.makedirs(target, exist_ok=True)
        for number, (shot, captions) in enumerate(CAPTIONS.items(), 1):
            name = shot.split("_", 1)[1]
            raw = Image.open(source + shot + ".png")
            screenshot(raw, captions[lang]).save(f"{target}{number:02d}_{name}.jpg", quality=90)
            written += 1
    return written


def main() -> None:
    icon().save(DIR + "icon_512.png", optimize=True)
    feature_graphic().save(DIR + "feature_graphic.png", optimize=True)
    count = screenshots()
    print(f"written icon_512.png, feature_graphic.png and {count} screenshots")


if __name__ == "__main__":
    main()
