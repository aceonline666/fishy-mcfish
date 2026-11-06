"""Cuts a buyer sheet (art_source/characters/buyer_sheet_N.png, see buyer_sprite_prompt.md) into
one sprite per buyer and pose for Customer.

The sheet has three buyers (rows) in four poses (columns): front, back, front with a fish, back
with a fish. Each figure is found in its cell (its faint glow cleared, bits of the neighbours'
figures dropped) and cropped so the middle
of its feet is the sprite's bottom centre, where Customer stands it on the ground.

Needs Pillow, NumPy and SciPy. Usage:
  python tools/import_buyers.py art_source/characters/buyer_sheet_1.png assets/sprites/buyers 1
writes buyer_1..3 (the number after the folder is the sheet's number: sheet 2 writes buyer_4..6)
as <buyer>_front.png, _back.png, _front_fish.png and _back_fish.png.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROWS, COLUMNS = 3, 4
POSES = ["front", "back", "front_fish", "back_fish"]
# Alpha below this is the painting's glow, not the figure.
CLEAR_BELOW = 120
# Rows near the soles, used to find the middle of the feet.
FOOT_BAND = 40


def main() -> None:
    sheet = np.array(Image.open(sys.argv[1]).convert("RGBA"))
    sheet[sheet[..., 3] < CLEAR_BELOW] = 0
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    first = (int(sys.argv[3]) - 1) * ROWS + 1
    height, width = sheet.shape[:2]
    for row in range(ROWS):
        for column in range(COLUMNS):
            y0, y1 = row * height // ROWS, (row + 1) * height // ROWS
            x0, x1 = column * width // COLUMNS, (column + 1) * width // COLUMNS
            cell = sheet[y0:y1, x0:x1].copy()
            # Keep the figure: the biggest blob and what lies close to it.
            labels, _ = ndimage.label(ndimage.binary_dilation(cell[..., 3] > 0, iterations=4))
            sizes = np.bincount(labels.ravel())
            sizes[0] = 0
            cell[labels != np.argmax(sizes)] = 0
            ys, xs = np.where(cell[..., 3] > 128)
            top, bottom = ys.min(), ys.max()
            band = cell[bottom - FOOT_BAND:bottom + 1, :, 3] > 128
            foot_x = int(round(np.where(band)[1].mean()))
            half = max(foot_x - xs.min(), xs.max() - foot_x) + 2
            sprite = np.zeros((bottom - top + 1, 2 * half + 1, 4), np.uint8)
            left = foot_x - half
            src_x0, src_x1 = max(left, 0), min(foot_x + half + 1, cell.shape[1])
            sprite[:, src_x0 - left:src_x1 - left] = cell[top:bottom + 1, src_x0:src_x1]
            name = f"buyer_{first + row}_{POSES[column]}.png"
            Image.fromarray(sprite).save(out / name)
            print(name, sprite.shape[1], "x", sprite.shape[0])


if __name__ == "__main__":
    main()
