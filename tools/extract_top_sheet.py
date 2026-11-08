"""Cuts a top-view species sheet (art_source/fish/top_view/top_sheet_NN.png) into sprites.

The sheets have a fixed grid (tools/make_top_view_prompts.py): 4 x 2 cells, one species per cell,
each swimming towards the lower left (top_sheet_NN.png) or, on the second sheet of the same
creatures, towards the upper left (top_sheet_NN_up.png). The species per cell are read from the
sheet's prompt file. Each drawing becomes assets/sprites/fish_painted/<id>_top.png (or
<id>_top_up.png), cropped to its pixels.

Usage:
    python tools/extract_top_sheet.py 1 [--up] [--scale=0.75]

A sheet with real transparency is cut by its alpha (a faint glow is dropped); a sheet with an
opaque light background (white or a painted checkerboard) has the light pixels connected to the
border removed. Every drawing is assigned to the cell its centre lies in, so a fin reaching into
the next cell does no harm. After cutting, import in Godot and turn mipmaps on for the new sprites
(see the README).
"""
import os
import re
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEET_DIR = os.path.join(ROOT, "art_source", "fish", "top_view")
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "fish_painted")
COLUMNS, ROWS = 4, 2
# Alpha a pixel needs to count as part of a creature; below it lies the glow.
SOLID_ALPHA = 200
KEEP_ALPHA = 40
# Drawings smaller than this share of a cell are specks, not creatures.
MIN_SHARE = 0.01


def cell_species(sheet: int) -> list[str]:
    """Species ids in cell order (row 1 from left, then row 2)."""
    text = open(os.path.join(SHEET_DIR, f"top_sheet_{sheet:02d}_prompt.md"), encoding="utf-8").read()
    return re.findall(r"^\| \d \| \S+ \| `([a-z0-9_]+)` \|", text, re.M)


def alpha_of(image: np.ndarray) -> np.ndarray:
    alpha = image[:, :, 3].astype(np.int32)
    if (alpha < 250).mean() > 0.2:
        return alpha
    # Opaque: light, grey pixels connected to the border are background.
    rgb = image[:, :, :3].astype(np.int32)
    light = (rgb.min(axis=2) > 185) & (rgb.max(axis=2) - rgb.min(axis=2) < 25)
    labels, _ = ndimage.label(light)
    border = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
    background = np.isin(labels, border[border > 0])
    return np.where(background, 0, 255)


def main() -> None:
    sheet = int(sys.argv[1])
    scale = 0.75
    suffix = ""
    for arg in sys.argv[2:]:
        if arg.startswith("--scale="):
            scale = float(arg.split("=", 1)[1])
        elif arg == "--up":
            suffix = "_up"
    ids = cell_species(sheet)
    image = np.array(Image.open(os.path.join(SHEET_DIR, f"top_sheet_{sheet:02d}{suffix}.png")).convert("RGBA"))
    height, width = image.shape[:2]
    cell_w, cell_h = width / COLUMNS, height / ROWS
    alpha = alpha_of(image)
    solid = ndimage.binary_fill_holes(alpha >= SOLID_ALPHA)
    labels, count = ndimage.label(ndimage.binary_dilation(solid, iterations=2))
    sizes = ndimage.sum(solid, labels, range(1, count + 1))
    centres = ndimage.center_of_mass(solid, labels, range(1, count + 1))
    cells: dict[tuple[int, int], np.ndarray] = {}
    for index in range(count):
        if sizes[index] < MIN_SHARE * cell_w * cell_h:
            continue
        y, x = centres[index]
        key = (int(y // cell_h), int(x // cell_w))
        part = labels == index + 1
        cells[key] = cells[key] | part if key in cells else part
    for k, species_id in enumerate(ids):
        key = (k // COLUMNS, k % COLUMNS)
        if key not in cells:
            print(f"MISSING {species_id} (row {key[0] + 1}, column {key[1] + 1})")
            continue
        mask = cells[key]
        out = image.copy()
        out[:, :, 3] = np.where(mask & (alpha >= KEEP_ALPHA), alpha, 0).astype(np.uint8)
        ys, xs = np.nonzero(out[:, :, 3])
        sprite = Image.fromarray(out[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
        if scale != 1.0:
            sprite = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))), Image.LANCZOS)
        sprite.save(os.path.join(OUT_DIR, f"{species_id}_top{suffix}.png"))
        print(f"{species_id}_top{suffix}: {sprite.width} x {sprite.height}")

main()
