"""Cuts the painted pier (assets/sprites/props/boardwalk.png) into three pieces, so Boardwalk can
draw it at any length: the steps at the water end, one section that repeats, and the lantern end.

The deck runs from WATER_END to SHORE_END in the sprite, four sections long. A cut goes across
the deck, then straight down from its near edge and straight up from its far edge, so the posts
hanging below and standing above stay whole. The section is the deck between the two cuts; a
section placed one SECTION further up the pier lines up with the one below it. Each piece reaches
OVERLAP pixels past its shore-side cut, so the pieces leave no gap where they meet (Boardwalk
draws them from the shore end down, the nearer piece on top).

Prints each piece's top-left corner in the uncut sprite, for Boardwalk's constants.

Needs Pillow and NumPy. Usage:
  python tools/cut_boardwalk.py assets/sprites/props/boardwalk.png assets/sprites/props/boardwalk
"""
import sys

import numpy as np
from PIL import Image

WATER_END = np.array([194.0, 722.0])
SHORE_END = np.array([1134.0, 202.0])
SECTIONS = 4
# Where the repeating section starts, in sprite pixels along the deck from WATER_END: between
# posts, where the section's two ends match best.
FIRST_CUT = 312.0
# The deck's far and near edges, in sprite pixels across it from the WATER_END-SHORE_END line.
FAR_EDGE = -165.0
NEAR_EDGE = 150.0
OVERLAP = 3.0


def main(source: str, prefix: str) -> None:
    image = np.array(Image.open(source).convert("RGBA"))
    height, width = image.shape[:2]
    walk = (SHORE_END - WATER_END) / np.linalg.norm(SHORE_END - WATER_END)
    across = np.array([2.0, 1.0]) / np.sqrt(5.0)
    to_deck = np.linalg.inv(np.column_stack([walk, across]))
    ys, xs = np.mgrid[0:height, 0:width]
    deck = np.stack([xs - WATER_END[0], ys - WATER_END[1]], -1) @ to_deck.T
    along, side = deck[..., 0], deck[..., 1]

    def water_side(cut: float) -> np.ndarray:
        far = WATER_END + cut * walk + FAR_EDGE * across
        near = WATER_END + cut * walk + NEAR_EDGE * across
        return np.where(side < FAR_EDGE, xs < far[0], np.where(side > NEAR_EDGE, xs < near[0], along < cut))

    section = np.linalg.norm(SHORE_END - WATER_END) / SECTIONS
    first, second = FIRST_CUT, FIRST_CUT + section
    pieces = {
        "steps": water_side(first + OVERLAP),
        "section": water_side(second + OVERLAP) & ~water_side(first),
        "lantern": ~water_side(second),
    }
    for name, mask in pieces.items():
        piece = image.copy()
        piece[..., 3] = np.where(mask, piece[..., 3], 0)
        rows, cols = np.nonzero(piece[..., 3])
        left, top = cols.min(), rows.min()
        Image.fromarray(piece[top:rows.max() + 1, left:cols.max() + 1]).save("%s_%s.png" % (prefix, name))
        print(name, (left, top))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
