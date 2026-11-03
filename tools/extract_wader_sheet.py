"""Cuts a zone's wader sheet (art_source/characters/wader_zone_N.png) into walk strips.

The sheets follow art_source/characters/wader_sprite_prompt.md: rows are views, columns the
standing frame and four walk frames, all looking screen-left. Each view becomes one strip
<outfit>_<view>.png of FRAMES frames side by side, every frame the same size, with the feet on
the bottom edge. The frames of a view are lined up on the head, so it does not jitter
sideways while the legs move. Every sheet is scaled alike, so the wader is BODY_HEIGHT pixels from
boots to the top of the head as in tools/extract_diver.py (gear sticking out above the head, like
the snorkel, makes the frames taller instead).

Needs Pillow, NumPy and SciPy. Usage (from the project folder):
  python tools/extract_wader_sheet.py art_source/characters/wader_zone_1.png wader
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from extract_diver import EDGE  # noqa: E402

OUT = Path("assets/sprites/wader")
BODY_HEIGHT = 215
# Boots to the top of the beanie of the standing front view on the sheets (zone 1).
SHEET_BODY_HEIGHT = 228
FRAMES = 5
# Sheet row of each view, by the number of rows on the sheet. Most sheets came with an extra row
# between the side and the away view (a steeper view from behind), which is not used.
ROWS = {
    5: {"front": 0, "towards": 1, "side": 2, "away": 3, "back": 4},
    6: {"front": 0, "towards": 1, "side": 2, "away": 4, "back": 5},
}
# Smallest figure, in opaque pixels; smaller specks are left over from the background.
MIN_FIGURE = 3000


def main() -> None:
    sheet = np.array(Image.open(sys.argv[1]).convert("RGBA"))
    outfit = sys.argv[2]
    alpha = sheet[..., 3].astype(np.float32)
    figure = np.clip((alpha - EDGE[0]) / (EDGE[1] - EDGE[0]), 0.0, 1.0)
    cutout = sheet.copy()
    cutout[..., 3] = (figure * 255.0).astype(np.uint8)

    # Figures may reach across the cell borders (long fins), so each one is found whole. Sorted
    # top to bottom they fall into rows of FRAMES, each row sorted left to right.
    labels, _ = ndimage.label(ndimage.binary_dilation(cutout[..., 3] > 128, iterations=2))
    found: list[tuple[float, float, np.ndarray]] = []
    for label, sl in enumerate(ndimage.find_objects(labels), 1):
        if sl is None or np.count_nonzero(labels[sl] == label) < MIN_FIGURE:
            continue
        sprite = cutout[sl].copy()
        sprite[..., 3][labels[sl] != label] = 0
        found.append(((sl[0].start + sl[0].stop) / 2.0, (sl[1].start + sl[1].stop) / 2.0, _trim(sprite)))
    found.sort(key=lambda f: f[0])
    rows = [sorted(found[i:i + FRAMES], key=lambda f: f[1]) for i in range(0, len(found), FRAMES)]
    if len(found) % FRAMES or len(rows) not in ROWS:
        sys.exit(f"{len(found)} figures found, expected {FRAMES} per row in 5 or 6 rows")
    cells = {view: [f[2] for f in rows[row]] for view, row in ROWS[len(rows)].items()}
    scale = BODY_HEIGHT / SHEET_BODY_HEIGHT

    # Per frame: the sprite and the x of its anchor (the standing frame's middle, moved with the
    # head).
    placed: dict[str, list[tuple[np.ndarray, float]]] = {}
    for view, frames in cells.items():
        standing = frames[0]
        anchor = standing.shape[1] / 2.0 - _head_x(standing)
        placed[view] = [(sprite, _head_x(sprite) + anchor) for sprite in frames]
    half = max(max(x, s.shape[1] - x) for frames in placed.values() for s, x in frames)
    width = int(np.ceil(half * 2.0))
    height = max(s.shape[0] for frames in placed.values() for s, _ in frames)

    frame_w = round(width * scale)
    frame_h = round(height * scale)
    for view, frames in placed.items():
        strip = np.zeros((height, width * FRAMES, 4), np.uint8)
        for i, (sprite, x) in enumerate(frames):
            left = int(round(i * width + half - x))
            strip[height - sprite.shape[0]:, left:left + sprite.shape[1]] = sprite
        image = Image.fromarray(strip).resize((frame_w * FRAMES, frame_h), Image.LANCZOS)
        image.save(OUT / f"{outfit}_{view}.png")
    print(f"{outfit}: {FRAMES} frames of {frame_w}x{frame_h} per view")


def _trim(sprite: np.ndarray) -> np.ndarray:
    """The sprite cut down to its outline."""
    ys, xs = np.nonzero(sprite[..., 3] > 0)
    return sprite[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def _head_x(sprite: np.ndarray) -> float:
    """Middle of the head (the top quarter of the figure), the steadiest part while walking."""
    xs = np.nonzero(sprite[:sprite.shape[0] // 4, :, 3] > 128)[1]
    return float(xs.mean()) if len(xs) else sprite.shape[1] / 2.0


if __name__ == "__main__":
    main()
