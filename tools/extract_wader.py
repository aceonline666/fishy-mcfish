"""Cuts the wader and his equipment out of the equipment sheets into assets/sprites/wader.

Every sprite is cut like the props (tools/extract_props.py: the checkerboard background is
removed by flood fill). Figures and legs are then padded so that the middle of the hips is at
the horizontal centre of the image: the game puts both at x = 0, so legs line up under the body.

Views: front, towards (three-quarter towards the camera), away (three-quarter from behind), back.

Needs Pillow, NumPy and SciPy. Usage (the first sheet adds the baskets and the hard-hat diver):
  python tools/extract_wader.py art_source/equipment_sheet_2.png assets/sprites/wader
  python tools/extract_wader.py art_source/equipment_sprite_sheet.png assets/sprites/wader
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from extract_props import _foreground, _label_near, _trim  # noqa: E402

# Leg rows: the row's middle and the columns of the four views.
LEG_ROWS = {"wader": 566, "snorkel": 646, "scuba": 727, "rebreather": 807}
LEG_VIEWS = {"front": 943, "towards": 1001, "away": 1117, "back": 1223}

# Per sheet, name: a point on the sprite.
SHEETS = {
    "equipment_sheet_2.png": {
        "body_front": (49, 150), "body_towards": (137, 150), "body_away": (285, 150), "body_back": (368, 150),
        "snorkel_front": (69, 490), "snorkel_towards": (150, 490),
        "scuba_front": (58, 606), "scuba_towards": (133, 606), "scuba_away": (335, 606), "scuba_back": (501, 606),
        "rebreather_front": (59, 720), "rebreather_towards": (135, 720), "rebreather_away": (272, 720),
        "rebreather_back": (423, 720),
        "sub_front": (60, 950), "sub_towards": (154, 950), "sub_away": (364, 950), "sub_back": (561, 950),
        # The landing nets seen from above, hoop on the left, handle to the right.
        "net_1": (860, 235), "net_2": (980, 235), "net_3": (1100, 235), "net_4": (1230, 235),
        "net_5": (1345, 235), "net_6": (1465, 235),
    } | {
        f"legs_{suit}_{view}": (x, y) for suit, y in LEG_ROWS.items() for view, x in LEG_VIEWS.items()
    },
    # The hard-hat diver is painted much bigger here than on the second sheet.
    "equipment_sprite_sheet.png": {
        "hardhat_front": (1070, 385), "hardhat_towards": (1168, 387), "hardhat_away": (1364, 384),
        "hardhat_back": (1472, 384),
        "basket_1": (872, 601), "basket_2": (958, 598), "basket_3": (1054, 591), "basket_4": (1164, 593),
        "basket_5": (1293, 586), "basket_6": (1439, 572),
    },
}
NET_PAD = 6
# Rows (share of the height) where the middle of the hips is measured.
HIP_ROW = {"body": 0.7, "hardhat": 0.7, "legs": 0.12}


def main() -> None:
    sprites = SHEETS[Path(sys.argv[1]).name]
    sheet = np.array(Image.open(sys.argv[1]).convert("RGB"))
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    alpha = _foreground(sheet)
    labels, _ = ndimage.label(ndimage.binary_dilation(alpha > 0, iterations=1))
    rgba = np.dstack([sheet, alpha])
    for name, (x, y) in sprites.items():
        label = _label_near(labels, x, y)
        sl = ndimage.find_objects((labels == label).astype(int))[0]
        sprite = rgba[sl].copy()
        sprite[..., 3][labels[sl] != label] = 0
        sprite = _trim(sprite)
        kind = name.split("_")[0]
        if kind in HIP_ROW:
            sprite = _center_on_hips(sprite, HIP_ROW[kind])
        if kind == "net":
            # A transparent border, so the stretched handle does not smear the edge pixels.
            sprite = np.pad(sprite, ((NET_PAD, NET_PAD), (NET_PAD, NET_PAD), (0, 0)))
        Image.fromarray(sprite).save(out / f"{name}.png")
        print(f"{name}: {sprite.shape[1]}x{sprite.shape[0]}")


def _center_on_hips(sprite: np.ndarray, row_share: float) -> np.ndarray:
    """Pads the sprite so the middle of its outline at the given row is the image centre."""
    row = int(sprite.shape[0] * row_share)
    xs = np.nonzero(sprite[row, :, 3] > 128)[0]
    middle = (xs.min() + xs.max()) / 2.0 if len(xs) else sprite.shape[1] / 2.0
    left = int(round(middle))
    right = sprite.shape[1] - left
    half = max(left, right)
    return np.pad(sprite, ((0, 0), (half - left, half - right), (0, 0)))


if __name__ == "__main__":
    main()
