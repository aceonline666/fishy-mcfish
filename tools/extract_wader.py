"""Cuts the baskets out of the equipment sheet into assets/sprites/wader. (The landing nets come
from art_source/characters/net_sheet_2.png, cut by tools/extract_magenta_sheet.py.)

The wader himself, in the outfit of each gear level, comes from tools/extract_diver.py. Every
sprite is cut like the props (tools/extract_props.py: the checkerboard background is removed by
flood fill).

Needs Pillow, NumPy and SciPy. Usage:
  python tools/extract_wader.py art_source/characters/equipment_sprite_sheet.png assets/sprites/wader
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from extract_props import _foreground, _label_near, _trim  # noqa: E402

# Per sheet, name: a point on the sprite.
SHEETS = {
    "equipment_sprite_sheet.png": {
        "basket_1": (872, 601), "basket_2": (958, 598), "basket_3": (1054, 591), "basket_4": (1164, 593),
        "basket_5": (1293, 586), "basket_6": (1439, 572),
    },
}


def main() -> None:
    sprites = SHEETS[Path(sys.argv[1]).name]
    sheet = np.array(Image.open(sys.argv[1]).convert("RGB"))
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    alpha = _foreground(sheet)
    labels, _ = ndimage.label(ndimage.binary_dilation(alpha > 0, iterations=1))
    rgba = np.dstack([sheet, alpha])
    for name, (x, y) in sprites.items():
        label = _label_near(labels, x, y)
        sl = ndimage.find_objects((labels == label).astype(int))[0]
        sprite = rgba[sl].copy()
        sprite[..., 3][labels[sl] != label] = 0
        sprite = _trim(sprite)
        Image.fromarray(sprite).save(out / f"{name}.png")
        print(f"{name}: {sprite.shape[1]}x{sprite.shape[0]}")


if __name__ == "__main__":
    main()
