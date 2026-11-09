"""Cuts a seabird sheet (art_source/props/seabirds_N.png, art_source/props/seabird_sprite_prompt.md)
into the four poses of its two birds: assets/sprites/birds/<bird>_glide.png, _up, _mid, _down.

The sheet is a grid of 4 columns (glide, wings up, wings level, wings down) and 2 rows (one bird
each) on flat magenta. The painter does not put the body in the same place in every cell, so
the frames are lined up on the head: a patch around the head in the glide frame (its position
given per bird, in pixels of the glide cell) is looked for in the other three frames. All four
frames of a bird get the same canvas with the head at the same point, so the game can draw them
centred and the body keeps still while the wings beat.

Needs Pillow, NumPy and SciPy. Usage:
  python tools/extract_seabirds.py <sheet> <bird_1> <bird_2> --heads=x,y/x,y [--scale=S]
  python tools/extract_seabirds.py art_source/props/seabirds_1.png herring_gull great_frigatebird --heads=117,271/117,767
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.signal import fftconvolve

sys.path.insert(0, str(Path(__file__).parent))
from extract_magenta_sheet import _key, _scale  # noqa: E402

OUT = Path("assets/sprites/birds")
POSES = ["glide", "up", "mid", "down"]
SCALE = 0.4
# Half size of the head patch (pixels on the sheet).
PATCH = (40, 30)
VISIBLE = 24


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    sheet = np.array(Image.open(args[0]).convert("RGB")).astype(float)
    birds = args[1:3]
    heads = next(a[8:] for a in sys.argv if a.startswith("--heads="))
    heads = [tuple(int(v) for v in h.split(",")) for h in heads.split("/")]
    scale = next((float(a[8:]) for a in sys.argv if a.startswith("--scale=")), SCALE)
    rgba = _key(sheet).astype(float)
    cell_w, cell_h = sheet.shape[1] // 4, sheet.shape[0] // 2
    OUT.mkdir(parents=True, exist_ok=True)
    for row, (bird, head) in enumerate(zip(birds, heads)):
        cells = [rgba[row * cell_h:(row + 1) * cell_h, col * cell_w:(col + 1) * cell_w] for col in range(4)]
        anchors = [np.array(head)] + [_find(cells[0], head, cell) for cell in cells[1:]]
        # The visible box of every frame, relative to its head; the canvas holds them all.
        boxes = []
        for cell, anchor in zip(cells, anchors):
            ys, xs = np.nonzero(cell[..., 3] >= VISIBLE)
            boxes.append((xs.min() - anchor[0], ys.min() - anchor[1], xs.max() + 1 - anchor[0], ys.max() + 1 - anchor[1]))
        left, top = min(b[0] for b in boxes), min(b[1] for b in boxes)
        right, bottom = max(b[2] for b in boxes), max(b[3] for b in boxes)
        for pose, cell, anchor in zip(POSES, cells, anchors):
            canvas = np.zeros((bottom - top, right - left, 4))
            x0, y0 = anchor[0] + left, anchor[1] + top
            src = cell[max(y0, 0):y0 + canvas.shape[0], max(x0, 0):x0 + canvas.shape[1]]
            canvas[max(-y0, 0):max(-y0, 0) + src.shape[0], max(-x0, 0):max(-x0, 0) + src.shape[1]] = src
            image = _scale(canvas.astype(np.uint8), scale)
            image.save(OUT / f"{bird}_{pose}.png")
        print(f"{bird}: {image.width} x {image.height}, head offsets {[tuple(int(v) for v in a - anchors[0]) for a in anchors]}")


def _find(reference: np.ndarray, head: tuple, cell: np.ndarray) -> np.ndarray:
    """Where the head patch of `reference` around `head` fits `cell` best (least squared
    difference over the patch's opaque pixels)."""
    hx, hy = head
    patch = reference[hy - PATCH[1]:hy + PATCH[1], hx - PATCH[0]:hx + PATCH[0]]
    mask = (patch[..., 3] > 128).astype(float)
    cost = np.zeros(cell.shape[:2])
    for c in range(3):
        image = cell[..., c] * (cell[..., 3] > 128)
        template = patch[..., c] * mask
        flip = lambda a: a[::-1, ::-1]  # noqa: E731
        cost += fftconvolve(image ** 2, flip(mask), mode="same")
        cost -= 2.0 * fftconvolve(image, flip(template), mode="same")
    # Where the cell is transparent the patch would match nothing: keep the search on the bird.
    cost[cell[..., 3] < 128] = np.inf
    y, x = np.unravel_index(np.argmin(cost), cost.shape)
    # mode="same" centres the patch on (x, y); the patch is centred on the head.
    return np.array([x, y])


if __name__ == "__main__":
    main()
