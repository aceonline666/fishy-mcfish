"""Cuts the wader and his equipment out of the equipment sheet into assets/sprites/wader.

Every sprite is cut like the props (tools/extract_props.py: the checkerboard background is
removed by flood fill). Figures and leg frames are then padded so that the middle of the hips
is at the horizontal centre of the image: the game puts both at x = 0, so leg frames line up
under any upper body.

Needs Pillow, NumPy and SciPy. Usage (the second sheet adds the landing nets):
  python tools/extract_wader.py art_source/equipment_sprite_sheet.png assets/sprites/wader
  python tools/extract_wader.py art_source/equipment_sheet_2.png assets/sprites/wader
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from extract_props import _foreground, _label_near, _trim  # noqa: E402

# name: a point on the sprite. Views: front, towards (three-quarter towards the camera), away
# (three-quarter from behind), back.
SPRITES = {
    "body_front": (54, 147), "body_towards": (156, 149), "body_back": (359, 147), "body_away": (455, 147),
    "snorkel_front": (878, 137), "snorkel_towards": (993, 137), "snorkel_back": (1360, 134),
    "scuba_front": (70, 390), "scuba_towards": (174, 392), "scuba_away": (345, 391), "scuba_back": (440, 393),
    "rebreather_back": (736, 375), "rebreather_side": (841, 373),
    "hardhat_front": (1070, 385), "hardhat_towards": (1168, 387), "hardhat_away": (1364, 384), "hardhat_back": (1472, 384),
    "sub_front": (67, 605), "sub_towards": (187, 604), "sub_away": (597, 607), "sub_back": (742, 604),
    "basket_1": (872, 601), "basket_2": (958, 598), "basket_3": (1054, 591), "basket_4": (1164, 593),
    "basket_5": (1293, 586), "basket_6": (1439, 572),
    # Walk cycles: stride, passing, stride, passing.
    "legs_towards_1": (867, 826), "legs_towards_2": (189, 827), "legs_towards_3": (758, 949), "legs_towards_4": (187, 948),
    "legs_away_1": (460, 827), "legs_away_2": (403, 828), "legs_away_3": (459, 950), "legs_away_4": (405, 951),
    "legs_back_1": (947, 826), "legs_back_2": (593, 827), "legs_back_3": (1018, 827), "legs_back_4": (670, 827),
}
# From the second equipment sheet: the landing nets seen from above, hoop on the left, handle
# to the right.
NETS = {
    "net_1": (860, 235), "net_2": (980, 235), "net_3": (1100, 235), "net_4": (1230, 235),
    "net_5": (1345, 235), "net_6": (1465, 235),
}
NET_PAD = 6
# Rows (share of the height) where the middle of the hips is measured.
HIP_ROW = {"body": 0.7, "scuba": 0.7, "hardhat": 0.7, "legs": 0.12}


def main() -> None:
    sprites = NETS if Path(sys.argv[1]).name == "equipment_sheet_2.png" else SPRITES
    sheet = np.array(Image.open(sys.argv[1]).convert("RGB"))
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    alpha = _foreground(sheet)
    labels, _ = ndimage.label(ndimage.binary_dilation(alpha > 0, iterations=2))
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
