"""Cuts the menu icons and the boot splash out of art_source/menu_sheet.png.

The upper part of the sheet is a landscape title picture; the game is portrait, so the splash
shows the picture (sides cropped a little) across the middle of the screen, with its own water
surface stretched above it and its own seabed below it.
The icons below it (coins, map, trophy, book, cog) are cut out like the props (the light
background is removed by flood fill, see tools/extract_props.py).

Needs Pillow, NumPy and SciPy. Usage (from the project folder):
  python tools/make_menu_art.py
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from extract_props import _foreground, _label_near, _trim  # noqa: E402

SHEET = "art_source/menu_sheet.png"
OUT = "assets/ui/"
# Bottom of the title picture on the sheet.
PICTURE_BOTTOM = 712
SPLASH_SIZE = (1080, 1920)
# The part of the picture shown, its centre on the splash (share of the height), the outermost
# rows that are stretched to fill the screen above and below it, the fade into them, and the deep
# sea colour the bottom turns into.
CROP_X = (150, 1386)
PICTURE_CENTER = 0.46
EDGE_ROWS = 4
FADE_ROWS = 50
DEEP = (8, 40, 70)
# icon name: a point on it
ICONS = {"coins": (190, 870), "map": (520, 860), "trophy": (800, 860), "book": (1085, 860), "cog": (1365, 870)}


def main() -> None:
    sheet = Image.open(SHEET).convert("RGB")
    _splash(sheet.crop((0, 0, sheet.width, PICTURE_BOTTOM))).save(OUT + "splash.png")
    icons = np.array(sheet)
    icons[:PICTURE_BOTTOM + 4] = 255
    alpha = _foreground(icons)
    labels, _ = ndimage.label(ndimage.binary_dilation(alpha > 0, iterations=2))
    rgba = np.dstack([icons, alpha])
    for name, (x, y) in ICONS.items():
        label = _label_near(labels, x, y)
        sl = ndimage.find_objects((labels == label).astype(int))[0]
        sprite = rgba[sl].copy()
        sprite[..., 3][labels[sl] != label] = 0
        sprite = _trim(sprite)
        Image.fromarray(sprite).save(OUT + f"icon_{name}.png")
        print(f"icon_{name}: {sprite.shape[1]}x{sprite.shape[0]}")


def _splash(picture: Image.Image) -> Image.Image:
    width, height = SPLASH_SIZE
    front = picture.crop((CROP_X[0], 0, CROP_X[1], picture.height))
    front = front.resize((width, int(front.height * width / front.width)), Image.LANCZOS)
    top = int(height * PICTURE_CENTER - front.height / 2)
    bottom = top + front.height
    out = Image.new("RGB", SPLASH_SIZE)
    above = front.crop((0, 0, width, EDGE_ROWS)).resize((width, top + FADE_ROWS), Image.BICUBIC)
    below = front.crop((0, front.height - EDGE_ROWS, width, front.height)).resize((width, height - bottom + FADE_ROWS), Image.BICUBIC)
    below = np.array(below.filter(ImageFilter.GaussianBlur(70))).astype(np.float32)
    depth = np.linspace(0.0, 1.0, below.shape[0])[:, None, None] ** 0.7
    below = below * (1.0 - depth) + np.array(DEEP, np.float32) * depth
    out.paste(above.filter(ImageFilter.GaussianBlur(25)), (0, 0))
    out.paste(Image.fromarray(below.astype(np.uint8)), (0, bottom - FADE_ROWS))
    # The picture over it, its top and bottom edges fading into the stretched parts.
    fade = np.ones((front.height, width), np.float32)
    for i in range(FADE_ROWS):
        fade[i, :] = i / FADE_ROWS
        fade[-1 - i, :] = i / FADE_ROWS
    out.paste(front, (0, top), Image.fromarray((fade * 255).astype(np.uint8)))
    return out


if __name__ == "__main__":
    main()
