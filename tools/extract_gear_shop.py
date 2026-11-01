"""Cuts the gear shop out of its painting and straightens it to the game's 2:1 isometry.

The painting (art_source/"Bunt bemaltes Fischereigeschäft am Meer.png") has a dark backdrop with
a soft glow instead of transparency. Background is every smooth pixel (no sharp step to its
neighbours) connected to the border, plus the pocket of backdrop under the sign; the building's
black outline is a sharp edge, so the fill stops there. Where the backdrop is nearly black the
fill runs into the outline, so the dark pixels next to the building are given back.

The painting's camera is flatter than the game's: its base edges rise 0.39 and 0.42 px per px
instead of 0.5. A vertical stretch with a slight shear (y' = 1.235 y + 0.0185 x) brings both to
0.5 and keeps verticals vertical. The building then is 3 cells long but only about 1.6 deep;
GearShopNode stands it on the footprint's front edges.

Needs Pillow, NumPy and SciPy. Usage:
  python tools/extract_gear_shop.py "art_source/Bunt bemaltes Fischereigeschäft am Meer.png" assets/sprites/props/gear_shop.png
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

SMOOTH = 8
# A point in the pocket of backdrop between the sign and the roof.
POCKET = (900, 245)
DARK = 40
STRETCH = 1.235
SHEAR = 0.0185


def main() -> None:
    rgb = np.array(Image.open(sys.argv[1]).convert("RGB"))
    rgba = np.dstack([rgb, _alpha(rgb.astype(int))])
    Image.fromarray(_trim(_straighten(rgba)), "RGBA").save(sys.argv[2])


def _alpha(rgb: np.ndarray) -> np.ndarray:
    step = np.zeros(rgb.shape[:2], int)
    d = np.abs(np.diff(rgb, axis=1)).max(2)
    step[:, 1:] = np.maximum(step[:, 1:], d)
    step[:, :-1] = np.maximum(step[:, :-1], d)
    d = np.abs(np.diff(rgb, axis=0)).max(2)
    step[1:] = np.maximum(step[1:], d)
    step[:-1] = np.maximum(step[:-1], d)
    regions, _ = ndimage.label(step < SMOOTH)
    border = np.unique(np.concatenate([regions[0], regions[-1], regions[:, 0], regions[:, -1]]))
    pocket = regions == regions[POCKET[1], POCKET[0]]
    background = ndimage.binary_opening(np.isin(regions, border[border > 0]) | pocket, iterations=1)
    dark = rgb.max(2) <= DARK
    building = ~background
    building |= dark & ndimage.binary_dilation(building, iterations=10)
    building = ndimage.binary_fill_holes(building)
    building[ndimage.binary_dilation(pocket)] = False
    parts, count = ndimage.label(building)
    building = parts == 1 + np.argmax(ndimage.sum(building, parts, range(1, count + 1)))
    # Specks of glow outside the outline.
    for _ in range(3):
        edge = building & ndimage.binary_dilation(~building)
        building &= ~(edge & ~dark)
    keep = ndimage.binary_erosion(building, iterations=1)
    soft = ndimage.gaussian_filter(keep.astype(float), 0.6)
    return (np.clip(soft * 1.4 - 0.2, 0, 1) * 255).astype(np.uint8)


def _straighten(rgba: np.ndarray) -> np.ndarray:
    """y' = STRETCH y + SHEAR x, resampled premultiplied so no backdrop colour bleeds in."""
    premult = rgba.astype(float)
    premult[..., :3] *= premult[..., 3:] / 255
    height = int(np.ceil(rgba.shape[0] * STRETCH + rgba.shape[1] * SHEAR)) + 2
    image = Image.fromarray(np.clip(premult, 0, 255).astype(np.uint8), "RGBA")
    inverse = (1, 0, 0, -SHEAR / STRETCH, 1 / STRETCH, 0)
    out = np.array(image.transform((rgba.shape[1], height), Image.AFFINE, inverse, resample=Image.BICUBIC)).astype(float)
    alpha = out[..., 3:]
    out[..., :3] = np.where(alpha > 0, out[..., :3] * 255 / np.maximum(alpha, 1), 0)
    return np.clip(out, 0, 255).astype(np.uint8)


def _trim(img: np.ndarray) -> np.ndarray:
    ys, xs = np.nonzero(img[..., 3] > 8)
    return img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


if __name__ == "__main__":
    main()
