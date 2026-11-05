"""Cuts the painted booth row (art_source/buildings/booth_row_N.png, see booth_row_sprite_prompt.md)
into the pieces Booth draws: a repeating segment and the row's two end caps.

The painting shows three segments of a market row. Its camera is a little off 2:1, so it is
straightened first: y' = A·y − K·x + C keeps verticals vertical and turns the row (which rose
0.38 px per px) and the end faces (which fell 0.67) to exactly 0.5. Its segments also shrink
towards the back (420, 375, 320 px), so only the middle one is used as the tile.

A segment is cut along its natural seams: at each join, from the back post's cap down the awning
seam to the front post, then down the middle of the front post (`seam`). Two neighbouring cuts
are the same curve shifted by one segment, so the tiles meet exactly. The end caps are what lies
beyond the cut at the outer posts, stretched (an affine map of the post's foot and cap) to the
tile's cut so that they meet it too.

Outputs, each with its anchor printed (the foot of the front post the piece attaches at):
  booth_row.png        the segment; anchor: its south join (the next segment's anchor is
                       SEGMENT pixels up-right of it)
  booth_row_south.png  the south end cap; anchor: the south join of the first booth
  booth_row_north.png  the north end cap; anchor: the north join of the last booth

Needs Pillow and NumPy. Usage:
  python tools/import_booth_row.py art_source/buildings/booth_row_1.png assets/sprites/props
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# Straightening, measured on booth_row_1.png.
A, K, C = 0.955, 0.137, 210
HEIGHT = 1160
# In the straightened painting: front post foot (centre) and the bottom of the back post's cap
# at each join; the south end, the two joins of the middle segment, the north end.
SOUTH_END = ((322, 1110), (172, 622))
JOIN = ((757, 900), (585, 420))
SEGMENT = (373, -186)
NORTH_END = ((1440, 555), (1265, 85))


def main() -> None:
    painting = Image.open(sys.argv[1]).convert("RGBA")
    out = Path(sys.argv[2])
    straight = np.array(painting.transform((painting.width, HEIGHT), Image.AFFINE,
                                           (1, 0, 0, K / A, 1 / A, -C / A), resample=Image.BICUBIC))
    height, width = straight.shape[:2]
    xs = np.arange(width)[None, :]
    south_join = seam(JOIN, height)
    north_join = seam(((JOIN[0][0] + SEGMENT[0], JOIN[0][1] + SEGMENT[1]), (JOIN[1][0] + SEGMENT[0], JOIN[1][1] + SEGMENT[1])), height)
    tile = masked(straight, (xs >= south_join) & (xs < north_join))
    save(tile, JOIN[0], out / "booth_row.png")
    south = masked(straight, xs < seam(SOUTH_END, height))
    save(fit(south, SOUTH_END, JOIN), JOIN[0], out / "booth_row_south.png")
    north = masked(straight, xs >= seam(NORTH_END, height))
    save(fit(north, NORTH_END, JOIN), JOIN[0], out / "booth_row_north.png")


def seam(post: tuple, height: int) -> np.ndarray:
    """The cut's x for every row: up the back post's middle, down the awning seam, down the front post."""
    (fx, _), (bx, by) = post
    y = np.arange(height, dtype=float)
    return np.where(y < by, bx, np.minimum(bx + 2.0 * (y - by), fx))[:, None]


def masked(image: np.ndarray, keep: np.ndarray) -> np.ndarray:
    result = image.copy()
    result[~keep] = 0
    return result


def fit(piece: np.ndarray, post: tuple, target: tuple) -> np.ndarray:
    """Stretches a cap so its post (foot, cap) lands on the tile's join post (foot, cap)."""
    (fx, fy), (bx, by) = post
    (tx, ty), (ux, uy) = target
    sx, sy = (tx - ux) / (fx - bx), (ty - uy) / (fy - by)
    # Output pixel (x, y) shows input (fx + (x - tx) / sx, fy + (y - ty) / sy).
    data = (1 / sx, 0, fx - tx / sx, 0, 1 / sy, fy - ty / sy)
    image = Image.fromarray(piece).transform((piece.shape[1], piece.shape[0]), Image.AFFINE, data, resample=Image.BICUBIC)
    return np.array(image)


def save(piece: np.ndarray, anchor: tuple, path: Path) -> None:
    piece[piece[:, :, 3] == 0, :3] = 0
    ys, xs = np.where(piece[:, :, 3] > 0)
    left, top = int(xs.min()), int(ys.min())
    Image.fromarray(piece[top:ys.max() + 1, left:xs.max() + 1]).save(path)
    print(f"{path.name}: anchor ({anchor[0] - left}, {anchor[1] - top})")


if __name__ == "__main__":
    main()
