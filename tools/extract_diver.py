"""Cuts the wader in his outfit of every gear level out of the diver sheets into assets/sprites/wader.

One sprite per gear level and view, with the gear painted on: <outfit>_<view>.png for the
outfits wader, snorkel, scuba, rebreather, hardhat and sub. The sheets have an alpha channel;
its soft edge (a glow around each figure) is cut off just outside the dark outline.

Views: front, towards (three-quarter towards the camera), side (profile), away (three-quarter
from behind), back. The game expects the side views looking screen-left and mirrors them when
walking right, so sprites painted looking right are flipped here.

The figures are scaled to their size in the game (the wader BODY_HEIGHT pixels from boots to the
top of his head), padded to one common height with the boots at the bottom and centred on the
hips, so they swap without jumping. The submersible is scaled to SUB_WIDTH.

Needs Pillow, NumPy and SciPy. Usage (from the project folder):
  python tools/extract_diver.py
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SHEET_1 = "art_source/Cartoon-Taucher-Sprite-Sheet mit Mini-U-Boot.png"
SHEET_2 = "art_source/Tauchers und Mini-U-Boote im Sprite-Sheet.png"
OUT = Path("assets/sprites/wader")
BODY_HEIGHT = 215
SUB_WIDTH = 210
# Sheet scales: the first sheet's wader is 161 px tall; the second sheet paints the scuba diver
# (which is 158 px on the first sheet) 275 px tall.
SCALE = {SHEET_1: BODY_HEIGHT / 161.0, SHEET_2: BODY_HEIGHT / 161.0 * 158.0 / 275.0}
COLUMNS_1 = [166, 404, 646, 893, 1143, 1376]
COLUMNS_2 = [160, 424, 662, 921, 1180, 1425]
# outfit: sheet, row centre, and per view the column and whether to flip it.
OUTFITS = {
    "wader": (SHEET_1, 85, {"front": (0, False), "towards": (1, True), "side": (2, True), "away": (4, False), "back": (5, False)}),
    "snorkel": (SHEET_1, 262, {"front": (0, False), "towards": (1, True), "side": (2, True), "away": (4, False), "back": (5, False)}),
    "scuba": (SHEET_2, 183, {"front": (0, False), "towards": (1, True), "side": (2, True), "away": (4, True), "back": (5, False)}),
    "rebreather": (SHEET_1, 609, {"front": (0, False), "towards": (1, True), "side": (2, True), "away": (4, False), "back": (5, False)}),
    "hardhat": (SHEET_2, 499, {"front": (0, False), "towards": (1, True), "side": (2, True), "away": (4, False), "back": (3, False)}),
    # The submersible's side views already look left; it has no view from behind at an angle.
    "sub": (SHEET_2, 804, {"front": (0, False), "towards": (1, False), "side": (2, False), "away": (3, False), "back": (5, False)}),
}
# Alpha range of the soft edge: below is glow, above is the figure.
EDGE = (120.0, 230.0)
# Row (share of the height of the plain wader, from the top) where the middle of the hips is.
HIP_ROW = 0.62


def main() -> None:
    sheets = {path: np.array(Image.open(path).convert("RGBA")) for path in (SHEET_1, SHEET_2)}
    figures: dict[str, np.ndarray] = {}
    for outfit, (path, row, views) in OUTFITS.items():
        sheet = sheets[path]
        columns = COLUMNS_1 if path == SHEET_1 else COLUMNS_2
        for view, (column, flip) in views.items():
            sprite = _cut(sheet, columns[column], row)
            if flip:
                sprite = sprite[:, ::-1]
            if outfit == "sub":
                scale = SUB_WIDTH / 213.0
            else:
                scale = SCALE[path]
            size = (round(sprite.shape[1] * scale), round(sprite.shape[0] * scale))
            sprite = np.array(Image.fromarray(sprite).resize(size, Image.LANCZOS))
            figures[f"{outfit}_{view}"] = sprite
    height = max(s.shape[0] for name, s in figures.items() if not name.startswith("sub"))
    for name, sprite in figures.items():
        if not name.startswith("sub"):
            sprite = np.pad(sprite, ((height - sprite.shape[0], 0), (0, 0), (0, 0)))
            sprite = _center_on_hips(sprite, height - BODY_HEIGHT * (1.0 - HIP_ROW))
        Image.fromarray(sprite).save(OUT / f"{name}.png")
        print(f"{name}: {sprite.shape[1]}x{sprite.shape[0]}")
    print(f"figure height {height}: hips at {1.0 - BODY_HEIGHT * (1.0 - HIP_ROW) / height:.3f}")


def _cut(sheet: np.ndarray, x: int, y: int) -> np.ndarray:
    """The figure around the point, with the glow around it made transparent."""
    alpha = sheet[..., 3].astype(np.float32)
    labels, _ = ndimage.label(ndimage.binary_dilation(alpha > 128, iterations=2))
    window = labels[y - 20:y + 20, x - 20:x + 20]
    values, counts = np.unique(window[window > 0], return_counts=True)
    label = values[np.argmax(counts)]
    sl = ndimage.find_objects((labels == label).astype(int))[0]
    sprite = sheet[sl].copy()
    edge = np.clip((alpha[sl] - EDGE[0]) / (EDGE[1] - EDGE[0]), 0.0, 1.0) * 255.0
    edge[labels[sl] != label] = 0
    sprite[..., 3] = edge.astype(np.uint8)
    ys, xs = np.nonzero(sprite[..., 3] > 0)
    return sprite[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def _center_on_hips(sprite: np.ndarray, row: float) -> np.ndarray:
    """Pads the sprite so the middle of its outline at the row is the image centre."""
    xs = np.nonzero(sprite[int(row), :, 3] > 128)[0]
    middle = (xs.min() + xs.max()) / 2.0 if len(xs) else sprite.shape[1] / 2.0
    left = int(round(middle))
    right = sprite.shape[1] - left
    half = max(left, right)
    return np.pad(sprite, ((0, 0), (half - left, half - right), (0, 0)))


if __name__ == "__main__":
    main()
