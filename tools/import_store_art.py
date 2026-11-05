"""Brings a painting for the gear shop (art_source/store: the room, the displays) into the game.

The paintings already have a transparent background (their dark glow has zero alpha), so this only
crops one to its opaque pixels and clears the colour of the transparent ones, so no dark fringe
bleeds in when the texture is filtered. Points measured on the painting (the room's floor corners,
a display's spot on the floor) are printed shifted by the crop, for StoreRoom and
UpgradeStore.FIXTURES.

Needs Pillow and NumPy. Usage:
  python tools/import_store_art.py <painting.png> <sprite.png> [--clear-below=A] [x,y ...]
--clear-below=A clears pixels with alpha below A: some paintings come with a faint halo of
low-alpha pixels around the subject (basket_display.png: 100).
  python tools/import_store_art.py art_source/store/room.png assets/sprites/props/store_room.png 64,620 768,972 1472,620
  python tools/import_store_art.py art_source/store/net_display.png assets/sprites/props/net_display.png 665,1110
  python tools/import_store_art.py art_source/store/gear_display.png assets/sprites/props/gear_display.png 952,1060
  python tools/import_store_art.py art_source/store/basket_display.png assets/sprites/props/basket_display.png --clear-below=100 765,640
"""
import sys

import numpy as np
from PIL import Image


def main() -> None:
    image = np.array(Image.open(sys.argv[1]).convert("RGBA"))
    args = sys.argv[3:]
    for arg in [a for a in args if a.startswith("--clear-below=")]:
        image[image[:, :, 3] < int(arg.split("=")[1]), 3] = 0
        args.remove(arg)
    image[image[:, :, 3] == 0, :3] = 0
    ys, xs = np.where(image[:, :, 3] > 0)
    left, top = int(xs.min()), int(ys.min())
    Image.fromarray(image[top:ys.max() + 1, left:xs.max() + 1]).save(sys.argv[2])
    for point in args:
        x, y = (float(v) for v in point.split(","))
        print(f"{point} -> ({x - left:g}, {y - top:g})")


if __name__ == "__main__":
    main()
