"""Cuts sprites (tanks, shops, people, gear, drones, decoration) out of the painted sheets.

The sheets have no transparency: their background is a light grey checkerboard. Background is
every light, colourless pixel connected to the sheet's border; it becomes transparent, and the
edge is pulled in by a pixel so no light fringe remains. Each sprite is found by a point on it
and saved trimmed to its own PNG. Pictures with light parts at their edge (the location scenes)
are cut as plain rectangles instead.

Needs Pillow, NumPy and SciPy. Usage, per sheet (SHEETS says what each one holds):
  python tools/extract_props.py art_source/coastal_sprite_sheet.png assets/sprites/props
  python tools/extract_props.py art_source/gear_sprite_sheet.png assets/sprites/props
  python tools/extract_props.py <sheet> out_dir --debug
    (writes debug.png with a box around every found sprite, to pick the points)
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

LIGHT = 226
GREY_SPREAD = 16

# Per sheet file: "width" (columns to look at), "sprites" (name: a point on the sprite) and
# "pictures" (name: left, top, right, bottom of a rectangle).
SHEETS = {
    "coastal_sprite_sheet.png": {
        # The painted background strip on the right of the sheet is not a sprite.
        "width": 1180,
        "sprites": {
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
            "palm": (575, 870), "parasol": (690, 890), "signpost": (793, 895),
            "bush": (905, 900), "seagull": (1026, 920), "buoy": (1100, 900),
        },
        "pictures": {},
    },
    "gear_sprite_sheet.png": {
        "width": 1536,
        "sprites": {
            "net_1": (371, 146), "net_2": (449, 151), "net_3": (530, 149), "net_4": (615, 147),
            "net_5": (705, 143), "net_6": (793, 135),
            "gear_1": (916, 129), "gear_2": (1017, 119), "gear_3": (1130, 120), "gear_4": (1241, 120),
            "gear_5": (1351, 122), "gear_6": (1466, 119),
            "drone_1": (57, 420), "drone_2": (169, 419), "drone_3": (292, 415), "drone_4": (414, 407),
            "drone_5": (552, 401), "drone_6": (710, 384),
            "buyer_1_front": (852, 416), "buyer_1_back": (931, 417),
            "buyer_2_front": (1041, 416), "buyer_2_back": (1128, 417),
            "buyer_3_front": (1220, 416), "buyer_3_back": (1294, 416),
            "buyer_4_front": (1388, 416), "buyer_4_back": (1479, 417),
        },
        "pictures": {
            "location_north_sea": (40, 630, 316, 945), "location_coral_reef": (366, 630, 610, 945),
            "location_australia": (660, 630, 898, 945), "location_japan": (950, 630, 1200, 945),
            "location_south_africa": (1254, 630, 1504, 945),
        },
    },
}


def main() -> None:
    config = SHEETS.get(Path(sys.argv[1]).name, {"width": None, "sprites": {}, "pictures": {}})
    full = np.array(Image.open(sys.argv[1]).convert("RGB"))
    sheet = full[:, :config["width"]]
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    alpha = _foreground(sheet)
    labels, count = ndimage.label(ndimage.binary_dilation(alpha > 0, iterations=2))
    if "--debug" in sys.argv:
        _debug(sheet, alpha, labels, count, out / "debug.png")
        return
    for name, box in config["pictures"].items():
        Image.fromarray(full[box[1]:box[3], box[0]:box[2]]).save(out / f"{name}.png")
        print(f"{name}: {box[2] - box[0]}x{box[3] - box[1]}")
    rgba = np.dstack([sheet, alpha])
    for name, (x, y) in config["sprites"].items():
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
