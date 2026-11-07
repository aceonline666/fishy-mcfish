"""Makes the boot splash and cuts the menu icons out of art_source/ui/menu_sheet.png.

The splash is the portrait beach picture art_source/ui/splash.png, scaled to the screen, with the
title (lettering as in the logo, tools/make_logo.py) in its sky.
The icons (coins, map, trophy, book, cog) are cut out of the menu sheet like the props (the
light background is removed by flood fill, see tools/extract_props.py) and scaled down to
ICON_HEIGHT: the HUD shows them about 60 px high, and a picture four times that size shrunk on
screen looks jagged.

Needs Pillow, NumPy and SciPy. Usage (from the project folder):
  python tools/make_menu_art.py
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from extract_props import _foreground, _label_near, _trim  # noqa: E402
from make_logo import title  # noqa: E402

SHEET = "art_source/ui/menu_sheet.png"
SPLASH = "art_source/ui/splash.png"
OUT = "assets/ui/"
# Bottom of the title picture on the menu sheet, above the icons.
PICTURE_BOTTOM = 712
SPLASH_SIZE = (1080, 1920)
# Width of the title on the splash and the height of its top.
TITLE_WIDTH = 860
TITLE_TOP = 70
# icon name: a point on it
# Height of the saved icons: about 1.5 times their height on the HUD (54-80 px), the rest is
# done by mipmaps on screen.
ICON_HEIGHT = 96
ICONS = {"coins": (190, 870), "map": (520, 860), "trophy": (800, 860), "book": (1085, 860), "cog": (1365, 870)}


def main() -> None:
    _splash().save(OUT + "splash.png")
    sheet = Image.open(SHEET).convert("RGB")
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
        icon = _shrink(Image.fromarray(_trim(sprite)), ICON_HEIGHT)
        icon.save(OUT + f"icon_{name}.png")
        print(f"icon_{name}: {icon.width}x{icon.height}")


def _shrink(image: Image.Image, height: int) -> Image.Image:
    """Scales an RGBA picture to `height` with premultiplied alpha, so its edges keep no fringe."""
    width = round(image.width * height / image.height)
    rgba = np.asarray(image, dtype=np.float32) / 255.0
    rgba[..., :3] *= rgba[..., 3:]
    channels = [Image.fromarray(rgba[..., i]).resize((width, height), Image.LANCZOS) for i in range(4)]
    out = np.clip(np.dstack([np.asarray(c) for c in channels]), 0.0, 1.0)
    out[..., :3] /= np.maximum(out[..., 3:], 1e-6)
    return Image.fromarray((np.clip(out, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8))


def _splash() -> Image.Image:
    out = Image.open(SPLASH).convert("RGBA").resize(SPLASH_SIZE, Image.LANCZOS)
    lettering = title(TITLE_WIDTH)
    lettering = lettering.crop(lettering.getbbox())
    out.alpha_composite(lettering, ((SPLASH_SIZE[0] - lettering.width) // 2, TITLE_TOP))
    return out.convert("RGB")


if __name__ == "__main__":
    main()
