"""Cuts species sprites out of a painted sprite sheet into body/tail PNGs in FishArt's layout.

Body canvas: 240 units wide, tail root at x=20, snout at x=220, centred on the body axis.
Tail canvas: 70 units wide at the body's pixel scale, tail root at x=62.
SPRITES maps each species to a point on its sprite in the sheet.

Needs Pillow, NumPy and SciPy. Usage:
  python tools/extract_painted.py art_source/painted_sprite_sheet.png assets/sprites/fish_painted
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

# species id: (sprite centre x, y on the sheet, facing, split tail)
SPRITES = {
    "european_sprat": (246, 115, "left", True),
    "atlantic_herring": (381, 112, "left", True),
    "lesser_sand_eel": (515, 113, "left", True),
    "atlantic_mackerel": (669, 112, "left", True),
    "european_plaice": (835, 112, "left", True),
    "lumpsucker": (978, 112, "left", True),
    "atlantic_cod": (1112, 114, "left", True),
    "conger_eel": (1281, 109, "left", True),
    "ocellaris_clownfish": (1449, 111, "left", True),
    "blue_green_chromis": (95, 277, "left", True),
    "blue_tang": (221, 273, "left", True),
    "mandarinfish": (363, 273, "left", True),
    "red_lionfish": (508, 271, "left", True),
    "blacktip_reef_shark": (668, 273, "left", True),
    "humphead_wrasse": (835, 275, "left", True),
    "lions_mane_jellyfish": (972, 266, "right", False),
    "atlantic_bluefin_tuna": (1126, 277, "left", True),
    "ocean_sunfish": (1285, 268, "left", False),
    "basking_shark": (1446, 272, "left", True),
    "roundnose_grenadier": (92, 434, "left", False),
    "rabbit_fish": (240, 431, "left", False),
    "curled_octopus": (369, 431, "right", False),
    "greenland_shark": (519, 430, "left", True),
    "humpback_anglerfish": (677, 432, "left", True),
    "south_african_sardine": (532, 595, "left", True),
    "green_sea_turtle": (387, 761, "right", False),
    "sperm_whale": (1172, 746, "left", True),
    "blue_whale": (111, 883, "left", True),
    "giant_squid": (1250, 901, "right", False),
}

# Sheet rows below which a sprite's region is its label, not the creature.
BOTTOM_LIMIT = {"green_sea_turtle": 800}

ALPHA_FLOOR = 40
MAX_TAIL_SHARE = 0.3


def main() -> None:
    sheet = np.array(Image.open(sys.argv[1]).convert("RGBA"))
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    mask = sheet[..., 3] > 60
    labels, _ = ndimage.label(ndimage.binary_dilation(mask, iterations=3))
    for species, (cx, cy, facing, split) in SPRITES.items():
        label = _label_near(labels, cx, cy)
        sl = ndimage.find_objects((labels == label).astype(int))[0]
        crop = sheet[sl].copy()
        keep = labels[sl] == label
        # The turtle's name label sits so close that it merges with the sprite.
        if species in BOTTOM_LIMIT:
            keep[BOTTOM_LIMIT[species] - sl[0].start:] = False
        alpha = crop[..., 3].astype(float)
        alpha[~keep] = 0
        alpha = np.clip((alpha - ALPHA_FLOOR) / (255 - ALPHA_FLOOR), 0, 1) * 255
        crop[..., 3] = alpha.astype(np.uint8)
        crop = _trim(crop)
        if facing == "left":
            crop = crop[:, ::-1]
        _write(species, crop, split, out)


def _label_near(labels: np.ndarray, x: int, y: int) -> int:
    """The biggest labelled region within a few pixels of the point."""
    window = labels[y - 12:y + 12, x - 12:x + 12]
    values, counts = np.unique(window[window > 0], return_counts=True)
    return int(values[np.argmax(counts)])


def _trim(img: np.ndarray) -> np.ndarray:
    ys, xs = np.nonzero(img[..., 3] > 0)
    return img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def _write(species: str, img: np.ndarray, split: bool, out: Path) -> None:
    h, w = img.shape[:2]
    opaque = img[..., 3] > 128
    if split:
        # The tail root is the narrowest column in the back part of the body.
        heights = np.array([np.count_nonzero(opaque[:, x]) for x in range(w)])
        lo, hi = int(w * 0.08), int(w * MAX_TAIL_SHARE * 1.2)
        root = lo + int(np.argmin(heights[lo:hi] + np.linspace(0, 2, hi - lo)))
        root = min(root, int(w * MAX_TAIL_SHARE))
        rows = np.nonzero(opaque[:, root])[0]
        axis = int(rows.mean()) if len(rows) else h // 2
    else:
        root = 0
        axis = h // 2
    body = img[:, root:]
    tail = img[:, :root + 2] if root > 0 else np.zeros((h, 1, 4), np.uint8)
    body_px = body.shape[1]
    unit = body_px / 200.0
    # Centre both parts on the body axis.
    half = max(axis, h - axis)
    body = _pad_vertical(body, axis, half)
    tail = _pad_vertical(tail, axis, half)
    pad = int(round(20 * unit))
    body_canvas = np.zeros((body.shape[0], body_px + 2 * pad, 4), np.uint8)
    body_canvas[:, pad:pad + body_px] = body
    tail_width = int(round(70 * unit))
    tail_canvas = np.zeros((tail.shape[0], tail_width, 4), np.uint8)
    root_x = int(round(62 * unit))
    # The tail part reaches 2 px into the body so no seam shows; its column `root` sits at root_x.
    start = root_x - root
    if start < 0:
        tail = tail[:, -start:]
        start = 0
    end = min(start + tail.shape[1], tail_width)
    tail_canvas[:, start:end] = tail[:, :end - start]
    Image.fromarray(body_canvas).save(out / f"{species}_body.png")
    Image.fromarray(tail_canvas).save(out / f"{species}_tail.png")
    print(f"{species}: {w}x{h}, tail {root}px")


def _pad_vertical(img: np.ndarray, axis: int, half: int) -> np.ndarray:
    top = half - axis
    bottom = 2 * half - img.shape[0] - top
    return np.pad(img, ((top, max(bottom, 0)), (0, 0), (0, 0)))


if __name__ == "__main__":
    main()
