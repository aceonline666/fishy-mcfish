"""Cuts the sprites out of a painted sheet on a flat magenta (#FF00FF) background.

Unlike the checkerboard sheets (tools/extract_props.py), every magenta pixel is background, also
the enclosed ones: the holes of a net, the inside of a rotor ring. Pixels that are partly magenta
(anti-aliased edges, glass) get partial alpha, with the magenta taken out of their colour. The
sheet is a grid of equal cells, one sprite per cell, read left to right and top to bottom; each is
trimmed to its visible pixels and scaled by SCALE, or by --scale=S. --pad=N adds a transparent border of N pixels
(the landing nets need one, so their stretched handle does not smear the edge pixels).

Needs Pillow and NumPy. Usage:
  python tools/extract_magenta_sheet.py <sheet> <out_dir> <columns> <rows> <name_1> ... <name_n> [--pad=N] [--scale=S]
  python tools/extract_magenta_sheet.py art_source/props/drone_sheet_2.png assets/sprites/props 3 2 drone_1 drone_2 drone_3 drone_4 drone_5 drone_6 --scale=0.4
  python tools/extract_magenta_sheet.py art_source/ground/seabed_props_currents.png assets/sprites/seabed 3 2 sand_ripples sea_whips sardine_shoal whale_bones shark_cage red_bait --scale=0.33
    (then delete sand_ripples.png and sardine_shoal.png: not used)
  The props drawn largest (whale_bones, black_smoker, whale_fall) are cut at the default 0.5
  instead, or they turn blurry; the others at 0.33 look as soft as the older props.
  python tools/extract_magenta_sheet.py art_source/ground/seabed_props_deep.png assets/sprites/seabed 3 2 black_smoker tube_worms glass_sponge sea_pens whale_fall brittle_stars --scale=0.33
  python tools/extract_magenta_sheet.py art_source/ground/seabed_props_open.png assets/sprites/seabed 3 2 sand_dollars razor_clams lost_lure sea_cucumbers hermit_crab wall_sponges --scale=0.33
  python tools/extract_magenta_sheet.py art_source/characters/net_sheet_2.png assets/sprites/wader 3 2 net_1 net_2 net_3 net_4 net_5 net_6 --pad=6
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SCALE = 0.5
# Magenta-ness (min(red, blue) - green) at and above which a pixel is all background, and below
# which it is all sprite.
CLEAR = 200
SOLID = 90
# Fainter pixels than this at the edges are specks.
VISIBLE = 24
# Sprites smaller than this many pixels inside a cell are specks, not sprites.
MIN_PIXELS = 400


def main() -> None:
    sheet = np.array(Image.open(sys.argv[1]).convert("RGB")).astype(float)
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    columns, rows = int(sys.argv[3]), int(sys.argv[4])
    names = [arg for arg in sys.argv[5:] if not arg.startswith("--")]
    pad = next((int(arg[6:]) for arg in sys.argv[5:] if arg.startswith("--pad=")), 0)
    scale = next((float(arg[8:]) for arg in sys.argv[5:] if arg.startswith("--scale=")), SCALE)
    rgba = _key(sheet)
    cell_w, cell_h = sheet.shape[1] / columns, sheet.shape[0] / rows
    for i, name in enumerate(names):
        x, y = i % columns, i // columns
        cell = rgba[round(y * cell_h):round((y + 1) * cell_h), round(x * cell_w):round((x + 1) * cell_w)]
        sprite = _trim(cell)
        image = _scale(sprite, scale)
        if pad:
            padded = Image.new("RGBA", (image.width + 2 * pad, image.height + 2 * pad))
            padded.paste(image, (pad, pad))
            image = padded
        image.save(out / f"{name}.png")
        print(f"{name}: {image.width} x {image.height}")


def _key(rgb: np.ndarray) -> np.ndarray:
    magenta = np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1]
    alpha = np.clip((CLEAR - magenta) / (CLEAR - SOLID), 0.0, 1.0)
    # Take the magenta share out of the colour: pixel = a * colour + (1 - a) * magenta.
    key = np.array([255.0, 0.0, 255.0])
    a = np.maximum(alpha, 1e-3)[..., None]
    colour = np.clip((rgb - (1.0 - a) * key) / a, 0, 255)
    # Despill: what is left of a magenta tint (red and blue both above green) on the sprite's own
    # pixels is taken out of red and blue; the sprites have no magenta or pink of their own.
    spill = np.clip(np.minimum(colour[..., 0], colour[..., 2]) - colour[..., 1], 0, None)
    colour[..., 0] -= spill
    colour[..., 2] -= spill
    return np.dstack([colour, alpha * 255]).astype(np.uint8)


def _trim(rgba: np.ndarray) -> np.ndarray:
    visible = rgba[..., 3] >= VISIBLE
    if visible.sum() < MIN_PIXELS:
        sys.exit("empty cell")
    ys, xs = np.nonzero(visible)
    return rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def _scale(rgba: np.ndarray, scale: float = SCALE) -> Image.Image:
    """Scales premultiplied, so no colour hidden under alpha 0 bleeds into the edges."""
    premult = rgba.astype(float)
    premult[..., :3] *= premult[..., 3:] / 255
    image = Image.fromarray(premult.astype(np.uint8), "RGBA")
    size = (round(image.width * scale), round(image.height * scale))
    out = np.array(image.resize(size, Image.LANCZOS)).astype(float)
    alpha = out[..., 3:]
    out[..., :3] = np.where(alpha > 0, out[..., :3] * 255 / np.maximum(alpha, 1), 0)
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


if __name__ == "__main__":
    main()
