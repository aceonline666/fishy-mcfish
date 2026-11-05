"""Cuts the cashier sheet (art_source/characters/cashier_sheet.png, see cashier_sprite_prompt.md)
into one strip per cashier for Booth.

The sheet has three cashiers (rows) in five frames (columns). Each figure is found in its cell,
then all frames are put into cells of one size with the feet on the bottom line and the middle of
the boots on the cell's centre line, so the frames line up when played. The figure height of the
standing frame is printed: Booth scales it to the wader's height.

Needs Pillow and NumPy. Usage:
  python tools/import_cashiers.py art_source/characters/cashier_sheet.png assets/sprites/cashier
writes cashier_1.png .. cashier_3.png (5 frames side by side).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROWS, COLUMNS = 3, 5
# Rows near the soles, used to find the middle of the boots.
FOOT_BAND = 40
MARGIN = 4


def main() -> None:
    sheet = np.array(Image.open(sys.argv[1]).convert("RGBA"))
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    height, width = sheet.shape[:2]
    figures = []
    for row in range(ROWS):
        frames = []
        for column in range(COLUMNS):
            y0, y1 = row * height // ROWS, (row + 1) * height // ROWS
            x0, x1 = column * width // COLUMNS, (column + 1) * width // COLUMNS
            cell = sheet[y0:y1, x0:x1]
            ys, xs = np.where(cell[:, :, 3] > 128)
            bottom = ys.max()
            band = cell[bottom - FOOT_BAND:bottom + 1, :, 3] > 128
            foot_x = int(round(np.where(band)[1].mean()))
            frames.append((cell, foot_x, bottom, ys.min(), xs.min(), xs.max()))
        figures.append(frames)
    left = max(f[1] - f[4] for row in figures for f in row) + MARGIN
    right = max(f[5] - f[1] for row in figures for f in row) + MARGIN
    up = max(f[2] - f[3] for row in figures for f in row) + MARGIN
    frame_size = (left + right + 1, up + 1)
    for index, frames in enumerate(figures):
        strip = Image.new("RGBA", (frame_size[0] * COLUMNS, frame_size[1]), (0, 0, 0, 0))
        for column, (cell, foot_x, bottom, top, x_min, x_max) in enumerate(frames):
            piece = Image.fromarray(cell[top:bottom + 1, x_min:x_max + 1])
            strip.alpha_composite(piece, (column * frame_size[0] + left - (foot_x - x_min), up - (bottom - top)))
        array = np.array(strip)
        array[array[:, :, 3] == 0, :3] = 0
        Image.fromarray(array).save(out / f"cashier_{index + 1}.png")
    standing = [frames[0][2] - frames[0][3] for frames in figures]
    print(f"frame {frame_size[0]} x {frame_size[1]}, feet at ({left}, {up}), standing heights {standing}")


if __name__ == "__main__":
    main()
