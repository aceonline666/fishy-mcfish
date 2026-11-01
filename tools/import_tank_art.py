"""Imports a generated tank painting (art_source, see art_source/tank_sprite_prompt.md) as a sprite.

The painting already has its transparency (background alpha 0, half-transparent glass); it is only
trimmed to what is visible, straightened and scaled down by SCALE, resampled premultiplied so no
colour hidden under alpha 0 bleeds into the edges.

Straightening: the generator's camera is often a bit flatter than the game's 2:1 isometry. Given
how much the painting's front-left and front-right base edges rise or fall per pixel across
(measured, e.g. 0.30 and -0.48), y' = a y + b x brings both to 0.5 and keeps verticals vertical
(as tools/extract_gear_shop.py does). Leave the slopes out for a painting that is already right.

Needs Pillow and NumPy. Usage:
  python tools/import_tank_art.py <painting> <sprite> [left_slope right_slope]
  python tools/import_tank_art.py "art_source/Leeres Aquarium auf Holzkiste Level 1.png" assets/sprites/props/tank_1.png 0.43 -0.47
  python tools/import_tank_art.py "art_source/Isometrisches Aquarium mit türkisfarbenem Unterschrank Level 2.png" assets/sprites/props/tank_2.png 0.33 -0.485
  python tools/import_tank_art.py "art_source/Isometrisches Aquarium mit Holzsockel Level 3.png" assets/sprites/props/tank_3.png 0.39 -0.425
  python tools/import_tank_art.py "art_source/Isometrisches Aquarium mit Sand und Pflanzen Level 4.png" assets/sprites/props/tank_4.png 0.415 -0.38
  python tools/import_tank_art.py "art_source/Isometrisches Aquarium mit Korallenlandschaft Level 5.png" assets/sprites/props/tank_5.png 0.44 -0.45
  python tools/import_tank_art.py "art_source/Isometrisches Aquarium mit Meeresdekor Level 6.png" assets/sprites/props/tank_6.png 0.38 -0.395
  python tools/import_tank_art.py "art_source/Ornates Aquarium mit Korallenriff-Dekor Level 7.png" assets/sprites/props/tank_7.png 0.47 -0.37
"""
import sys

import numpy as np
from PIL import Image

SCALE = 0.5
# Fainter pixels than this at the edges are specks, not part of the tank.
VISIBLE = 16


def main() -> None:
    premult = _trim(np.array(Image.open(sys.argv[1]).convert("RGBA"))).astype(float)
    premult[..., :3] *= premult[..., 3:] / 255
    image = Image.fromarray(np.clip(premult, 0, 255).astype(np.uint8), "RGBA")
    if len(sys.argv) > 4:
        image = _straighten(image, float(sys.argv[3]), float(sys.argv[4]))
    image = Image.fromarray(_trim(np.array(image)))
    out = np.array(image.resize((round(image.width * SCALE), round(image.height * SCALE)), Image.LANCZOS)).astype(float)
    alpha = out[..., 3:]
    out[..., :3] = np.where(alpha > 0, out[..., :3] * 255 / np.maximum(alpha, 1), 0)
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA").save(sys.argv[2])


def _straighten(image: Image.Image, left: float, right: float) -> Image.Image:
    """y' = stretch y + shear x, so that slopes `left` and `right` become 0.5 and -0.5."""
    stretch = 1.0 / (left - right)
    shear = 0.5 - stretch * left
    top = min(0.0, shear * image.width)
    height = int(np.ceil(image.height * stretch + abs(shear) * image.width)) + 2
    inverse = (1, 0, 0, -shear / stretch, 1 / stretch, top / stretch)
    return image.transform((image.width, height), Image.AFFINE, inverse, resample=Image.BICUBIC)


def _trim(rgba: np.ndarray) -> np.ndarray:
    ys, xs = np.nonzero(rgba[..., 3] > VISIBLE)
    return rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


if __name__ == "__main__":
    main()
