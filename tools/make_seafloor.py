"""Makes a seamless seabed tile per location from art_source/seafloor_sheet.png.

Each location's strip on the sheet looks forward along the seabed. The near part of its floor is
laid flat (inverse perspective: ground depth goes with 1 / (y - horizon)), then cross-faded with
a copy shifted by half its size: the copy, whose edges meet seamlessly when repeated, shows at
the edges of the tile and the patch itself in its middle. The game lays the tile under the
water (src/shaders/water.gdshader).

Needs Pillow and NumPy. Usage (from the project folder):
  python tools/make_seafloor.py
"""
import numpy as np
from PIL import Image

SHEET = "art_source/seafloor_sheet.png"
OUT = "assets/sprites/seafloor/"
# location id: left and right edge of its strip, the horizon row, and the farthest row used.
STRIPS = {
    "north_sea": (8, 296, 300.0, 600.0),
    "coral_reef": (316, 604, 120.0, 520.0),
    "australia": (624, 914, 150.0, 560.0),
    "japan": (934, 1224, 150.0, 560.0),
    "south_africa": (1244, 1532, 150.0, 560.0),
}
# The nearest row used: just above the location's name label.
NEAR = 945.0
# Size of the flattened patch and of the tile.
PATCH = (384, 384)


def main() -> None:
    sheet = np.array(Image.open(SHEET).convert("RGB")).astype(np.float32)
    for location, (x0, x1, horizon, far) in STRIPS.items():
        patch = _flatten(sheet[:, x0:x1], horizon, far)
        # The picture darkens with distance; even out the brightness row by row.
        rows = patch.mean(axis=(1, 2), keepdims=True)
        patch = patch * (patch.mean() / np.maximum(rows, 1.0))
        tile = _seamless(patch)
        Image.fromarray(tile.clip(0, 255).astype(np.uint8)).save(OUT + f"{location}.png")
        print(location, tile.shape[1], "x", tile.shape[0])


def _seamless(patch: np.ndarray) -> np.ndarray:
    h, w = patch.shape[:2]
    shifted = np.roll(patch, (h // 2, w // 2), axis=(0, 1))
    # 1 in the middle, falling to 0 at the edges.
    ys = 1.0 - np.abs(np.linspace(-1.0, 1.0, h))
    xs = 1.0 - np.abs(np.linspace(-1.0, 1.0, w))
    weight = np.clip(np.minimum.outer(ys, xs) * 2.5, 0.0, 1.0)[..., None]
    return patch * weight + shifted * (1.0 - weight)


def _flatten(strip: np.ndarray, horizon: float, far: float) -> np.ndarray:
    width = strip.shape[1]
    out_w, out_h = PATCH
    d_near, d_far = 1.0 / (NEAR - horizon), 1.0 / (far - horizon)
    out = np.zeros((out_h, out_w, 3), np.float32)
    columns = np.arange(width)
    for r in range(out_h):
        d = d_near + (d_far - d_near) * (out_h - 1 - r) / (out_h - 1)
        y = horizon + 1.0 / d
        # The ground width seen at the near edge, which is narrower in the picture further away.
        half = (width / 2.0 - 2.0) * (y - horizon) / (NEAR - horizon)
        xs = width / 2.0 + (np.arange(out_w) / (out_w - 1) - 0.5) * 2.0 * half
        row_index = int(y)
        t = y - row_index
        row = strip[row_index] * (1.0 - t) + strip[min(row_index + 1, strip.shape[0] - 1)] * t
        out[r] = np.stack([np.interp(xs, columns, row[:, c]) for c in range(3)], axis=1)
    return out


if __name__ == "__main__":
    main()
