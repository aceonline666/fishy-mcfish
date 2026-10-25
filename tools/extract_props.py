"""Cuts the beach props (tanks, shops, people, decoration) out of the coastal sprite sheet.

The sheet has no transparency: its background is a light grey checkerboard. Background is
every light, colourless pixel connected to the sheet's border; it becomes transparent, and the
edge is pulled in by a pixel so no light fringe remains. Each sprite is found by a point on it
(PROPS) and saved trimmed to its own PNG.

Needs Pillow, NumPy and SciPy. Usage:
  python tools/extract_props.py art_source/coastal_sprite_sheet.png assets/sprites/props
  python tools/extract_props.py art_source/coastal_sprite_sheet.png out_dir --debug
    (writes debug.png with every found sprite numbered, to pick the points)
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

# The painted background strip on the right of the sheet is not a sprite.
SHEET_WIDTH = 1180
LIGHT = 226
GREY_SPREAD = 16

# name: (x, y) of a point on the sprite in the sheet
PROPS = {
    "wader_front": (55, 100), "wader_back": (155, 100),
    "customer_1_front": (252, 100), "customer_1_back": (313, 100),
    "customer_2_front": (393, 100), "customer_2_back": (462, 100),
    "customer_3_front": (540, 100), "customer_3_back": (606, 100),
    "customer_4_front": (757, 100), "customer_4_back": (822, 100),
    "customer_5_front": (910, 100), "customer_5_back": (982, 100),
    "customer_6_front": (1063, 100), "customer_6_back": (1126, 100),
    "tank_1": (63, 330), "tank_2": (167, 318), "tank_3": (283, 310), "tank_4": (408, 305),
    "tank_5": (542, 300), "tank_6": (683, 285), "tank_7": (1037, 260),
    "shop_1": (64, 530), "shop_2": (190, 525), "shop_3": (332, 515), "shop_4": (527, 515),
    "shop_5": (760, 515), "shop_6": (1025, 495),
    "cashier_1": (58, 720), "cashier_2": (213, 720), "cashier_3": (375, 720),
    "kid_1": (526, 700), "kid_2": (576, 700), "kid_3": (636, 700), "kid_4": (700, 700),
    "kid_5": (762, 700), "kid_6": (822, 700), "kid_7": (882, 700), "kid_8": (942, 700),
    "kid_9": (996, 700),
    "customer_fish_front": (1060, 700), "customer_fish_back": (1130, 700),
    "pier": (260, 900), "palm": (575, 870), "parasol": (690, 890), "signpost": (793, 895),
    "bush": (905, 900), "seagull": (1026, 920), "buoy": (1100, 900),
}


def main() -> None:
    sheet = np.array(Image.open(sys.argv[1]).convert("RGB"))[:, :SHEET_WIDTH]
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    alpha = _foreground(sheet)
    labels, count = ndimage.label(ndimage.binary_dilation(alpha > 0, iterations=2))
    if "--debug" in sys.argv:
        _debug(sheet, alpha, labels, count, out / "debug.png")
        return
    rgba = np.dstack([sheet, alpha])
    for name, (x, y) in PROPS.items():
        label = _label_near(labels, x, y)
        sl = ndimage.find_objects((labels == label).astype(int))[0]
        sprite = rgba[sl].copy()
        sprite[..., 3][labels[sl] != label] = 0
        Image.fromarray(_trim(sprite)).save(out / f"{name}.png")
        print(f"{name}: {sl[1].stop - sl[1].start}x{sl[0].stop - sl[0].start}")


def _foreground(sheet: np.ndarray) -> np.ndarray:
    """Alpha: 0 for the background connected to the border, 255 elsewhere, edge pulled in."""
    rgb = sheet.astype(int)
    light = (rgb.min(axis=2) >= LIGHT) & (rgb.max(axis=2) - rgb.min(axis=2) <= GREY_SPREAD)
    regions, _ = ndimage.label(light)
    border = np.unique(np.concatenate([regions[0], regions[-1], regions[:, 0], regions[:, -1]]))
    background = np.isin(regions, border[border > 0])
    # Light specks of background between sprite parts that do not touch the border.
    sizes = ndimage.sum(light, regions, index=np.arange(regions.max() + 1))
    background |= light & (sizes[regions] > 400)
    keep = ndimage.binary_erosion(~background, iterations=1)
    soft = ndimage.gaussian_filter(keep.astype(float), 0.6)
    return (np.clip(soft * 1.4 - 0.2, 0, 1) * 255).astype(np.uint8)


def _label_near(labels: np.ndarray, x: int, y: int) -> int:
    """The biggest labelled region within a few pixels of the point."""
    window = labels[y - 14:y + 14, x - 14:x + 14]
    values, counts = np.unique(window[window > 0], return_counts=True)
    assert len(values), f"nothing near {x},{y}"
    return int(values[np.argmax(counts)])


def _trim(img: np.ndarray) -> np.ndarray:
    ys, xs = np.nonzero(img[..., 3] > 0)
    return img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def _debug(sheet: np.ndarray, alpha: np.ndarray, labels: np.ndarray, count: int, path: Path) -> None:
    preview = Image.new("RGB", (sheet.shape[1], sheet.shape[0]), (30, 70, 100))
    preview.paste(Image.fromarray(sheet), mask=Image.fromarray(alpha))
    draw = ImageDraw.Draw(preview)
    for i, sl in enumerate(ndimage.find_objects(labels)):
        if sl is None or (sl[0].stop - sl[0].start) * (sl[1].stop - sl[1].start) < 400:
            continue
        draw.rectangle([sl[1].start, sl[0].start, sl[1].stop, sl[0].stop], outline=(255, 0, 0))
    preview.save(path)


if __name__ == "__main__":
    main()
