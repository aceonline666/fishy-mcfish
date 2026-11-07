"""Cuts the sardine shoal out of art_source/ground/seabed_props_currents.png without its sand.

The shoal turns in the game (SeabedDecor.SPIN), so the sand patch and pebbles it was painted on
must not turn with it. The sardines are cool silver-blue and the sand is warm, so every warm pixel
goes; the pebbles (grey, below the shoal) and specks are dropped as small blobs in the bottom rows.
Otherwise cut like tools/extract_magenta_sheet.py.

Needs Pillow, NumPy and SciPy. Usage:
  python tools/cut_sardine_shoal.py
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

from extract_magenta_sheet import _key, _scale, _trim

SHEET = Path("art_source/ground/seabed_props_currents.png")
OUT = Path("assets/sprites/seabed/sardine_shoal.png")
# The shoal's cell on the sheet (third column, first row of 512-pixel cells).
CELL = (1024, 0, 1536, 512)
# Red above blue by more than this is sand.
WARM = 12
# Blobs smaller than SPECK pixels anywhere, or than STONE pixels below row STONE_ROW (the pebbles
# and the shadow on the sand), are not sardines.
SPECK = 60
STONE = 1500
STONE_ROW = 360


def main() -> None:
    left, top, right, bottom = CELL
    rgb = np.array(Image.open(SHEET).convert("RGB")).astype(float)[top:bottom, left:right]
    rgba = _key(rgb)
    alpha = rgba[..., 3].astype(float)
    alpha[(rgb[..., 0] - rgb[..., 2]) > WARM] = 0
    labels, count = ndimage.label(alpha > 40)
    ones = np.ones_like(alpha)
    for index in range(1, count + 1):
        blob = labels == index
        size = ndimage.sum(ones, labels, index)
        row = ndimage.center_of_mass(blob)[0]
        if size < SPECK or (row > STONE_ROW and size < STONE):
            alpha[blob] = 0
    rgba[..., 3] = alpha.astype(np.uint8)
    image = _scale(_trim(rgba))
    image.save(OUT)
    print(f"{OUT}: {image.width} x {image.height}")


if __name__ == "__main__":
    main()
