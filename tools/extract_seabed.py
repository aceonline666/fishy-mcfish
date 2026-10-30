"""Cuts the seabed props out of art_source/seabed_props.png into assets/sprites/seabed.

The sheet has an alpha channel with a soft glow around each prop; the glow is cut off just
outside the dark outline. A prop may consist of several pieces (the starfish), which are cut
out together.

Needs Pillow, NumPy and SciPy. Usage (from the project folder):
  python tools/extract_seabed.py
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SHEET = "art_source/seabed_props.png"
OUT = Path("assets/sprites/seabed")
# name: points on its pieces
PROPS = {
    "wreck": [(296, 194)], "rowboat": [(749, 233)], "anchor": [(1072, 208)], "barrels": [(1373, 229)],
    "lobster_pot": [(158, 541)], "stones": [(399, 578)], "rock": [(610, 552)], "boulder": [(860, 541)],
    "kelp_small": [(1078, 568)], "kelp": [(1242, 546)], "kelp_tall": [(1426, 512)],
    "sea_lettuce": [(160, 852)], "mussels": [(454, 856)], "starfish": [(724, 811), (811, 858), (710, 901)],
    "anemones": [(1041, 844)], "crate": [(1365, 862)],
}
# Alpha range of the soft edge: below is glow, above is the prop.
EDGE = (120.0, 230.0)


def main() -> None:
    sheet = np.array(Image.open(SHEET).convert("RGBA"))
    alpha = sheet[..., 3].astype(np.float32)
    labels, _ = ndimage.label(ndimage.binary_dilation(alpha > 128, iterations=2))
    OUT.mkdir(parents=True, exist_ok=True)
    for name, points in PROPS.items():
        keep = np.isin(labels, [labels[y, x] for x, y in points])
        ys, xs = np.nonzero(keep)
        box = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1))
        sprite = sheet[box].copy()
        edge = np.clip((alpha[box] - EDGE[0]) / (EDGE[1] - EDGE[0]), 0.0, 1.0) * 255.0
        edge[~keep[box]] = 0
        sprite[..., 3] = edge.astype(np.uint8)
        Image.fromarray(sprite).save(OUT / f"{name}.png")
        print(f"{name}: {sprite.shape[1]}x{sprite.shape[0]}")


if __name__ == "__main__":
    main()
